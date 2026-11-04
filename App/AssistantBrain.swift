import Foundation
import FoundationModels
import ImageIO
import UIKit
import Vision

/// Answers the person's questions with the on-device Apple Foundation Model.
/// The conversation lives in one session, so follow-ups remember earlier questions and photos.
@MainActor
final class AssistantBrain {
  /// The reply so far. Each update replaces the previous one while the model streams.
  struct Update {
    var answer = ""
    var followUps: [String] = []
    var scannedTrip: ScannedTrip?
  }

  /// Whether the model can answer on this device. When it can't, the assistant uses its keyword answers.
  static var isAvailable: Bool {
    SystemLanguageModel.default.isAvailable
  }

  /// Whether the model on this device understands images.
  static var canSeePhotos: Bool {
    isAvailable && SystemLanguageModel.default.capabilities.contains(.vision)
  }

  private let trip: Trip
  private var session: LanguageModelSession

  init(trip: Trip) {
    self.trip = trip
    session = Self.makeSession(for: trip)
  }

  /// Loads the model ahead of the first question, so the answer starts sooner.
  func prewarm() {
    guard Self.isAvailable else { return }
    session.prewarm()
  }

  /// Starts a new conversation, forgetting earlier questions and photos.
  func reset() {
    session = Self.makeSession(for: trip)
  }

  /// Streams the answer to `question`, calling `onUpdate` with the reply so far.
  func reply(
    to question: String,
    context: [ContextItem],
    image: UIImage?,
    onUpdate: (Update) -> Void
  ) async throws {
    do {
      try await stream(question, context: context, image: image, onUpdate: onUpdate)
    } catch LanguageModelError.contextSizeExceeded {
      // A long conversation filled the model's memory. Start fresh and ask again.
      reset()
      try await stream(question, context: context, image: image, onUpdate: onUpdate)
    }
  }

  private func stream(
    _ question: String,
    context: [ContextItem],
    image: UIImage?,
    onUpdate: (Update) -> Void
  ) async throws {
    let prompt = Self.prompt(for: question, context: context, image: image)
    if image != nil {
      for try await snapshot in session.streamResponse(to: prompt, generating: PhotoReply.self) {
        let reply = snapshot.content
        onUpdate(Update(answer: reply.answer ?? "", followUps: reply.followUps ?? [], scannedTrip: reply.scannedTrip?.complete))
      }
    } else {
      for try await snapshot in session.streamResponse(to: prompt, generating: AssistantReply.self) {
        let reply = snapshot.content
        onUpdate(Update(answer: reply.answer ?? "", followUps: reply.followUps ?? []))
      }
    }
  }

  private static func prompt(for question: String, context: [ContextItem], image: UIImage?) -> Prompt {
    let shared = context.isEmpty
      ? ""
      : "The person shared these items from their screen:\n" + context.map { "- \($0.detail)" }.joined(separator: "\n") + "\n\n"
    let text = shared + question
    return Prompt {
      if let image, let cgImage = image.cgImage {
        text
        Attachment(cgImage, orientation: CGImagePropertyOrientation(image.imageOrientation)).label("photo")
      } else {
        text
      }
    }
  }

  private static func makeSession(for trip: Trip) -> LanguageModelSession {
    let departure = trip.departure.formatted(date: .complete, time: .shortened)
    let boarding = trip.boardingTime.formatted(date: .omitted, time: .shortened)
    let leaveBy = trip.leaveByTime.formatted(date: .omitted, time: .shortened)
    let instructions = """
      You are the Skyway travel assistant in the Skyway airline app. Answer questions about the person's trip \
      in one to three short sentences. Use only the facts below and your tools. If you don't know something, \
      say so and suggest where in the app to look. Never make up flight details.

      Today is \(Date.now.formatted(date: .complete, time: .shortened)).

      The person's trip:
      - Passenger: \(trip.passengerName)
      - Flight \(trip.flightNumber) from \(trip.originCity) (\(trip.originCode)) to \(trip.destinationCity) (\(trip.destinationCode))
      - Departs \(departure) from gate \(trip.gate)
      - Boarding starts \(boarding), group \(trip.boardingGroup)
      - Seat \(trip.seat)
      - Confirmation code \(trip.confirmationCode)
      - Leave for the airport by \(leaveBy)

      Use getTravelInfo for the inflight menu, upgrades, directions, bags, Wi-Fi, changes, cancellation, \
      check-in, arrival weather, and flight status. Use getMileage for questions about drives, miles, or \
      mileage deductions.

      When the person attaches a photo, look at it carefully. Use the barcode reader on boarding pass \
      barcodes and the text reader for printed text. If the photo shows a flight, say whether it matches \
      the trip above.
      """
    var tools: [any Tool] = [TravelInfoTool(trip: trip), MileageTool()]
    // The Vision tools are in the device SDK, but not the simulator's.
    #if canImport(_Vision_FoundationModels)
    if canSeePhotos {
      tools += [BarcodeReaderTool(), OCRTool()]
    }
    #endif
    return LanguageModelSession(tools: tools, instructions: instructions)
  }
}

private extension ScannedTrip.PartiallyGenerated {
  /// The scanned trip once its required fields have streamed in.
  var complete: ScannedTrip? {
    guard let flightNumber, let originCode, let destinationCode else { return nil }
    return ScannedTrip(
      flightNumber: flightNumber,
      originCode: originCode,
      destinationCode: destinationCode,
      departure: departure ?? nil,
      passengerName: passengerName ?? nil,
      gate: gate ?? nil,
      seat: seat ?? nil,
      boardingGroup: boardingGroup ?? nil,
      confirmationCode: confirmationCode ?? nil
    )
  }
}

private extension CGImagePropertyOrientation {
  /// `UIImage.cgImage` drops the photo's rotation, so the model is told how to turn it upright.
  init(_ orientation: UIImage.Orientation) {
    self = switch orientation {
    case .up: .up
    case .upMirrored: .upMirrored
    case .down: .down
    case .downMirrored: .downMirrored
    case .left: .left
    case .leftMirrored: .leftMirrored
    case .right: .right
    case .rightMirrored: .rightMirrored
    @unknown default: .up
    }
  }
}
