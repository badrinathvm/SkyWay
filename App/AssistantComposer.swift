import SwiftUI

/// The text field and send button, pinned above the keyboard while composing.
struct AssistantComposer: View {
  @Bindable var assistant: FlightAssistant
  @FocusState private var isFocused: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      if assistant.screenContext.mode == .off {
        // Offer screen context right when someone is about to ask a question.
        Button("Add What's on Screen", systemImage: "rectangle.stack.badge.plus") {
          isFocused = false
          ScreenContextTip.hasChosenContext = true
          withAnimation(.smooth) {
            assistant.chooseContextFromComposer()
          }
        }
        .font(.subheadline.weight(.medium))
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
      }

      inputRow
    }
    .padding(12)
    .glassEffect(in: .rect(cornerRadius: 28))
    .padding(.horizontal)
    .padding(.bottom, 8)
    .onAppear { isFocused = true }
    .sensoryFeedback(.impact(weight: .light), trigger: assistant.messages.count)
  }

  private var inputRow: some View {
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
        placeholder,
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

  private var placeholder: String {
    let count = assistant.screenContext.mode == .off ? 0 : assistant.screenContext.selectedIDs.count
    return switch count {
    case 0: "Ask about your trip…"
    case 1: "Ask about 1 selected item…"
    default: "Ask about \(count) selected items…"
    }
  }

  private func send() {
    guard assistant.canSend else { return }
    isFocused = false
    withAnimation(.smooth) {
      assistant.sendDraftToSheet()
    }
  }
}
