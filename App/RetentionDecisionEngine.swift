import Foundation

/// A stand-in for your Get Retention Message endpoint. On a real server this logic runs after
/// verifying the request's JWS; here it runs in the app so the Confirm Cancellation preview can
/// show what the App Store would display.
struct RetentionDecisionEngine {
  /// What your server knows about the subscriber, looked up by `originalTransactionId`.
  struct SubscriberSignals {
    var loggedDriveCount: Int
    var isMonthly: Bool
    var monthsSubscribed: Int
    var hasRedeemedRetentionOffer: Bool
  }

  /// One round trip: what the App Store sent, what the server answered, and what the customer sees.
  struct Exchange: Identifiable {
    var request: RetentionRealtimeRequest
    /// `nil` when the endpoint failed or timed out.
    var response: RetentionRealtimeResponse?
    var latency: Duration
    var message: RetentionMessage
    var usedDefaultMessage: Bool { response == nil }
    var id: String { request.requestIdentifier }

    var requestJSON: String { Self.prettyJSON(request) }
    var responseJSON: String {
      response.map(Self.prettyJSON) ?? "// No response within 700 ms. The App Store shows the default message."
    }

    private static func prettyJSON(_ value: some Encodable) -> String {
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
      guard let data = try? encoder.encode(value) else { return "{}" }
      return String(decoding: data, as: UTF8.self)
    }
  }

  /// The App Store's production deadline for a response.
  static let deadline = Duration.milliseconds(700)

  static let annualProductID = "skyway.plus.annual"
  static let retentionOfferID = "skyway.plus.retention.3mfree"

  var scenario: RetentionScenario = .automatic

  /// Simulates the App Store calling your endpoint, including its fallback when the endpoint is too slow.
  func exchange(for request: RetentionRealtimeRequest, signals: SubscriberSignals) async -> Exchange {
    let clock = ContinuousClock()
    let start = clock.now
    let response = await respond(to: request, signals: signals)
    let latency = clock.now - start

    guard let response, latency < Self.deadline,
      let message = RetentionMessage.approved(id: response.messageIdentifier)
    else {
      return Exchange(request: request, response: nil, latency: latency, message: .default)
    }
    return Exchange(request: request, response: response, latency: latency, message: message)
  }

  /// The decision your server makes. Keep it fast: precompute signals rather than querying slow
  /// services here.
  func respond(to request: RetentionRealtimeRequest, signals: SubscriberSignals) async -> RetentionRealtimeResponse? {
    switch scenario {
    case .textOnly:
      return .message(messageIdentifier: RetentionMessage.default.messageIdentifier)
    case .textWithImage:
      return .message(messageIdentifier: RetentionMessage.mileageLog.messageIdentifier)
    case .switchPlan:
      return .alternateProduct(messageIdentifier: RetentionMessage.switchToAnnual.messageIdentifier, productId: Self.annualProductID)
    case .promotionalOffer:
      return .promotionalOffer(messageIdentifier: RetentionMessage.comeBackOffer.messageIdentifier, offerId: Self.retentionOfferID)
    case .serverTimeout:
      try? await Task.sleep(for: .milliseconds(900))
      return .message(messageIdentifier: RetentionMessage.mileageLog.messageIdentifier)
    case .automatic:
      return automaticResponse(for: request, signals: signals)
    }
  }

  /// Picks the message most likely to keep this subscriber.
  private func automaticResponse(for request: RetentionRealtimeRequest, signals: SubscriberSignals) -> RetentionRealtimeResponse {
    // Heavy CarPlay users lose the most, so remind them what goes away.
    if signals.loggedDriveCount >= 3 {
      return .message(messageIdentifier: RetentionMessage.mileageLog.messageIdentifier)
    }
    // Monthly subscribers who might be cancelling over the bill: suggest the annual plan.
    if signals.isMonthly && request.productId != Self.annualProductID {
      return .alternateProduct(messageIdentifier: RetentionMessage.switchToAnnual.messageIdentifier, productId: Self.annualProductID)
    }
    // Loyal subscribers who haven't had an offer yet.
    if signals.monthsSubscribed >= 6 && !signals.hasRedeemedRetentionOffer {
      return .promotionalOffer(messageIdentifier: RetentionMessage.comeBackOffer.messageIdentifier, offerId: Self.retentionOfferID)
    }
    return .message(messageIdentifier: RetentionMessage.default.messageIdentifier)
  }
}
