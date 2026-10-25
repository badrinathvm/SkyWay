import SwiftUI

/// A resizable, dismissible sheet with the assistant's answers and follow-up suggestions.
/// It grows to fit its content as more answers arrive, up to the large detent.
struct AssistantAnswerSheet: View {
  var assistant: FlightAssistant
  @Environment(\.dismiss) private var dismiss
  @State private var contentHeight: CGFloat = 320
  @State private var detent: PresentationDetent = .height(320)

  /// Space for the drag indicator and sheet padding around the content.
  private let chromeHeight: CGFloat = 24

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        header

        ForEach(assistant.sessionMessages) { message in
          MessageBubble(message: message)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }

        if !assistant.followUpSuggestions.isEmpty {
          suggestions
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 20)
      .padding(.bottom, 12)
      .frame(maxWidth: .infinity, alignment: .leading)
      .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
        contentHeight = height
      }
    }
    .defaultScrollAnchor(.bottom, for: .sizeChanges)
    .scrollBounceBehavior(.basedOnSize)
    .presentationDetents([fittedDetent, .medium, .large], selection: $detent)
    .presentationDragIndicator(.visible)
    .presentationBackgroundInteraction(.enabled(upThrough: .medium))
    .onChange(of: contentHeight) {
      // Grow to fit new answers unless the person has already expanded the sheet fully.
      guard detent != .large else { return }
      withAnimation(.smooth) {
        detent = fittedDetent
      }
    }
    .animation(.smooth, value: assistant.sessionMessages)
    .sensoryFeedback(.impact(weight: .light), trigger: assistant.sessionMessages.count)
  }

  private var fittedDetent: PresentationDetent {
    .height(contentHeight + chromeHeight)
  }

  private var header: some View {
    HStack(alignment: .top) {
      VStack(alignment: .leading, spacing: 6) {
        Label("Skyway Assistant", systemImage: "sparkles")
          .font(.headline)
          .foregroundStyle(.tint)
        if assistant.usesScreenContext {
          Label("Using \(assistant.screenCardCount) cards on screen", systemImage: "rectangle.stack")
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.tint.opacity(0.12), in: .capsule)
        }
      }
      Spacer()
      Button("Close", systemImage: "xmark") {
        dismiss()
      }
      .labelStyle(.iconOnly)
      .buttonStyle(.bordered)
      .buttonBorderShape(.circle)
    }
  }

  private var suggestions: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Ask a follow-up")
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)
      ForEach(assistant.followUpSuggestions, id: \.self) { suggestion in
        Button(suggestion, systemImage: "sparkles") {
          withAnimation(.smooth) {
            assistant.send(suggestion)
          }
        }
        .buttonStyle(.bordered)
        .transition(.blurReplace)
      }
    }
  }
}
