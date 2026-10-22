import Foundation

struct Trip: Identifiable, Hashable {
  var originCity: String
  var destinationCity: String
  var originCode: String
  var destinationCode: String
  var flightNumber: String
  var departure: Date
  var gate: String
  var seat: String
  var boardingGroup: String
  var passengerName: String
  var confirmationCode: String

  /// Stable across launches so Siri and Apple Intelligence can look the trip up by identifier.
  var id: String { confirmationCode }

  var title: String { "Trip to \(destinationCity)" }

  var boardingPassPayload: String {
    "\(confirmationCode)|\(flightNumber)|\(originCode)-\(destinationCode)|\(seat)|\(passengerName)"
  }

  static let sample = Trip(
    originCity: "New York",
    destinationCity: "San Francisco",
    originCode: "JFK",
    destinationCode: "SFO",
    flightNumber: "SW 214",
    departure: Calendar.current.date(byAdding: .hour, value: 3, to: .now) ?? .now,
    gate: "B22",
    seat: "14A",
    boardingGroup: "2",
    passengerName: "Alex Morgan",
    confirmationCode: "K7QX2P"
  )
}
