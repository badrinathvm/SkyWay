import Foundation

/// A retention message as you upload it with the Retention Messaging API's Upload Message
/// endpoint (or create it in App Store Connect › Monetization › Subscriptions › Retention Messaging).
/// The App Store shows it in the "From the Developer" card on the Confirm Cancellation sheet.
///
/// Apple rejects text that mentions prices, discounts, or promotions, so offers are attached to
/// the message rather than written into it.
struct RetentionMessage: Identifiable, Codable, Hashable {
  /// The UUID you choose when uploading the message; real-time responses refer to it.
  var messageIdentifier: String
  var header: String
  var body: String
  var bulletPoints: [String] = []
  /// The approved image from the Asset Library, if any. Here, a key into `RetentionMessageArtwork`.
  var image: RetentionMessageArtwork?

  var id: String { messageIdentifier }
}

/// Artwork for messages that include an image. Real messages use an uploaded image; the demo
/// draws an equivalent in SwiftUI so it needs no bundled assets.
enum RetentionMessageArtwork: String, Codable, Hashable {
  case carPlayMileage
  case tripAssistant
}

extension RetentionMessage {
  /// The messages this demo pretends are approved for Skyway Plus.
  static let approved: [RetentionMessage] = [.default, .mileageLog, .switchToAnnual, .comeBackOffer]

  /// The default message: shown when the real-time endpoint fails, times out, or isn't configured.
  static let `default` = RetentionMessage(
    messageIdentifier: "0b8e2d6c-4f0a-4c1e-9a52-3c1f6d7e9a01",
    header: "Your trips stay organized with Skyway Plus",
    body: "Skyway Plus keeps every flight, drive, and boarding pass in one place, synced across your devices."
  )

  /// A message with an image, personalized for people who log drives in CarPlay.
  static let mileageLog = RetentionMessage(
    messageIdentifier: "6a1f3b2e-8d4c-4b7a-9e10-2f5c8a9d0b02",
    header: "Keep your mileage log",
    body: "If you cancel, Skyway stops logging drives from CarPlay. You'll lose:",
    bulletPoints: [
      "Automatic trip detection in CarPlay",
      "Business and personal mileage reports",
      "Deduction estimates for tax time",
    ],
    image: .carPlayMileage
  )

  /// A switch-plan message, used with an `alternateProduct` response.
  static let switchToAnnual = RetentionMessage(
    messageIdentifier: "ed7f25fc-5741-46a3-8502-062e0fb8afd0",
    header: "Prefer to pay once a year?",
    body: "Switch to the annual plan and keep everything in Skyway Plus without a monthly bill."
  )

  /// A promotional-offer message, used with a `promotionalOffer` response.
  static let comeBackOffer = RetentionMessage(
    messageIdentifier: "c4d9e1a7-2b6f-4e8c-8a31-7d0e5f2b9c04",
    header: "Stay for the trips ahead",
    body: "Your trip assistant and synced boarding passes are ready for your next journey.",
    image: .tripAssistant
  )

  static func approved(id: String) -> RetentionMessage? {
    approved.first { $0.messageIdentifier == id }
  }
}
