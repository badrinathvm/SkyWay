import SwiftUI

struct MessageBubble: View {
  var message: ChatMessage
  /// The person's trip, to say whether a scanned boarding pass matches it.
  var trip: Trip?

  var body: some View {
    HStack {
      if isUser { Spacer(minLength: 48) }
      VStack(alignment: isUser ? .trailing : .leading, spacing: 8) {
        if let image = message.image {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 180, height: 180)
            .clipShape(.rect(cornerRadius: 18))
            .accessibilityLabel("Attached photo")
        }
        if message.isPending && message.text.isEmpty {
          TypingIndicator()
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(.fill.tertiary, in: .rect(cornerRadius: 18))
        } else if !message.text.isEmpty {
          Text(message.text)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .foregroundStyle(isUser ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .background(isUser ? AnyShapeStyle(.tint) : AnyShapeStyle(.fill.tertiary), in: .rect(cornerRadius: 18))
            .contentTransition(.opacity)
        }
        if let scannedTrip = message.scannedTrip {
          ScannedTripCard(scannedTrip: scannedTrip, trip: trip)
            .transition(.blurReplace)
        }
      }
      if !isUser { Spacer(minLength: 48) }
    }
    .animation(.smooth, value: message.scannedTrip)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(accessibilityText)
  }

  private var isUser: Bool { message.sender == .user }

  private var accessibilityText: String {
    let sender = isUser ? "You" : "Skyway"
    if message.isPending && message.text.isEmpty {
      return "\(sender) is typing"
    }
    let photo = message.image == nil ? "" : "Photo. "
    return "\(sender): \(photo)\(message.text)"
  }
}

/// Three dots that pulse while the assistant writes its answer.
private struct TypingIndicator: View {
  var body: some View {
    HStack(spacing: 4) {
      ForEach(0..<3) { index in
        Circle()
          .frame(width: 7, height: 7)
          .foregroundStyle(.secondary)
          .phaseAnimator([0.3, 1]) { dot, opacity in
            dot.opacity(opacity)
          } animation: { _ in
            .easeInOut(duration: 0.5).delay(Double(index) * 0.15)
          }
      }
    }
    .accessibilityHidden(true)
  }
}
