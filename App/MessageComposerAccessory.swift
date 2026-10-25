import SwiftUI
import TipKit

/// A prompt in the tab bar accessory that opens the composer above the keyboard.
/// Tab bar accessories stay behind the keyboard, so the text field itself lives in `AssistantComposer`.
/// A long press switches it to a selection bar for choosing which on-screen items to share.
struct MessageComposerAccessory: View {
  var assistant: FlightAssistant
  @Environment(\.tabViewBottomAccessoryPlacement) private var placement
  private let tip = ScreenContextTip()

  var body: some View {
    Group {
      if context.mode == .selecting {
        selectionBar
      } else {
        promptBar
      }
    }
    .font(isInline ? .subheadline : .body)
    .padding(.leading, isInline ? 12 : 16)
    .padding(.trailing, 4)
    .animation(.smooth, value: isInline)
    .animation(.smooth, value: context.mode)
    .sensoryFeedback(.impact(weight: .medium), trigger: context.mode == .selecting)
  }

  private var context: ScreenContext { assistant.screenContext }

  private var isInline: Bool { placement == .inline }

  private var isAssistantIdle: Bool {
    !assistant.isComposing && !assistant.isShowingAnswerSheet
  }

  private var promptBar: some View {
    HStack(spacing: 8) {
      // A visible way to share what's on screen; the long press is a shortcut for the same thing.
      Button("Choose What's on Screen", systemImage: "sparkles.rectangle.stack", action: beginSelecting)
        .labelStyle(.iconOnly)
        .foregroundStyle(.tint)
        .buttonStyle(.borderless)
        // Hide the tip while the person is asking a question or reading an answer.
        .popoverTip(isAssistantIdle ? tip : nil, arrowEdge: .bottom)

      HStack(spacing: 8) {
        Text("Ask about your trip…")
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
      .contentShape(.rect)
      // Separate gestures so a long press starts selecting without also opening the composer.
      .onTapGesture(perform: compose)
      .onLongPressGesture(minimumDuration: 0.4, perform: beginSelecting) { isPressing in
        withAnimation(.easeIn(duration: 0.4)) {
          context.isPreviewing = isPressing
        }
      }
      .accessibilityElement(children: .ignore)
      .accessibilityAddTraits(.isButton)
      .accessibilityLabel("Ask about your trip")
      .accessibilityHint("Opens a text field. Touch and hold to choose what's on screen to share.")
      .accessibilityAction { compose() }
    }
    .transition(.blurReplace)
  }

  private var selectionBar: some View {
    HStack(spacing: 8) {
      Button("Cancel", systemImage: "xmark") {
        withAnimation(.smooth) { context.clear() }
      }
      .labelStyle(.iconOnly)
      .buttonStyle(.borderless)

      Text("\(context.selectedIDs.count) of \(context.items.count) selected")
        .lineLimit(1)
        .contentTransition(.numericText())

      Spacer(minLength: 0)

      Button(context.areAllSelected ? "None" : "All") {
        withAnimation(.snappy) {
          if context.areAllSelected {
            context.selectNone()
          } else {
            context.selectAll()
          }
        }
      }
      .buttonStyle(.borderless)

      Button("Ask", systemImage: "arrow.up", action: compose)
        .labelStyle(.iconOnly)
        .fontWeight(.semibold)
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.circle)
    }
    .transition(.blurReplace)
  }

  private func compose() {
    withAnimation(.smooth) {
      assistant.startComposing()
    }
  }

  private func beginSelecting() {
    ScreenContextTip.hasChosenContext = true
    tip.invalidate(reason: .actionPerformed)
    withAnimation(.smooth) {
      context.beginSelecting()
    }
  }
}
