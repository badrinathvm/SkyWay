import Foundation
import Observation

/// Holds the assistant conversation and answers questions from the trip and the cards on screen.
@Observable
final class FlightAssistant {
  var trip: Trip
  var draft = ""
  var isComposing = false
  var isShowingAnswerSheet = false
  /// The on-screen items the person can share as context.
  let screenContext = ScreenContext()
  /// Every message, shown on the Flight status tab.
  private(set) var messages: [ChatMessage] = []
  /// Messages from the current answer sheet session.
  private(set) var sessionMessages: [ChatMessage] = []
  /// The items the person shared as context for the current session.
  private(set) var contextItems: [ContextItem] = []

  var usesScreenContext: Bool { !contextItems.isEmpty }

  static let suggestions = [
    "What gate do I leave from?",
    "When do I board?",
    "What's my seat?",
  ]

  private static let screenSuggestions = TravelAction.all.map(\.question)

  init(trip: Trip) {
    self.trip = trip
  }

  var canSend: Bool {
    !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  /// Follow-up questions for the answer sheet, skipping ones already asked.
  var followUpSuggestions: [String] {
    let pool = usesScreenContext
      ? contextItems.compactMap(\.suggestion) + ["Summarize what I selected"]
      : Self.suggestions + Self.screenSuggestions
    let asked = Set(sessionMessages.filter { $0.sender == .user }.map(\.text))
    return Array(pool.filter { !asked.contains($0) }.prefix(3))
  }

  func startComposing() {
    screenContext.lock()
    isComposing = true
  }

  func stopComposing() {
    isComposing = false
    if !isShowingAnswerSheet {
      screenContext.clear()
    }
  }

  /// Sends the draft as a follow-up in the current session.
  func sendDraft() {
    let question = draft
    draft = ""
    send(question)
  }

  /// Sends the draft from the Travel composer and shows the reply in the answer sheet.
  func sendDraftToSheet() {
    let question = draft
    draft = ""
    sessionMessages = []
    contextItems = screenContext.mode == .off ? [] : screenContext.selectedItems
    isComposing = false
    send(question)
    isShowingAnswerSheet = true
  }

  func endSession() {
    isShowingAnswerSheet = false
    screenContext.clear()
    contextItems = []
    sessionMessages = []
  }

  func send(_ text: String) {
    let question = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !question.isEmpty else { return }
    let exchange = [
      ChatMessage(sender: .user, text: question),
      ChatMessage(sender: .assistant, text: answer(to: question)),
    ]
    messages.append(contentsOf: exchange)
    sessionMessages.append(contentsOf: exchange)
  }

  var boardingTime: Date {
    trip.departure.addingTimeInterval(-40 * 60)
  }

  private func answer(to question: String) -> String {
    let text = question.lowercased()
    let departure = trip.departure.formatted(date: .omitted, time: .shortened)
    let boarding = boardingTime.formatted(date: .omitted, time: .shortened)

    // Questions about the travel cards come first, since they often mention a gate or seat too.
    if text.contains("menu") || text.contains("food") || text.contains("eat") || text.contains("drink") {
      return """
      On \(trip.flightNumber) to \(trip.destinationCity) you can choose from:
      • Breakfast: Greek yogurt parfait with granola and berries
      • Snack box: hummus, pita chips, olives, and dark chocolate
      • Hot meal: chicken teriyaki rice bowl
      • Drinks: coffee, tea, juices, soft drinks, and beer and wine for purchase
      Pre-order by \(boarding) to make sure your first choice is available.
      """
    } else if text.contains("upgrade") {
      return "Yes. Extra legroom seats are available on \(trip.flightNumber) for $49, including 12C (aisle) and 12F (window) near your current seat \(trip.seat). Tap Upgrade your seat on the Travel tab to choose one."
    } else if text.contains("get to") || text.contains("terminal") || text.contains("direction") || text.contains("find my gate") {
      return """
      To get to gate \(trip.gate) at \(trip.originCode):
      1. After security, follow signs for Concourse B.
      2. Take the moving walkway toward gates B15–B30.
      3. Gate \(trip.gate) is on your right, past the coffee shop.
      It's about a 9-minute walk. Boarding starts at \(boarding), so aim to be there by then.
      """
    } else if text.contains("bag") || text.contains("luggage") {
      return "Your checked bag was scanned at \(trip.originCode) bag drop and is checked through to \(trip.destinationCode). After landing, collect it from the baggage claim carousel shown on the arrivals board."
    } else if text.contains("wi-fi") || text.contains("wifi") || text.contains("internet") || text.contains("entertainment") {
      return "Yes. \(trip.flightNumber) has free messaging Wi-Fi, and full browsing for $8. Movies and TV stream to your own device through the Skyway Entertainment portal once you're above 10,000 feet."
    } else if text.contains("change") {
      return "You can change \(trip.flightNumber) up to 1 hour before departure. Later flights to \(trip.destinationCity) today leave at 9:15 AM and 1:40 PM. Tap Change flight on the Travel tab to see fares."
    } else if text.contains("cancel") {
      return "You can cancel this trip from the Travel tab. Since your fare is refundable, you'll get credit for the full amount, using confirmation code \(trip.confirmationCode)."
    } else if text.contains("check-in") || text.contains("check in") {
      return "You're checked in for \(trip.flightNumber). Your boarding pass is ready in the boarding pass bar on the Flight status tab."
    } else if text.contains("weather") || text.contains("temperature") {
      return "It's forecast to be \(trip.arrivalWeather) in \(trip.destinationCity) when you land."
    } else if usesScreenContext && ["summar", "selected", "this", "these", "them"].contains(where: text.contains) {
      return "Here's what you shared:\n" + contextItems.map { "• \($0.detail)" }.joined(separator: "\n")
    } else if text.contains("gate") {
      return "Flight \(trip.flightNumber) departs from gate \(trip.gate)."
    } else if text.contains("board") {
      return "Boarding starts at \(boarding). You're in group \(trip.boardingGroup)."
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
      return "I can help with your gate, boarding time, seat, departure, flight status, and anything on the Travel cards, like the inflight menu, upgrades, bags, and Wi-Fi."
    }
  }
}
