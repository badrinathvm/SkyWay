import AppIntents

/// "Change my seat to 17B": checks the seat map, shows a confirmation card in Siri, then moves the booking.
struct ChangeSeatIntent: AppIntent {
  static let title: LocalizedStringResource = "Change Seat"
  static let description = IntentDescription(
    "Moves you to a different seat on your upcoming Skyway flight after you confirm. Extra legroom seats in rows 12 and 15 cost $49.",
    searchKeywords: ["seat", "move seats", "switch seats", "window seat", "aisle seat", "legroom"]
  )

  @Parameter(
    title: "Seat",
    description: "The new seat, a row number from 1 to 30 followed by a letter from A to F, like 17B",
    requestValueDialog: "Which seat would you like?"
  )
  var seat: String

  @Parameter(title: "Trip", description: "The trip to change seats on. Leave empty for the upcoming trip.")
  var trip: TripEntity?

  init() {}

  init(seat: String, trip: TripEntity? = nil) {
    self.seat = seat
    self.trip = trip
  }

  func perform() async throws -> some IntentResult & ReturnsValue<TripEntity> & ProvidesDialog & ShowsSnippetIntent {
    guard let booking = trip.flatMap({ TripStore.trips(with: [$0.id]).first }) ?? TripStore.trips.first else {
      throw TripError.noUpcomingTrip
    }
    let seatMap = SeatMap.forTrip(booking)
    let current = Seat(booking.seat)

    guard let newSeat = Seat(seat), seatMap.contains(newSeat) else {
      throw SeatChangeError.invalidSeat(seat.uppercased(), flight: booking.flightNumber)
    }
    guard newSeat != current else {
      throw SeatChangeError.alreadyInSeat(newSeat.description)
    }
    guard seatMap.isFree(newSeat) else {
      let nearby = seatMap.freeSeats(near: newSeat, excluding: current)
      throw SeatChangeError.seatTaken(newSeat.description, nearby: nearby)
    }

    try await requestConfirmation(
      actionName: .custom(
        acceptLabel: "Change Seat",
        acceptAlternatives: ["Yes", "Confirm", "Change it"],
        denyLabel: "Keep \(booking.seat)",
        denyAlternatives: ["No", "Cancel"],
        destructive: false
      ),
      dialog: confirmationDialog(from: booking.seat, to: newSeat, fee: seatMap.fee(for: newSeat)),
      snippetIntent: SeatChangeConfirmationSnippetIntent(trip: booking.entity, newSeat: newSeat.description)
    )

    let previousSeat = await SeatAssignments.changeSeat(of: booking, to: newSeat)
    let updated = booking.withSavedSeat
    return .result(
      value: updated.entity,
      dialog: "Done. You're now in \(newSeat.description) on flight \(updated.flightNumber).",
      snippetIntent: SeatChangeResultSnippetIntent(trip: updated.entity, previousSeat: previousSeat)
    )
  }

  private func confirmationDialog(from current: String, to newSeat: Seat, fee: Int?) -> IntentDialog {
    let position = newSeat.position.title.lowercased()
    if let fee {
      return "Move from \(current) to \(newSeat.description), an extra legroom \(position) seat, for $\(fee)?"
    }
    return "Move from \(current) to \(newSeat.description), a \(position) seat?"
  }
}

@available(iOS 27.3, *)
extension ChangeSeatIntent: ToolIntent {}

enum SeatChangeError: Error, CustomLocalizedStringResourceConvertible {
  case invalidSeat(String, flight: String)
  case alreadyInSeat(String)
  case seatTaken(String, nearby: [Seat])

  var localizedStringResource: LocalizedStringResource {
    switch self {
    case let .invalidSeat(seat, flight):
      "\(seat) isn't a seat on \(flight). Seats are rows 1 to 30, letters A to F, like 17B."
    case let .alreadyInSeat(seat):
      "You're already in seat \(seat)."
    case let .seatTaken(seat, nearby) where nearby.isEmpty:
      "\(seat) is taken, and there are no other free seats on this flight."
    case let .seatTaken(seat, nearby):
      "\(seat) is taken. \(nearby.map { "\($0) (\($0.position.title.lowercased()))" }.formatted(.list(type: .or))) \(nearby.count == 1 ? "is" : "are") free nearby."
    }
  }
}
