import AppIntents

/// Answers "Where am I travelling?" with the person's upcoming trip.
///
/// Returns the trip as well as the reply, so Siri can act on it in a follow-up like
/// "move me to an aisle seat" without looking the trip up again.
struct GetCurrentTripIntent: AppIntent {
  static let title: LocalizedStringResource = "Get Upcoming Trip"
  static let description = IntentDescription(
    "Gets your next Skyway flight: where it's going and from, the flight number, departure date and time, gate, seat, boarding group and confirmation code. It doesn't change the trip or the seat.",
    searchKeywords: ["trip", "flight", "where am I flying", "gate", "departure", "boarding", "my seat", "confirmation code", "itinerary"]
  )

  init() {}

  func perform() async throws -> some IntentResult & ReturnsValue<TripEntity> & ProvidesDialog {
    guard let trip = TripStore.trips.first else {
      throw TripError.noUpcomingTrip
    }
    let departure = trip.departure.formatted(date: .abbreviated, time: .shortened)
    // Spoken for the App Shortcut. Keep it short: Siri also gets the trip itself to answer
    // anything more specific.
    return .result(
      value: trip.entity,
      dialog: "You're flying to \(trip.destinationCity) on \(trip.flightNumber), \(departure), from gate \(trip.gate), seat \(trip.seat)."
    )
  }
}

@available(iOS 27.3, *)
extension GetCurrentTripIntent: ToolIntent {}
