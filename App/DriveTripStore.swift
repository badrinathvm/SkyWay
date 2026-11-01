import CoreLocation
import Foundation
import MapKit

/// The person's logged drives, shared by CarPlay and Siri and saved across launches.
@MainActor
@Observable
final class DriveTripStore {
  static let shared = DriveTripStore()

  /// Ended trips, newest first.
  private(set) var trips: [DriveTrip] = []
  private(set) var activeTrip: DriveTrip?
  /// The latest fix while a trip is in progress, for the map.
  private(set) var currentLocation: CLLocation?
  /// Set when a trip couldn't be tracked because location access is off.
  var isLocationDenied = false
  /// When the car last covered ground, to tell driving from parked.
  private(set) var lastMovedAt: Date?

  /// The car moved during the trip but has been still for a minute.
  var isParked: Bool {
    guard let lastMovedAt else { return false }
    return Date.now.timeIntervalSince(lastMovedAt) > 60
  }

  var recentTrips: ArraySlice<DriveTrip> { trips.prefix(5) }

  private let tracker = DriveTracker()
  private var trackingTask: Task<Void, Never>?
  private var lastFix: CLLocation?
  private var lastSave = Date.distantPast
  /// Uploads ended trips. Swap `SwiftDataTripBackend` for a network backend when the server is ready.
  private let syncer = TripSyncer(backend: SwiftDataTripBackend())

  private init() {
    load()
    syncer.configure(
      // Oldest first, so the backend receives trips in the order they were driven.
      pendingTrips: { [unowned self] in trips.filter { !$0.isSynced }.reversed() },
      markSynced: { [unowned self] id, date in markSynced(id, at: date) }
    )
    // Catch up on trips that ended while there was no signal, or before the app was suspended.
    syncer.syncNow()
  }

  /// Uploads any trips the backend doesn't have yet. Called on launch and whenever a trip ends;
  /// CarPlay also calls it when the car connects, since that's when a driver is likely to have signal.
  func syncPendingTrips() {
    syncer.syncNow()
  }

  func startTrip() {
    guard activeTrip == nil else { return }
    activeTrip = DriveTrip(startDate: .now)
    isLocationDenied = false
    save()
    track()
  }

  /// Picks tracking back up when the app relaunches mid-trip.
  func resumeTrackingIfNeeded() {
    guard activeTrip != nil, trackingTask == nil else { return }
    track()
  }

  /// Looks up where the trip is ending, so it can be shown before the trip is saved.
  func endingAddress() async -> String? {
    guard let location = currentLocation else { return activeTrip?.endAddress }
    let address = await Self.address(at: location)
    activeTrip?.endAddress = address
    return address
  }

  /// Saves the trip in progress. Pass `miles` and `endDate` to save what was shown when the
  /// person chose to end it, rather than what was driven while they answered.
  @discardableResult
  func endTrip(as purpose: DriveTrip.Purpose, miles: Double? = nil, endDate: Date = .now) -> DriveTrip? {
    guard var trip = activeTrip else { return nil }
    stopTracking()
    trip.endDate = endDate
    trip.purpose = purpose
    if let miles {
      trip.miles = miles
    }
    if let currentLocation {
      trip.end = DriveTrip.Coordinate(currentLocation.coordinate)
    }
    trips.insert(trip, at: 0)
    activeTrip = nil
    currentLocation = nil
    // Save to disk first, then upload: if the upload fails, or the app is suspended mid-request,
    // the trip is already safe in DriveTrips.json and stays in the queue until it goes through.
    save()
    // Here rather than in the CarPlay code, so trips ended with Siri upload too.
    syncer.syncNow()
    return trip
  }

  private func markSynced(_ id: DriveTrip.ID, at date: Date) {
    guard let index = trips.firstIndex(where: { $0.id == id }) else { return }
    trips[index].syncedAt = date
    // Saved right away, so a trip isn't uploaded again after a relaunch. Even if it were, the
    // backend treats a repeat as an update, so nothing would be duplicated.
    save()
  }

  // MARK: Tracking

  private func track() {
    lastFix = nil
    lastMovedAt = nil
    trackingTask = Task {
      for await event in tracker.events() {
        switch event {
        case .location(let location):
          record(location)
        case .denied:
          isLocationDenied = true
          stopTracking()
          activeTrip = nil
          currentLocation = nil
          save()
          return
        }
      }
    }
  }

  private func stopTracking() {
    trackingTask?.cancel()
    trackingTask = nil
    tracker.stop()
  }

  private func record(_ location: CLLocation) {
    guard activeTrip != nil else { return }
    currentLocation = location
    if activeTrip?.start == nil {
      activeTrip?.start = DriveTrip.Coordinate(location.coordinate)
      Task {
        activeTrip?.startAddress = await Self.address(at: location)
        save()
      }
    }
    if let lastFix {
      let meters = location.distance(from: lastFix)
      // Ignore GPS jitter while stopped, keeping the older fix so a slow crawl still adds up.
      guard meters >= 5 else { return }
      let seconds = location.timestamp.timeIntervalSince(lastFix.timestamp)
      // A jump faster than any car is a bad fix or a gap in tracking, not driving.
      if seconds > 0, meters / seconds < 70 {
        activeTrip?.miles += meters / 1609.344
        lastMovedAt = location.timestamp
      }
    }
    lastFix = location
    if Date.now.timeIntervalSince(lastSave) > 15 {
      save()
    }
  }

  private static func address(at location: CLLocation) async -> String? {
    guard let request = MKReverseGeocodingRequest(location: location) else { return nil }
    let item = try? await request.mapItems.first
    return item?.address?.shortAddress ?? item?.name
  }

  // MARK: Saving

  private struct Saved: Codable {
    var trips: [DriveTrip]
    var activeTrip: DriveTrip?
  }

  private static var fileURL: URL {
    URL.applicationSupportDirectory.appending(path: "DriveTrips.json")
  }

  private func load() {
    guard let data = try? Data(contentsOf: Self.fileURL),
          let saved = try? JSONDecoder().decode(Saved.self, from: data) else { return }
    trips = saved.trips
    activeTrip = saved.activeTrip
  }

  private func save() {
    lastSave = .now
    do {
      try FileManager.default.createDirectory(at: .applicationSupportDirectory, withIntermediateDirectories: true)
      let data = try JSONEncoder().encode(Saved(trips: trips, activeTrip: activeTrip))
      // CarPlay is often used with iPhone locked, so the file stays readable after the first unlock.
      try data.write(to: Self.fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    } catch {
      print("Couldn't save trips: \(error)")
    }
  }
}
