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
  /// The center of +, in global coordinates, where the peek starts.
  @State private var plusCenter: CGPoint?
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

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

  /// The group's current tip, so only one screen-context tip shows at a time.
  private var barTip: (any Tip)? {
    SkywayTips.screenContext.currentTip
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
        // Lifts on touch down, hinting that + can be picked up and dragged.
        .scaleEffect(context.isLensActive ? 0.6 : isTouchingPlus ? 1.25 : 1)
        .opacity(context.isLensActive ? 0.4 : 1)
        .animation(.bouncy, value: context.isLensActive)
        .animation(.snappy, value: isTouchingPlus)
        .sensoryFeedback(.impact(weight: .light), trigger: isTouchingPlus) { _, touching in touching }
        .onGeometryChange(for: CGPoint.self) { proxy in
          let frame = proxy.frame(in: .global)
          return CGPoint(x: frame.midX, y: frame.midY)
        } action: { center in
          plusCenter = center
        }
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
    .task { await peekIfNeeded() }
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
        // Touching + stops the demonstration, so it can't be mistaken for a drop.
        if context.isPeeking {
          context.cancelLens()
        }
        let distance = hypot(value.translation.width, value.translation.height)
        guard context.isLensActive || distance > Self.dragThreshold else { return }
        context.moveLens(fingerAt: value.location, from: value.startLocation)
      }
      .onEnded { value in
        guard context.isLensActive else {
          beginSelecting()
          return
        }
        SkywayTips.didUseLens()
        if let item = context.endLens() {
          withAnimation(.smooth) {
            assistant.askAbout(item)
          }
        }
      }
  }

  private static let dragThreshold: CGFloat = 8

  /// Shows that + can be dragged: the lens slides out to the first item, lights it up, and returns.
  private func peekIfNeeded() async {
    guard !reduceMotion, ContextLensTip.shouldPeek else { return }
    try? await Task.sleep(for: .seconds(1.2))
    // Don't compete with a tip, the composer, or a selection the person started.
    guard !Task.isCancelled, barTip == nil, isAssistantIdle, context.mode == .off,
          !context.isLensActive, let plusCenter,
          let target = context.peekTarget(above: plusCenter.y - 40)
    else { return }

    ContextLensTip.didPeek()
    context.preparePeek(at: plusCenter)
    // Let the lens settle at + before it moves, so it visibly travels from there.
    try? await Task.sleep(for: .milliseconds(50))
    withAnimation(.smooth(duration: 0.7)) {
      context.movePeek(to: target)
    }
    try? await Task.sleep(for: .seconds(1.4))
    guard context.isPeeking else { return }
    withAnimation(.smooth(duration: 0.6)) {
      context.cancelLens()
    }
  }

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
