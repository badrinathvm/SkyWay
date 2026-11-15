import AppIntents

/// Runs when the person taps Undo on the result card. Siri then redraws the card.
struct UndoSeatChangeIntent: AppIntent {
  static let title: LocalizedStringResource = "Undo Seat Change"
  static let isDiscoverable = false

  @Parameter(title: "Trip")
  var trip: TripEntity

  @Parameter(title: "Seat")
  var seat: String

  init() {}

  init(trip: TripEntity, seat: String) {
    self.trip = trip
    self.seat = seat
  }

  func perform() async throws -> some IntentResult {
    guard let booking = TripStore.trips(with: [trip.id]).first, let seat = Seat(seat) else {
      throw TripError.noUpcomingTrip
    }
    await SeatAssignments.changeSeat(of: booking, to: seat)
    return .result()
  }
}
