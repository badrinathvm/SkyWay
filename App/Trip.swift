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
  var arrivalWeather: String

  /// Stable across launches so Siri and Apple Intelligence can look the trip up by identifier.
  var id: String { confirmationCode }

  var title: String { "Trip to \(destinationCity)" }

  /// Boarding starts 40 minutes before departure.
  var boardingTime: Date { departure.addingTimeInterval(-40 * 60) }

  /// When to leave for the airport: the drive plus time to get through security before boarding.
  var leaveByTime: Date { boardingTime.addingTimeInterval(-(45 + 30) * 60) }

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
    confirmationCode: "K7QX2P",
    arrivalWeather: "64°F and sunny"
  )
}

extension Trip {
  var summaryContextItem: ContextItem {
    ContextItem(
      id: "trip-summary",
      title: title,
      detail: "\(title), flight \(flightNumber) from \(originCode) to \(destinationCode), departing \(departure.formatted(date: .omitted, time: .shortened)) from gate \(gate), seat \(seat).",
      systemImage: "airplane",
      suggestion: "When do I board?"
    )
  }

  var weatherContextItem: ContextItem {
    ContextItem(
      id: "arrival-weather",
      title: "Arrival weather",
      detail: "Weather in \(destinationCity) on arrival: \(arrivalWeather).",
      systemImage: "sun.max.fill",
      suggestion: "What's the weather when I land?",
      sortOrder: 1
    )
  }
}
