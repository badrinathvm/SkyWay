import AppIntents
import CoreTransferable

/// Exposes a trip to Siri and Apple Intelligence so requests like
/// "Where am I travelling to?" can resolve the trip shown on screen.
struct TripEntity: AppEntity {
  static let typeDisplayRepresentation: TypeDisplayRepresentation = "Trip"
  static let defaultQuery = TripEntityQuery()
  static let viewTripActivityType = "app.skyway.viewTrip"

  var id: String

  @Property(title: "Destination")
  var destination: String

  @Property(title: "Origin")
  var origin: String

  @Property(title: "Flight Number")
  var flightNumber: String

  @Property(title: "Departure")
  var departure: Date

  @Property(title: "Gate")
  var gate: String

  @Property(title: "Seat")
  var seat: String

  @Property(title: "Boarding Group")
  var boardingGroup: String

  @Property(title: "Confirmation Code")
  var confirmationCode: String

  init(trip: Trip) {
    id = trip.id
    destination = "\(trip.destinationCity) (\(trip.destinationCode))"
    origin = "\(trip.originCity) (\(trip.originCode))"
    flightNumber = trip.flightNumber
    departure = trip.departure
    gate = trip.gate
    seat = trip.seat
    boardingGroup = trip.boardingGroup
    confirmationCode = trip.confirmationCode
  }

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(
      title: "Trip to \(destination)",
      subtitle: "\(flightNumber) from \(origin) · Departs \(departure.formatted(date: .abbreviated, time: .shortened))",
      image: .init(systemName: "airplane.departure")
    )
  }

  /// A plain-language description Apple Intelligence can read when it reasons about the screen.
  var summary: String {
    """
    Trip to \(destination) on flight \(flightNumber), departing from \(origin) \
    on \(departure.formatted(date: .complete, time: .shortened)). \
    Gate \(gate), seat \(seat), boarding group \(boardingGroup). Confirmation \(confirmationCode).
    """
  }
}

extension TripEntity: Transferable {
  static var transferRepresentation: some TransferRepresentation {
    ProxyRepresentation(exporting: \.summary)
  }
}

extension Trip {
  var entity: TripEntity { TripEntity(trip: self) }
}

struct TripEntityQuery: EntityStringQuery {
  func entities(for identifiers: [TripEntity.ID]) async throws -> [TripEntity] {
    TripStore.trips(with: identifiers).map(\.entity)
  }

  func entities(matching string: String) async throws -> [TripEntity] {
    TripStore.trips(matching: string).map(\.entity)
  }

  func suggestedEntities() async throws -> [TripEntity] {
    TripStore.trips.map(\.entity)
  }
}
