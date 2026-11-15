import CoreLocation
import Foundation

/// Streams location fixes accurate enough to measure a drive with.
@MainActor
final class DriveTracker {
  enum Event: Sendable {
    case location(CLLocation)
    case denied
  }

  private var serviceSession: CLServiceSession?
  private var backgroundSession: CLBackgroundActivitySession?

  func events() -> AsyncStream<Event> {
    #if DEBUG
    if ProcessInfo.processInfo.arguments.contains("-simulateDrive") {
      return SimulatedDrive.events()
    }
    #endif
    // Asks for When In Use access on iPhone if needed, and keeps updates coming while it's locked.
    serviceSession = CLServiceSession(authorization: .whenInUse)
    backgroundSession = CLBackgroundActivitySession()
    return AsyncStream { continuation in
      let task = Task {
        do {
          for try await update in CLLocationUpdate.liveUpdates(.automotiveNavigation) {
            if update.authorizationDenied || update.authorizationDeniedGlobally || update.authorizationRestricted {
              continuation.yield(.denied)
              break
            }
            // Imprecise fixes wander, and the wandering would add up to miles that weren't driven.
            if let location = update.location, location.horizontalAccuracy >= 0, location.horizontalAccuracy <= 50 {
              continuation.yield(.location(location))
            }
          }
        } catch {}
        continuation.finish()
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }

  func stop() {
    backgroundSession?.invalidate()
    backgroundSession = nil
    serviceSession?.invalidate()
    serviceSession = nil
  }
}

#if DEBUG
/// A drive through Cupertino at about 67 mph, for testing in the simulator with -simulateDrive.
enum SimulatedDrive {
  private static let waypoints = [
    CLLocation(latitude: 37.3349, longitude: -122.0090),
    CLLocation(latitude: 37.3230, longitude: -122.0322),
    CLLocation(latitude: 37.3230, longitude: -122.0600),
    CLLocation(latitude: 37.3550, longitude: -122.0600),
    CLLocation(latitude: 37.3860, longitude: -122.0830),
    CLLocation(latitude: 37.4000, longitude: -122.1100),
  ]
  private static let metersPerSecond = 30.0

  static func events() -> AsyncStream<DriveTracker.Event> {
    AsyncStream { continuation in
      let task = Task {
        let start = Date.now
        var seconds = 0.0
        // Parks at the last waypoint, where the trip stays until it's ended.
        while !Task.isCancelled, let coordinate = coordinate(afterMeters: seconds * metersPerSecond) {
          let location = CLLocation(
            coordinate: coordinate, altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5,
            timestamp: start.addingTimeInterval(seconds)
          )
          continuation.yield(.location(location))
          try? await Task.sleep(for: .seconds(1))
          seconds += 1
        }
        continuation.finish()
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }

  private static func coordinate(afterMeters meters: Double) -> CLLocationCoordinate2D? {
    var remaining = meters
    for (from, to) in zip(waypoints, waypoints.dropFirst()) {
      let length = to.distance(from: from)
      if remaining <= length {
        let fraction = remaining / length
        return CLLocationCoordinate2D(
          latitude: from.coordinate.latitude + (to.coordinate.latitude - from.coordinate.latitude) * fraction,
          longitude: from.coordinate.longitude + (to.coordinate.longitude - from.coordinate.longitude) * fraction
        )
      }
      remaining -= length
    }
    return nil
  }
}
#endif
