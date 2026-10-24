import SwiftUI

/// The text field and send button, pinned above the keyboard while composing.
struct AssistantComposer: View {
  @Bindable var assistant: FlightAssistant
  @FocusState private var isFocused: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      if let reply = assistant.latestReply {
        Label(reply.text, systemImage: "sparkles")
          .font(.subheadline)
          .labelStyle(ReplyLabelStyle())
          .transition(.blurReplace)
      }

      HStack(spacing: 8) {
        Button("Close", systemImage: "xmark") {
          withAnimation(.smooth) {
            assistant.stopComposing()
          }
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)

        TextField(
          assistant.isHighlightingCards ? "Ask about what's on screen…" : "Ask about your trip…",
          text: $assistant.draft
        )
        .focused($isFocused)
        .submitLabel(.send)
        .onSubmit(send)

        Button("Send", systemImage: "arrow.up", action: send)
          .labelStyle(.iconOnly)
          .fontWeight(.semibold)
          .buttonStyle(.borderedProminent)
          .buttonBorderShape(.circle)
          .disabled(!assistant.canSend)
      }
    }
    .padding(12)
    .glassEffect(in: .rect(cornerRadius: 28))
    .padding(.horizontal)
    .padding(.bottom, 8)
    .onAppear { isFocused = true }
    .animation(.smooth, value: assistant.latestReply)
    .sensoryFeedback(.impact(weight: .light), trigger: assistant.messages.count)
  }

  private func send() {
    guard assistant.canSend else { return }
    withAnimation(.smooth) {
      assistant.sendDraft()
    }
    isFocused = true
  }
}

private struct ReplyLabelStyle: LabelStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
      configuration.icon
        .foregroundStyle(.tint)
      configuration.title
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.horizontal, 4)
  }
}
