import Foundation

/// Where ended trips are sent so they're kept off the iPhone, such as a mileage server.
///
/// `TripSyncer` only talks to this protocol, so moving from the SwiftData stand-in
/// (`SwiftDataTripBackend`) to a real network call means writing one new conforming type,
/// for example an `HTTPTripBackend` that POSTs the trip with `URLSession`, and passing it
/// to `DriveTripStore`. Nothing in CarPlay, Siri, or the sync queue has to change.
@MainActor
protocol TripBackend {
  /// Saves the trip, or updates it if it was sent before.
  ///
  /// Must be safe to call more than once for the same trip: if the app is suspended after the
  /// backend saves a trip but before Skyway hears back, the trip is sent again on the next pass.
  /// Use `trip.id` as the key so a repeat updates the saved trip rather than adding a copy.
  ///
  /// Throw for anything that should be retried later, such as no signal or a server error.
  func upload(_ trip: DriveTrip) async throws
}
