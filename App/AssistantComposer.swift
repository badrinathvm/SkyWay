import SwiftUI

/// The text field and send button, pinned above the keyboard while composing.
/// There's no close button: dropping focus, by scrolling or tapping outside, dismisses it.
struct AssistantComposer: View {
  @Bindable var assistant: FlightAssistant
  @FocusState private var isFocused: Bool
  @State private var plusBounce = 0
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      if showsAddChip {
        // Offer screen context right when someone is about to ask a question.
        Button("Add What's on Screen", systemImage: "rectangle.stack.badge.plus", action: chooseContext)
          .font(.subheadline.weight(.medium))
          .buttonStyle(.bordered)
          .buttonBorderShape(.capsule)
          .transition(.blurReplace)
      }

      inputRow
    }
    .padding(12)
    .glassEffect(in: .rect(cornerRadius: 28))
    .padding(.horizontal)
    .padding(.bottom, 8)
    .animation(.smooth, value: showsAddChip)
    .onAppear { isFocused = true }
    .onChange(of: isFocused) { _, focused in
      // Choosing context and sending already leave the composer, so this only catches dismissals.
      if !focused && assistant.isComposing {
        withAnimation(.smooth) {
          assistant.stopComposing()
        }
      }
    }
    .task {
      // Draw the eye to + until the person has used it, once per composer.
      guard !ScreenContextTip.hasChosenContext, !reduceMotion else { return }
      try? await Task.sleep(for: .seconds(0.6))
      plusBounce += 1
    }
    .sensoryFeedback(.impact(weight: .light), trigger: assistant.messages.count)
  }

  private var inputRow: some View {
    HStack(spacing: 8) {
      // Starts choosing what's on screen, or changes the current selection.
      Button("Add Context", systemImage: "plus", action: chooseContext)
        .labelStyle(.iconOnly)
        .fontWeight(.semibold)
        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)
        .symbolEffect(.bounce, value: plusBounce)

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

  private var showsAddChip: Bool {
    isFocused && assistant.screenContext.mode == .off
  }

  private var placeholder: String {
    let count = assistant.screenContext.mode == .off ? 0 : assistant.screenContext.selectedIDs.count
    return switch count {
    case 0: "Ask about your trip…"
    case 1: "Ask about 1 selected item…"
    default: "Ask about \(count) selected items…"
    }
  }

  private func chooseContext() {
    SkywayTips.didChooseContext()
    withAnimation(.smooth) {
      assistant.chooseContextFromComposer()
    }
    isFocused = false
  }

  private func send() {
    guard assistant.canSend else { return }
    withAnimation(.smooth) {
      assistant.sendDraftToSheet()
    }
    isFocused = false
  }
}
