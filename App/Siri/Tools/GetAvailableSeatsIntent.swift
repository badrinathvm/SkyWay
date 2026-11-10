import AppIntents

/// Lists free seats so Siri can pick one for requests like "get me a window seat with more legroom".
struct GetAvailableSeatsIntent: AppIntent {
  static let title: LocalizedStringResource = "Get Available Seats"
  static let description = IntentDescription(
    "Lists free seats on your upcoming Skyway flight, closest to your current seat first, with each seat's position and any extra-legroom fee. It doesn't change your seat.",
    searchKeywords: ["seat map", "free seats", "open seats", "empty seats", "window", "aisle", "legroom", "exit row"]
  )

  /// How many seats to report, so the answer stays short enough to read out.
  static let resultLimit = 8

  @Parameter(title: "Position", description: "Only window, middle, or aisle seats. Leave empty for any position.")
  var position: Seat.Position?

  @Parameter(
    title: "Extra Legroom Only",
    description: "Only extra-legroom seats, in rows 12 and 15, which cost $49 more.",
    default: false
  )
  var extraLegroomOnly: Bool

  @Parameter(
    title: "Up to Row",
    description: "Only seats in row 1 through this row, for seats near the front. Rows go from 1 to 30.",
    inclusiveRange: (1, 30)
  )
  var maximumRow: Int?

  @Parameter(title: "Trip", description: "The trip to look at. Leave empty for the upcoming trip.")
  var trip: TripEntity?

  init() {}

  func perform() async throws -> some IntentResult & ReturnsValue<[AvailableSeat]> & ProvidesDialog {
    guard let booking = trip.flatMap({ TripStore.trips(with: [$0.id]).first }) ?? TripStore.trips.first else {
      throw TripError.noUpcomingTrip
    }
    let seatMap = SeatMap.forTrip(booking)
    let current = Seat(booking.seat) ?? Seat(row: 1, letter: "A")

    let seats = seatMap.freeSeats(near: current, excluding: current, limit: .max)
      .filter { position == nil || $0.position == position }
      .filter { !extraLegroomOnly || seatMap.fee(for: $0) != nil }
      .filter { $0.row <= (maximumRow ?? .max) }
      .prefix(Self.resultLimit)
      .map { AvailableSeat(seat: $0, map: seatMap) }

    guard !seats.isEmpty else {
      return .result(value: [], dialog: "There are no free seats like that on flight \(booking.flightNumber). You're in \(booking.seat).")
    }
    let list = seats.map { "\($0.seat) (\($0.position.title.lowercased())\($0.isExtraLegroom ? ", $\($0.fee)" : ""))" }
    return .result(
      value: seats,
      dialog: "You're in \(booking.seat). Free seats nearby on flight \(booking.flightNumber): \(list.formatted(.list(type: .and)))."
    )
  }
}

@available(iOS 27.3, *)
extension GetAvailableSeatsIntent: ToolIntent {}
