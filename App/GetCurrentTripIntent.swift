import AppIntents

/// Answers "Where am I travelling?" with the person's upcoming trip.
struct GetCurrentTripIntent: AppIntent {
  static let title: LocalizedStringResource = "Get Upcoming Trip"
  static let description = IntentDescription("Tells you where your upcoming trip is going, with flight and gate details.")

  func perform() async throws -> some IntentResult & ReturnsValue<TripEntity> & ProvidesDialog {
    guard let trip = TripStore.trips.first else {
      throw TripError.noUpcomingTrip
    }
    let departure = trip.departure.formatted(date: .abbreviated, time: .shortened)
    return .result(
      value: trip.entity,
      dialog: "You're travelling to \(trip.destinationCity) on flight \(trip.flightNumber), departing \(trip.originCity) \(departure) from gate \(trip.gate). Your seat is \(trip.seat)."
    )
  }
}

enum TripError: Error, CustomLocalizedStringResourceConvertible {
  case noUpcomingTrip

  var localizedStringResource: LocalizedStringResource {
    switch self {
    case .noUpcomingTrip: "You don't have any upcoming trips in Skyway."
    }
  }
}
