import Foundation

/// The source of truth for the person's trips, shared by the UI and App Intents.
enum TripStore {
  /// Read each time, so a seat changed from Siri shows up everywhere.
  static var trips: [Trip] { [Trip.sample.withSavedSeat] }

  static func trips(with identifiers: [Trip.ID]) -> [Trip] {
    trips.filter { identifiers.contains($0.id) }
  }

  static func trips(matching text: String) -> [Trip] {
    trips.filter {
      $0.destinationCity.localizedStandardContains(text)
        || $0.originCity.localizedStandardContains(text)
        || $0.flightNumber.localizedStandardContains(text)
    }
  }
}
