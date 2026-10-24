import SwiftUI

struct MessageComposerAccessory: View {
  @Bindable var assistant: FlightAssistant
  @FocusState private var isFocused: Bool
  @Environment(\.tabViewBottomAccessoryPlacement) private var placement

  var body: some View {
    HStack(spacing: 8) {
      TextField("Ask about your flight…", text: $assistant.draft)
        .focused($isFocused)
        .submitLabel(.send)
        .onSubmit(send)
        .font(isInline ? .subheadline : .body)

      Button("Send", systemImage: "arrow.up", action: send)
        .labelStyle(.iconOnly)
        .font(isInline ? .footnote.weight(.semibold) : .body.weight(.semibold))
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.circle)
        .disabled(!assistant.canSend)
    }
    .padding(.leading, isInline ? 12 : 16)
    .padding(.trailing, 4)
    .animation(.smooth, value: isInline)
    .sensoryFeedback(.impact(weight: .light), trigger: assistant.messages.count)
  }

  private var isInline: Bool { placement == .inline }

  private func send() {
    guard assistant.canSend else { return }
    assistant.sendDraft()
  }
}
