import Foundation
import SwiftData

/// A stand-in for the mileage server: "uploads" trips into a SwiftData store on the iPhone.
///
/// It behaves the way the real backend should, so the sync queue can be built and tested now:
/// - Uploads are upserts keyed by trip ID, so sending a trip twice keeps one record.
/// - With `-failTripSync` (Debug builds), every upload throws, like having no signal,
///   to test that trips stay queued and are retried.
@MainActor
final class SwiftDataTripBackend: TripBackend {
  /// Created on first upload rather than at launch, so a CarPlay launch with the iPhone locked
  /// doesn't open a database it may not need.
  private var container: ModelContainer?

  func upload(_ trip: DriveTrip) async throws {
    #if DEBUG
    if ProcessInfo.processInfo.arguments.contains("-failTripSync") {
      throw URLError(.notConnectedToInternet)
    }
    #endif

    let context = try makeContainer().mainContext
    // Look for an earlier upload of this trip first, so a retry updates it in place.
    let tripID = trip.id
    var existing = FetchDescriptor<SyncedTripRecord>(predicate: #Predicate { $0.tripID == tripID })
    existing.fetchLimit = 1
    if let record = try context.fetch(existing).first {
      record.update(from: trip)
    } else {
      context.insert(SyncedTripRecord(trip: trip))
    }
    // Save before returning: once this returns, the syncer marks the trip as synced and
    // won't send it again, so the write has to be on disk by then, like a server's 200 OK.
    try context.save()
  }

  private func makeContainer() throws -> ModelContainer {
    if let container {
      return container
    }
    // Its own file, apart from DriveTrips.json, as a server's database would be. Files in
    // Application Support get iOS's default protection, which stays readable after the first
    // unlock, so saving works with the iPhone locked in the car.
    let configuration = ModelConfiguration(
      "SyncedTrips",
      url: URL.applicationSupportDirectory.appending(path: "SyncedTrips.store")
    )
    let container = try ModelContainer(for: SyncedTripRecord.self, configurations: configuration)
    self.container = container
    return container
  }
}
