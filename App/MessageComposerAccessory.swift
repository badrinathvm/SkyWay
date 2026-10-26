import SwiftUI
import TipKit

/// A prompt in the tab bar accessory that opens the composer above the keyboard.
/// Tab bar accessories stay behind the keyboard, so the text field itself lives in `AssistantComposer`.
/// A long press switches it to a selection bar for choosing which on-screen items to share,
/// and dragging from + points a lens at a single item to ask about.
struct MessageComposerAccessory: View {
  var assistant: FlightAssistant
  @Environment(\.tabViewBottomAccessoryPlacement) private var placement
  @GestureState private var isTouchingPlus = false

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

  /// The bar's tip, when it's the group's current tip, so only one screen-context tip shows at a time.
  private var barTip: ScreenContextTip? {
    SkywayTips.screenContext.currentTip as? ScreenContextTip
  }

  private var isAssistantIdle: Bool {
    !assistant.isComposing && !assistant.isShowingAnswerSheet
  }

  private var promptBar: some View {
    HStack(spacing: 8) {
      // A visible way to share what's on screen; the long press is a shortcut for the same thing.
      // Tapping chooses from everything on screen, and dragging out a lens picks a single item.
      Image(systemName: "plus")
        .foregroundStyle(.tint)
        .frame(width: 32, height: 32)
        .contentShape(.rect)
        .scaleEffect(context.isLensActive ? 0.6 : 1)
        .opacity(context.isLensActive ? 0.4 : 1)
        .animation(.bouncy, value: context.isLensActive)
        .gesture(lensGesture)
        .onChange(of: isTouchingPlus) { _, touching in
          // A drag the system cancels never ends, so put the lens away here.
          if !touching && context.isLensActive {
            context.cancelLens()
          }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Add What's on Screen")
        .accessibilityHint("Touch and drag onto an item to ask about it.")
        .accessibilityAction { beginSelecting() }
        // Hide the tip while the person is asking a question, reading an answer, or dragging.
        .popoverTip(isAssistantIdle && !context.isLensActive ? barTip : nil, arrowEdge: .bottom)

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

  /// A tap starts selecting; a drag shows the lens. Global coordinates match the frames
  /// items report, and the touch keeps tracking after the finger leaves the bar.
  private var lensGesture: some Gesture {
    DragGesture(minimumDistance: 0, coordinateSpace: .global)
      .updating($isTouchingPlus) { _, touching, _ in touching = true }
      .onChanged { value in
        let distance = hypot(value.translation.width, value.translation.height)
        guard context.isLensActive || distance > Self.dragThreshold else { return }
        context.moveLens(fingerAt: value.location, from: value.startLocation)
      }
      .onEnded { value in
        guard context.isLensActive else {
          beginSelecting()
          return
        }
        SkywayTips.didChooseContext()
        if let item = context.endLens() {
          withAnimation(.smooth) {
            assistant.askAbout(item)
          }
        }
      }
  }

  private static let dragThreshold: CGFloat = 8

  private func compose() {
    withAnimation(.smooth) {
      assistant.startComposing()
    }
  }

  private func beginSelecting() {
    SkywayTips.didChooseContext()
    withAnimation(.smooth) {
      context.beginSelecting()
    }
  }
}
