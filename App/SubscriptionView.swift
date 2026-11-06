import StoreKit
import SwiftUI

/// Skyway Plus: subscribe, manage the subscription, and preview the retention message the
/// App Store shows when a subscriber starts to cancel.
struct SubscriptionView: View {
  private let store = SubscriptionStore.shared
  @AppStorage("retentionScenario") private var scenario: RetentionScenario = .automatic
  @State private var isManagingSubscription = false
  @State private var isContactingServer = false
  @State private var lastExchange: RetentionDecisionEngine.Exchange?
  @State private var presentedExchange: RetentionDecisionEngine.Exchange?

  var body: some View {
    Form {
      statusSection
      if !store.isSubscribed || store.isMonthly {
        plansSection
      }
      retentionSection
      if let lastExchange {
        exchangeSection(lastExchange)
      }
    }
    .navigationTitle("Skyway Plus")
    .navigationBarTitleDisplayMode(.inline)
    .task { await store.load() }
    .manageSubscriptionsSheet(isPresented: $isManagingSubscription, subscriptionGroupID: SubscriptionStore.groupID)
    .onChange(of: isManagingSubscription) { _, isPresented in
      if !isPresented {
        Task { await store.refreshStatus() }
      }
    }
    .sheet(item: $presentedExchange) { exchange in
      CancellationPreviewSheet(exchange: exchange, store: store)
    }
    .alert("Purchase Failed", isPresented: errorBinding) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(store.errorMessage ?? "")
    }
  }

  // MARK: Sections

  private var statusSection: some View {
    Section {
      LabeledContent("Plan", value: store.currentProduct?.displayName ?? (store.isSubscribed ? "Skyway Plus" : "Not subscribed"))
      if let date = store.expirationDate {
        LabeledContent(store.willAutoRenew ? "Renews" : "Expires", value: date.formatted(date: .abbreviated, time: .shortened))
      }
      if let outcome = store.lastOutcome {
        Label {
          VStack(alignment: .leading, spacing: 2) {
            Text(outcome.title)
            Text(outcome.detail)
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
        } icon: {
          Image(systemName: outcome.systemImage)
            .foregroundStyle(outcome.isSaved ? Color.green : Color.red)
        }
      }
      if store.isSubscribed {
        Button("Manage Subscription", systemImage: "creditcard") {
          isManagingSubscription = true
        }
      }
    } header: {
      Text("Subscription")
    } footer: {
      if store.isSubscribed {
        Text("Manage Subscription opens Apple's sheet. With a Sandbox account and an approved message, tapping Cancel Subscription there shows your retention message.")
      }
    }
  }

  private var plansSection: some View {
    Section {
      if store.products.isEmpty {
        ProgressView()
          .frame(maxWidth: .infinity)
      }
      ForEach(store.products, id: \.id) { product in
        HStack {
          VStack(alignment: .leading, spacing: 2) {
            Text(product.displayName)
            Text(product.description)
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          Spacer()
          Button(product.displayPrice) {
            Task { await store.purchase(product) }
          }
          .buttonStyle(.borderedProminent)
          .buttonBorderShape(.capsule)
          .disabled(store.isPurchasing || store.transaction?.productID == product.id)
          .accessibilityLabel("Subscribe to \(product.displayName) for \(product.displayPrice)")
        }
      }
    } header: {
      Text(store.isSubscribed ? "Change Plan" : "Plans")
    }
  }

  private var retentionSection: some View {
    Section {
      Picker("Server Response", selection: $scenario) {
        ForEach(RetentionScenario.allCases) { scenario in
          Label(scenario.title, systemImage: scenario.systemImage)
            .tag(scenario)
        }
      }
      .pickerStyle(.menu)

      Button {
        Task { await previewCancellation() }
      } label: {
        HStack {
          Label("Preview Cancellation", systemImage: "rectangle.portrait.on.rectangle.portrait")
          if isContactingServer {
            Spacer()
            ProgressView()
          }
        }
      }
      .disabled(isContactingServer)
    } header: {
      Text("Retention Messaging")
    } footer: {
      Text("Simulates the App Store asking your server which message to show, then shows the Confirm Cancellation sheet. Automatic picks from your logged drives, plan, and tenure.")
    }
  }

  private func exchangeSection(_ exchange: RetentionDecisionEngine.Exchange) -> some View {
    Section("Last Server Exchange") {
      LabeledContent("Message", value: exchange.message.header)
      LabeledContent("Latency") {
        Text(exchange.latency.formatted(.units(allowed: [.milliseconds], width: .abbreviated)))
          .foregroundStyle(exchange.usedDefaultMessage ? .red : .secondary)
      }
      if exchange.usedDefaultMessage {
        Label("Missed the 700 ms deadline. The App Store showed the default message.", systemImage: "exclamationmark.triangle.fill")
          .font(.subheadline)
          .foregroundStyle(.orange)
      }
      DisclosureGroup("Request from the App Store") {
        JSONText(exchange.requestJSON)
      }
      DisclosureGroup("Your response") {
        JSONText(exchange.responseJSON)
      }
    }
  }

  // MARK: Actions

  private func previewCancellation() async {
    isContactingServer = true
    defer { isContactingServer = false }
    let engine = RetentionDecisionEngine(scenario: scenario)
    let exchange = await engine.exchange(for: store.realtimeRequest(), signals: store.subscriberSignals())
    lastExchange = exchange
    presentedExchange = exchange
  }

  private var errorBinding: Binding<Bool> {
    Binding {
      store.errorMessage != nil
    } set: { isPresented in
      if !isPresented { store.errorMessage = nil }
    }
  }
}

private struct JSONText: View {
  var text: String

  init(_ text: String) {
    self.text = text
  }

  var body: some View {
    ScrollView(.horizontal) {
      Text(text)
        .font(.caption.monospaced())
        .textSelection(.enabled)
        .padding(.vertical, 4)
    }
  }
}
