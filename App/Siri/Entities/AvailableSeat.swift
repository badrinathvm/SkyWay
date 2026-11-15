import AppIntents

/// A free seat on the person's flight, as the Get Available Seats tool reports it to Siri.
struct AvailableSeat: TransientAppEntity {
  static let typeDisplayRepresentation: TypeDisplayRepresentation = "Available Seat"

  @Property(title: "Seat")
  var seat: String

  @Property(title: "Row")
  var row: Int

  @Property(title: "Position")
  var position: Seat.Position

  @Property(title: "Extra Legroom")
  var isExtraLegroom: Bool

  /// The fee to move to this seat in US dollars, 0 when it's free.
  @Property(title: "Fee")
  var fee: Int

  init() {}

  init(seat: Seat, map: SeatMap) {
    self.seat = seat.description
    row = seat.row
    position = seat.position
    fee = map.fee(for: seat) ?? 0
    isExtraLegroom = fee > 0
  }

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(
      title: "\(seat)",
      subtitle: "\(position.title)\(isExtraLegroom ? " · Extra legroom, $\(fee)" : " · No fee")",
      image: .init(systemName: "carseat.left.fill")
    )
  }
}
