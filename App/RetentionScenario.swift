import Foundation

/// Which response the mock server gives, so each Confirm Cancellation layout can be previewed.
enum RetentionScenario: String, CaseIterable, Identifiable {
  /// Let the decision engine choose from the subscriber's real signals.
  case automatic
  case textOnly
  case textWithImage
  case switchPlan
  case promotionalOffer
  /// The endpoint misses the 700 ms deadline, so the App Store falls back to the default message.
  case serverTimeout

  var id: Self { self }

  var title: String {
    switch self {
    case .automatic: "Automatic"
    case .textOnly: "Text only"
    case .textWithImage: "Text and image"
    case .switchPlan: "Switch plan"
    case .promotionalOffer: "Promotional offer"
    case .serverTimeout: "Server timeout"
    }
  }

  var systemImage: String {
    switch self {
    case .automatic: "wand.and.sparkles"
    case .textOnly: "text.alignleft"
    case .textWithImage: "photo"
    case .switchPlan: "arrow.left.arrow.right"
    case .promotionalOffer: "gift"
    case .serverTimeout: "clock.badge.exclamationmark"
    }
  }
}
