import SwiftUI

/// A prompt in the tab bar accessory that opens the composer above the keyboard.
/// Tab bar accessories stay behind the keyboard, so the text field itself lives in `AssistantComposer`.
struct MessageComposerAccessory: View {
  var assistant: FlightAssistant
  @Environment(\.tabViewBottomAccessoryPlacement) private var placement

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: assistant.isHighlightingCards ? "sparkles" : "bubble.left.and.text.bubble.right")
        .foregroundStyle(.tint)
        .contentTransition(.symbolEffect(.replace))
      Text(assistant.isHighlightingCards ? "Ask about what's on screen…" : "Ask about your trip…")
        .foregroundStyle(.secondary)
        .lineLimit(1)
      Spacer(minLength: 0)
      Image(systemName: "arrow.up")
        .font(.footnote.weight(.semibold))
        .foregroundStyle(.white)
        .frame(width: isInline ? 26 : 32, height: isInline ? 26 : 32)
        .background(.tint, in: .circle)
        .accessibilityHidden(true)
    }
    .font(isInline ? .subheadline : .body)
    .padding(.leading, isInline ? 12 : 16)
    .padding(.trailing, 4)
    .contentShape(.rect)
    // Separate gestures so a long press highlights cards without also opening the composer.
    .onTapGesture {
      withAnimation(.smooth) {
        assistant.startComposing()
      }
    }
    .onLongPressGesture(minimumDuration: 0.4) {
      withAnimation(.smooth) {
        assistant.toggleCardHighlight()
      }
    }
    .sensoryFeedback(.impact(weight: .medium), trigger: assistant.isHighlightingCards)
    .animation(.smooth, value: isInline)
    .accessibilityElement(children: .ignore)
    .accessibilityAddTraits(.isButton)
    .accessibilityLabel("Ask about your trip")
    .accessibilityAction {
      withAnimation(.smooth) {
        assistant.startComposing()
      }
    }
    .accessibilityHint("Opens a text field. Touch and hold to highlight the cards on screen.")
    .accessibilityAction(named: assistant.isHighlightingCards ? "Stop Highlighting Cards" : "Highlight Cards") {
      withAnimation(.smooth) {
        assistant.toggleCardHighlight()
      }
    }
  }

  private var isInline: Bool { placement == .inline }
}
