import Foundation
import StoreKit

/// What happened after a subscriber reached the Confirm Cancellation sheet.
enum RetentionOutcome: Hashable {
  /// The App Store applied a Retention Offer configured in App Store Connect (`offerType` 5).
  case retentionOfferRedeemed(offerID: String?)
  /// The subscriber accepted a promotional offer your real-time endpoint chose.
  case promotionalOfferRedeemed(offerID: String?)
  case switchedPlan(to: String)
  case kept
  case cancelled(activeUntil: Date?)

  var title: String {
    switch self {
    case .retentionOfferRedeemed: "Retention offer redeemed"
    case .promotionalOfferRedeemed: "Promotional offer redeemed"
    case .switchedPlan: "Switched plan"
    case .kept: "Kept subscription"
    case .cancelled: "Subscription cancelled"
    }
  }

  var detail: String {
    switch self {
    case .retentionOfferRedeemed(let offerID), .promotionalOfferRedeemed(let offerID):
      offerID ?? "Offer applied to the next renewal."
    case .switchedPlan(let productID):
      "Now on \(productID)."
    case .kept:
      "The subscriber chose Keep Subscription."
    case .cancelled(let date):
      if let date {
        "Active until \(date.formatted(date: .abbreviated, time: .omitted))."
      } else {
        "Won't renew."
      }
    }
  }

  var systemImage: String {
    switch self {
    case .retentionOfferRedeemed, .promotionalOfferRedeemed: "gift.fill"
    case .switchedPlan: "arrow.left.arrow.right"
    case .kept: "checkmark.seal.fill"
    case .cancelled: "xmark.seal.fill"
    }
  }

  var isSaved: Bool {
    if case .cancelled = self { false } else { true }
  }
}

extension Transaction.OfferType {
  /// A Retention Offer the App Store applied from the Confirm Cancellation sheet. StoreKit has no
  /// named constant for it yet, so match the raw value the App Store sends.
  static let retention = Transaction.OfferType(rawValue: 5)
}
