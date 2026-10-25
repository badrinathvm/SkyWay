import SwiftUI

/// The text field and send button, pinned above the keyboard while composing.
struct AssistantComposer: View {
  @Bindable var assistant: FlightAssistant
  @FocusState private var isFocused: Bool

  var body: some View {
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
    .padding(12)
    .glassEffect(in: .rect(cornerRadius: 28))
    .padding(.horizontal)
    .padding(.bottom, 8)
    .onAppear { isFocused = true }
    .sensoryFeedback(.impact(weight: .light), trigger: assistant.messages.count)
  }

  private func send() {
    guard assistant.canSend else { return }
    isFocused = false
    withAnimation(.smooth) {
      assistant.sendDraftToSheet()
    }
  }
}
