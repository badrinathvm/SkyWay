import AppIntents

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
