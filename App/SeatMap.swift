import Foundation

/// The cabin layout of a Skyway flight: which seats exist, which are taken, and which cost extra.
struct SeatMap: Sendable {
  var rows = 1...30
  var letters: [Character] = ["A", "B", "C", "D", "E", "F"]
  /// Rows with extra legroom: the bulkhead row and the exit row.
  var extraLegroomRows: Set<Int> = [12, 15]
  var extraLegroomFee = 49
  var occupied: Set<Seat>

  /// The seat map for `trip`. Taken seats are fixed so the demo behaves the same every time.
  static func forTrip(_ trip: Trip) -> SeatMap {
    let taken = [
      "1A", "1C", "2D", "2F", "3B", "5A", "5E", "7C", "8F", "9A", "10D",
      "12A", "12B", "12D", "12E", "14B", "14C", "15A", "15F", "16C", "16D",
      "17C", "17F", "18A", "18F", "19B", "20E", "21A", "22C", "24D", "26F", "28B", "30A",
    ]
    return SeatMap(occupied: Set(taken.compactMap { Seat($0) }))
  }

  func contains(_ seat: Seat) -> Bool {
    rows.contains(seat.row) && letters.contains(seat.letter)
  }

  func isFree(_ seat: Seat) -> Bool {
    contains(seat) && !occupied.contains(seat)
  }

  /// The fee to move to `seat`, in US dollars, or nil when it's free.
  func fee(for seat: Seat) -> Int? {
    extraLegroomRows.contains(seat.row) ? extraLegroomFee : nil
  }

  /// Free seats closest to `seat`, the same row first, for when it's taken.
  func freeSeats(near seat: Seat, excluding current: Seat?, limit: Int = 2) -> [Seat] {
    let candidates = rows.flatMap { row in letters.map { Seat(row: row, letter: $0) } }
      .filter { isFree($0) && $0 != current }
    let column = { (seat: Seat) in letters.firstIndex(of: seat.letter) ?? 0 }
    return candidates
      .sorted {
        let distance0 = abs($0.row - seat.row) * 10 + abs(column($0) - column(seat))
        let distance1 = abs($1.row - seat.row) * 10 + abs(column($1) - column(seat))
        return distance0 < distance1
      }
      .prefix(limit)
      .map { $0 }
  }
}
