import Foundation
import FoundationModels
import Observation
import UIKit

/// Holds the assistant conversation and answers questions from the trip and the cards on screen.
@MainActor
@Observable
final class FlightAssistant {
  var trip: Trip
  var draft = ""
  /// A photo attached to the draft, sent along with the question.
  var draftImage: UIImage?
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

  /// Follow-ups the model suggested with its latest answer.
  private var modelFollowUps: [String] = []
  /// The answer being streamed, so a new question can stop it.
  private var replyTask: Task<Void, Never>?
  private let brain: AssistantBrain

  var usesScreenContext: Bool { !contextItems.isEmpty }

  /// True while the assistant is writing an answer.
  var isResponding: Bool { replyTask != nil }

  /// Whether a photo can be attached, which needs a model that understands images.
  var canAttachPhotos: Bool { AssistantBrain.canSeePhotos }

  static let suggestions = [
    "What gate do I leave from?",
    "When do I board?",
    "What's my seat?",
  ]

  private static let screenSuggestions = TravelAction.all.map(\.question)

  init(trip: Trip) {
    self.trip = trip
    brain = AssistantBrain(trip: trip)
  }

  var canSend: Bool {
    !isResponding && (draftImage != nil || !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
  }

  /// Loads the model while the person types, so the answer starts sooner.
  func prepareToAnswer() {
    brain.prewarm()
  }

  /// Follow-up questions for the answer sheet, skipping ones already asked.
  var followUpSuggestions: [String] {
    guard !isResponding else { return [] }
    let asked = Set(sessionMessages.filter { $0.sender == .user }.map(\.text))
    if !modelFollowUps.isEmpty {
      return Array(modelFollowUps.filter { !asked.contains($0) }.prefix(3))
    }
    let pool = usesScreenContext
      ? contextItems.compactMap(\.suggestion) + ["Summarize what I selected"]
      : Self.suggestions + Self.screenSuggestions
    return Array(pool.filter { !asked.contains($0) }.prefix(3))
  }

  func startComposing() {
    screenContext.lock()
    isComposing = true
  }

  /// Opens the composer to ask about a single item, picked by dragging the lens onto it.
  func askAbout(_ item: ContextItem) {
    screenContext.select(only: item.id)
    startComposing()
  }

  /// Leaves the composer so the person can choose what's on screen, then returns with Ask.
  func chooseContextFromComposer() {
    isComposing = false
    if screenContext.mode == .locked {
      screenContext.resumeSelecting()
    } else {
      screenContext.beginSelecting()
    }
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
    let image = draftImage
    draft = ""
    draftImage = nil
    send(question, image: image)
  }

  /// Sends the draft from the Travel composer and shows the reply in the answer sheet.
  func sendDraftToSheet() {
    let question = draft
    let image = draftImage
    draft = ""
    draftImage = nil
    sessionMessages = []
    modelFollowUps = []
    contextItems = screenContext.mode == .off ? [] : screenContext.selectedItems
    // Picking one item in selection mode is what the lens does faster, so suggest it.
    if contextItems.count == 1 && !screenContext.wasPickedWithLens {
      ContextLensTip.didAskAboutOneItem()
    }
    isComposing = false
    send(question, image: image)
    isShowingAnswerSheet = true
  }

  func endSession() {
    isShowingAnswerSheet = false
    screenContext.clear()
    contextItems = []
    sessionMessages = []
    modelFollowUps = []
    draftImage = nil
    replyTask?.cancel()
    replyTask = nil
    // The next session starts a fresh conversation with the model.
    brain.reset()
  }

  func send(_ text: String, image: UIImage? = nil) {
    let typed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !typed.isEmpty || image != nil, !isResponding else { return }
    let question = typed.isEmpty ? "What's in this photo?" : typed
    let reply = ChatMessage(sender: .assistant, text: "", isPending: true)
    let exchange = [ChatMessage(sender: .user, text: typed, image: image), reply]
    messages.append(contentsOf: exchange)
    sessionMessages.append(contentsOf: exchange)
    modelFollowUps = []

    guard AssistantBrain.isAvailable else {
      let answer = image == nil
        ? fallbackAnswer(to: question)
        : "Questions about photos need Apple Intelligence, which isn't available on this device."
      updateMessage(reply.id) {
        $0.text = answer
        $0.isPending = false
      }
      return
    }

    let context = contextItems
    replyTask = Task {
      do {
        try await brain.reply(to: question, context: context, image: image) { update in
          updateMessage(reply.id) {
            $0.text = update.answer
            $0.scannedTrip = update.scannedTrip
          }
          modelFollowUps = update.followUps
        }
      } catch is CancellationError {
      } catch {
        updateMessage(reply.id) { $0.text = failureMessage(for: error, question: question, hasImage: image != nil) }
        modelFollowUps = []
      }
      updateMessage(reply.id) { $0.isPending = false }
      replyTask = nil
    }
  }

  /// Changes a message in both the whole conversation and the current session.
  private func updateMessage(_ id: ChatMessage.ID, _ change: (inout ChatMessage) -> Void) {
    if let index = messages.firstIndex(where: { $0.id == id }) {
      change(&messages[index])
    }
    if let index = sessionMessages.firstIndex(where: { $0.id == id }) {
      change(&sessionMessages[index])
    }
  }

  /// What to say when the model couldn't answer. If the model itself failed, such as while it's
  /// still downloading, text questions get the keyword answer instead of an error.
  private func failureMessage(for error: any Error, question: String, hasImage: Bool) -> String {
    switch error {
    case LanguageModelError.guardrailViolation, LanguageModelError.refusal:
      "I can't help with that. Try asking about your flight, your gate, or your drives."
    case LanguageModelError.unsupportedLanguageOrLocale:
      "I can only answer in a language Apple Intelligence supports."
    default:
      hasImage
        ? "I couldn't look at that photo right now. Please try again in a moment."
        : fallbackAnswer(to: question)
    }
  }

  var boardingTime: Date {
    trip.boardingTime
  }

  /// The keyword answer used when Apple Intelligence isn't available on this device.
  private func fallbackAnswer(to question: String) -> String {
    let text = question.lowercased()
    // Whole words, for keywords that hide inside other words, like "eat" in "seat".
    let words = Set(text.split { !$0.isLetter }.map(String.init))
    let departure = trip.departure.formatted(date: .omitted, time: .shortened)
    let boarding = boardingTime.formatted(date: .omitted, time: .shortened)
    let details = { (topic: TravelKnowledge.Topic) in TravelKnowledge.details(about: topic, for: self.trip) }

    // Questions about the travel cards come first, since they often mention a gate or seat too.
    if text.contains("menu") || text.contains("food") || words.contains("eat") || text.contains("drink") {
      return details(.inflightMenu)
    } else if text.contains("upgrade") {
      return details(.seatUpgrade)
    } else if text.contains("get to") || text.contains("terminal") || text.contains("direction") || text.contains("find my gate") {
      return details(.terminalDirections)
    } else if text.contains("bag") || text.contains("luggage") {
      return details(.checkedBags)
    } else if text.contains("wi-fi") || text.contains("wifi") || text.contains("internet") || text.contains("entertainment") {
      return details(.wifiAndEntertainment)
    } else if text.contains("change") {
      return details(.changeFlight)
    } else if text.contains("cancel") {
      return details(.cancelTrip)
    } else if text.contains("check-in") || text.contains("check in") {
      return details(.checkIn)
    } else if text.contains("weather") || text.contains("temperature") {
      return details(.arrivalWeather)
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
      return details(.flightStatus)
    } else if text.contains("confirmation") {
      return "Your confirmation code is \(trip.confirmationCode)."
    } else {
      return "I can help with your gate, boarding time, seat, departure, flight status, and anything on the Travel cards, like the inflight menu, upgrades, bags, and Wi-Fi."
    }
  }
}
