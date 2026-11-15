import SwiftUI

/// A recreation of the App Store's Confirm Cancellation sheet, showing the retention message the
/// mock real-time endpoint chose. The real sheet is system UI that only appears with a Sandbox or
/// production subscription, so this lets you see each layout in the simulator.
struct CancellationPreviewSheet: View {
  var exchange: RetentionDecisionEngine.Exchange
  var store: SubscriptionStore
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        header
        DeveloperMessageCard(exchange: exchange, store: store) {
          dismiss()
        }
      }
      .padding(.horizontal, 24)
      .padding(.top, 32)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .safeAreaInset(edge: .bottom) {
      VStack(spacing: 10) {
        Button {
          store.cancelInPreview()
          dismiss()
        } label: {
          Text("Cancel Subscription")
            .frame(maxWidth: .infinity)
        }
        Button {
          store.keepSubscription()
          dismiss()
        } label: {
          Text("Keep Subscription")
            .frame(maxWidth: .infinity)
        }
      }
      .buttonStyle(.glass)
      .buttonBorderShape(.capsule)
      .foregroundStyle(.tint)
      .controlSize(.large)
      .padding(.horizontal, 24)
      .padding(.bottom, 8)
    }
    .presentationDragIndicator(.visible)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 16) {
      RoundedRectangle(cornerRadius: 22)
        .fill(Color.accentColor.gradient)
        .frame(width: 96, height: 96)
        .overlay {
          Image(systemName: "airplane")
            .font(.system(size: 44, weight: .semibold))
            .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 4) {
        Text("Confirm Cancellation")
          .font(.title2.bold())
          .accessibilityAddTraits(.isHeader)
        Text("If you cancel this subscription, your service will end on \(store.serviceEndDate.formatted(date: .long, time: .omitted)).")
          .font(.title3)
          .foregroundStyle(.secondary)
      }
    }
  }
}

/// The "From the Developer" card: the one part of the sheet your retention message controls.
private struct DeveloperMessageCard: View {
  var exchange: RetentionDecisionEngine.Exchange
  var store: SubscriptionStore
  var onAction: () -> Void

  private var message: RetentionMessage { exchange.message }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("From the Developer")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemFill))

      VStack(alignment: .leading, spacing: 12) {
        if let image = message.image {
          RetentionArtwork(artwork: image)
        }
        Text(message.header)
          .font(.headline)
        Text(message.body)
          .font(.subheadline)
        if !message.bulletPoints.isEmpty {
          VStack(alignment: .leading, spacing: 6) {
            ForEach(message.bulletPoints, id: \.self) { point in
              Label(point, systemImage: "checkmark.circle.fill")
                .font(.subheadline)
                .symbolRenderingMode(.hierarchical)
            }
          }
        }
        actionButton
      }
      .padding(16)
    }
    .cardBackground(cornerRadius: 20)
    .clipShape(.rect(cornerRadius: 20))
  }

  @ViewBuilder
  private var actionButton: some View {
    switch exchange.response {
    case .alternateProduct(_, let productID)?:
      let product = store.products.first { $0.id == productID }
      offerButton(
        title: "Switch Plan",
        // The App Store, not your message, shows the price of the suggested plan.
        detail: product.map { "\($0.displayName) · \($0.displayPrice)/year" } ?? productID
      ) {
        Task {
          await store.switchPlan(to: productID)
          onAction()
        }
      }
    case .promotionalOffer(_, let offerID)?:
      offerButton(title: "Accept Offer", detail: "3 months free, then renews at the regular price") {
        store.acceptOffer(offerID)
        onAction()
      }
    default:
      EmptyView()
    }
  }

  private func offerButton(title: String, detail: String, action: @escaping () -> Void) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(detail)
        .font(.footnote)
        .foregroundStyle(.secondary)
      Button(action: action) {
        Text(title)
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .buttonBorderShape(.capsule)
      .controlSize(.large)
      .disabled(store.isPurchasing)
    }
    .padding(.top, 4)
  }
}

/// Stands in for an image uploaded to the App Store Connect Asset Library.
private struct RetentionArtwork: View {
  var artwork: RetentionMessageArtwork

  var body: some View {
    RoundedRectangle(cornerRadius: 14)
      .fill(gradient)
      .aspectRatio(16 / 9, contentMode: .fit)
      .overlay {
        HStack(spacing: 10) {
          Image(systemName: symbol)
            .font(.title.weight(.semibold))
          Text(caption)
            .font(.title3.bold())
        }
        .foregroundStyle(.white)
      }
      .accessibilityElement(children: .combine)
  }

  private var symbol: String {
    switch artwork {
    case .carPlayMileage: "car.fill"
    case .tripAssistant: "sparkles"
    }
  }

  private var caption: String {
    switch artwork {
    case .carPlayMileage: "Mileage Log"
    case .tripAssistant: "Trip Assistant"
    }
  }

  private var gradient: LinearGradient {
    switch artwork {
    case .carPlayMileage:
      LinearGradient(colors: [.indigo, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
    case .tripAssistant:
      LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
  }
}
