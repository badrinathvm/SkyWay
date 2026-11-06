import Foundation
import StoreKit

/// Skyway Plus: the mock auto-renewable subscription the Retention Messaging demo is built on.
/// Products come from `StoreKit/SkywayPlus.storekit` when running locally.
@MainActor
@Observable
final class SubscriptionStore {
  static let shared = SubscriptionStore()

  static let groupID = "21540001"
  static let monthlyProductID = "skyway.plus.monthly"
  static let annualProductID = RetentionDecisionEngine.annualProductID

  private(set) var products: [Product] = []
  private(set) var transaction: Transaction?
  private(set) var renewalInfo: Product.SubscriptionInfo.RenewalInfo?
  private(set) var lastOutcome: RetentionOutcome?
  private(set) var isPurchasing = false
  var errorMessage: String?

  /// Set when the cancellation preview's Cancel Subscription is tapped. Only the App Store can
  /// really cancel, so the demo remembers the choice until the subscription changes.
  private var isCancelledInPreview = false

  @ObservationIgnored private var updatesTask: Task<Void, Never>?

  private init() {
    updatesTask = Task { [weak self] in
      for await result in Transaction.updates {
        guard case .verified(let transaction) = result else { continue }
        await transaction.finish()
        await self?.handle(transaction)
      }
    }
  }

  var isSubscribed: Bool { transaction != nil }

  var currentProduct: Product? {
    products.first { $0.id == transaction?.productID }
  }

  var isMonthly: Bool { transaction?.productID == Self.monthlyProductID }

  var expirationDate: Date? { transaction?.expirationDate }

  var willAutoRenew: Bool {
    !isCancelledInPreview && (renewalInfo?.willAutoRenew ?? true)
  }

  /// The date the confirmation sheet quotes: the current period's end, or a month out when not subscribed.
  var serviceEndDate: Date {
    expirationDate ?? Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now
  }

  func load() async {
    do {
      products = try await Product.products(for: [Self.monthlyProductID, Self.annualProductID])
        .sorted { $0.price < $1.price }
    } catch {
      errorMessage = error.localizedDescription
    }
    await refreshStatus()
  }

  /// Reads the group's current status, including whether it will renew.
  func refreshStatus() async {
    let statuses = (try? await Product.SubscriptionInfo.status(for: Self.groupID)) ?? []
    let active = statuses.first { $0.state == .subscribed || $0.state == .inGracePeriod || $0.state == .inBillingRetryPeriod }
    guard let active, case .verified(let transaction) = active.transaction else {
      transaction = nil
      renewalInfo = nil
      return
    }
    self.transaction = transaction
    if case .verified(let renewalInfo) = active.renewalInfo {
      self.renewalInfo = renewalInfo
      if !renewalInfo.willAutoRenew {
        lastOutcome = .cancelled(activeUntil: transaction.expirationDate)
      }
    }
  }

  func purchase(_ product: Product) async {
    isPurchasing = true
    defer { isPurchasing = false }
    do {
      let result = try await product.purchase()
      if case .success(.verified(let transaction)) = result {
        await transaction.finish()
        await handle(transaction)
      }
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  // MARK: Confirm Cancellation actions

  func switchPlan(to productID: String) async {
    guard let product = products.first(where: { $0.id == productID }) else { return }
    await purchase(product)
  }

  /// Accepting an offer on the real sheet is handled by the App Store, which then delivers a
  /// transaction through `Transaction.updates`. Redeeming a signed promotional offer needs your
  /// server's In-App Purchase key, so the demo records the outcome directly.
  func acceptOffer(_ offerID: String) {
    isCancelledInPreview = false
    lastOutcome = .promotionalOfferRedeemed(offerID: offerID)
  }

  func keepSubscription() {
    isCancelledInPreview = false
    lastOutcome = .kept
  }

  func cancelInPreview() {
    isCancelledInPreview = true
    lastOutcome = .cancelled(activeUntil: serviceEndDate)
  }

  // MARK: Retention Messaging

  /// The request the App Store would send your endpoint for this subscriber.
  func realtimeRequest() -> RetentionRealtimeRequest {
    RetentionRealtimeRequest(
      originalTransactionId: transaction.map { String($0.originalID) } ?? "2000000912345678",
      appAppleId: 6_740_000_000,
      productId: transaction?.productID ?? Self.monthlyProductID,
      userLocale: Locale.current.identifier(.bcp47),
      requestIdentifier: UUID().uuidString.lowercased(),
      environment: .sandbox,
      signedDate: Int64(Date.now.timeIntervalSince1970 * 1000)
    )
  }

  /// What your server would know about this subscriber.
  func subscriberSignals() -> RetentionDecisionEngine.SubscriberSignals {
    let start = transaction?.originalPurchaseDate ?? .now
    let months = Calendar.current.dateComponents([.month], from: start, to: .now).month ?? 0
    return RetentionDecisionEngine.SubscriberSignals(
      loggedDriveCount: DriveTripStore.shared.trips.count,
      isMonthly: transaction == nil || isMonthly,
      monthsSubscribed: months,
      hasRedeemedRetentionOffer: transaction?.offer?.type == .retention
    )
  }

  // MARK: Transactions

  private func handle(_ transaction: Transaction) async {
    let previousProductID = self.transaction?.productID
    isCancelledInPreview = false
    await refreshStatus()

    // Offers redeemed from the Confirm Cancellation sheet arrive as ordinary transactions.
    // Update any fixed list of offer types: retention offers use the new value 5.
    let offerType = transaction.offer?.type
    if offerType == .retention {
      lastOutcome = .retentionOfferRedeemed(offerID: transaction.offer?.id)
    } else if offerType == .promotional {
      lastOutcome = .promotionalOfferRedeemed(offerID: transaction.offer?.id)
    } else if let previousProductID, previousProductID != transaction.productID {
      lastOutcome = .switchedPlan(to: transaction.productID)
    }
  }
}
