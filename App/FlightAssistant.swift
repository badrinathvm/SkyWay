import Foundation
import Observation

/// Holds the Flight status conversation and answers questions from the trip's details.
@Observable
final class FlightAssistant {
  var trip: Trip
  var draft = ""
  private(set) var messages: [ChatMessage] = []

  static let suggestions = [
    "What gate do I leave from?",
    "When do I board?",
    "What's my seat?",
  ]

  init(trip: Trip) {
    self.trip = trip
  }

  var canSend: Bool {
    !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  func sendDraft() {
    send(draft)
    draft = ""
  }

  func send(_ text: String) {
    let question = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !question.isEmpty else { return }
    messages.append(ChatMessage(sender: .user, text: question))
    messages.append(ChatMessage(sender: .assistant, text: answer(to: question)))
  }

  var boardingTime: Date {
    trip.departure.addingTimeInterval(-40 * 60)
  }

  private func answer(to question: String) -> String {
    let text = question.lowercased()
    let departure = trip.departure.formatted(date: .omitted, time: .shortened)

    if text.contains("gate") {
      return "Flight \(trip.flightNumber) departs from gate \(trip.gate)."
    } else if text.contains("board") {
      return "Boarding starts at \(boardingTime.formatted(date: .omitted, time: .shortened)). You're in group \(trip.boardingGroup)."
    } else if text.contains("seat") {
      return "You're in seat \(trip.seat)."
    } else if text.contains("when") || text.contains("time") || text.contains("depart") || text.contains("leave") {
      return "Flight \(trip.flightNumber) departs \(trip.originCity) at \(departure)."
    } else if text.contains("where") || text.contains("destination") || text.contains("going") {
      return "You're flying from \(trip.originCity) (\(trip.originCode)) to \(trip.destinationCity) (\(trip.destinationCode))."
    } else if text.contains("status") || text.contains("delay") || text.contains("on time") {
      return "Flight \(trip.flightNumber) is on time, departing at \(departure) from gate \(trip.gate)."
    } else if text.contains("confirmation") {
      return "Your confirmation code is \(trip.confirmationCode)."
    } else {
      return "I can help with your gate, boarding time, seat, departure, and flight status for \(trip.flightNumber)."
    }
  }
}
