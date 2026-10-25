import SwiftUI

extension EnvironmentValues {
  /// The screen's assistant context, used by `assistantContext(_:cornerRadius:)`.
  @Entry var screenContext: ScreenContext?
}

extension View {
  /// Marks this view as something the person can share with the assistant.
  ///
  /// Works on any view, card or not. A long press on the assistant bar selects it automatically
  /// if `item.isSelectedByDefault` is true, and the person can tap it to include or exclude it.
  func assistantContext(_ item: ContextItem, cornerRadius: CGFloat = 20) -> some View {
    modifier(AssistantContextModifier(item: item, cornerRadius: cornerRadius))
  }
}

private struct AssistantContextModifier: ViewModifier {
  var item: ContextItem
  var cornerRadius: CGFloat
  @Environment(\.screenContext) private var context

  func body(content: Content) -> some View {
    let mode = context?.mode ?? .off
    let isSelected = context?.isSelected(item.id) ?? false
    let isSelecting = mode == .selecting
    let isPreviewed = context?.isPreviewed(item) ?? false

    content
      .opacity(isSelecting && !isSelected ? 0.55 : 1)
      .overlay {
        if isSelected {
          ContextGlow(cornerRadius: cornerRadius)
            .transition(.opacity)
        } else if isPreviewed {
          // A faint glow while the bar is being pressed hints at what a long press will do.
          ContextGlow(cornerRadius: cornerRadius)
            .opacity(0.35)
            .transition(.opacity)
        } else if isSelecting {
          RoundedRectangle(cornerRadius: cornerRadius)
            .strokeBorder(.secondary, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            .allowsHitTesting(false)
            .transition(.opacity)
        }
      }
      .overlay(alignment: .topTrailing) {
        if isSelecting {
          Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.title3)
            .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            .background(.background, in: .circle)
            .offset(x: 6, y: -6)
            .contentTransition(.symbolEffect(.replace))
            .allowsHitTesting(false)
            .transition(.scale.combined(with: .opacity))
        }
      }
      // While selecting, a tap toggles the item instead of triggering the view's own action.
      .overlay {
        if isSelecting {
          Color.clear
            .contentShape(.rect(cornerRadius: cornerRadius))
            .onTapGesture {
              withAnimation(.snappy) {
                context?.toggle(item.id)
              }
            }
        }
      }
      .scaleEffect(isSelected ? 0.98 : 1)
      .animation(.smooth, value: isSelected)
      .animation(.smooth, value: isSelecting)
      .animation(.easeIn(duration: 0.4), value: isPreviewed)
      .sensoryFeedback(.selection, trigger: isSelected)
      .accessibilityAddTraits(isSelecting && isSelected ? .isSelected : [])
      .accessibilityActions {
        if isSelecting {
          Button(isSelected ? "Remove from Context" : "Add to Context") {
            context?.toggle(item.id)
          }
        }
      }
      .onAppear { context?.register(item) }
      .onDisappear { context?.unregister(item.id) }
  }
}

/// An animated rainbow border, like Apple Intelligence.
private struct ContextGlow: View {
  var cornerRadius: CGFloat
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private static let colors: [Color] = [.blue, .purple, .pink, .orange, .yellow, .cyan, .blue]

  var body: some View {
    TimelineView(.animation(paused: reduceMotion)) { timeline in
      let angle = Angle.degrees(timeline.date.timeIntervalSinceReferenceDate * 90)
      let gradient = AngularGradient(colors: Self.colors, center: .center, angle: angle)
      ZStack {
        RoundedRectangle(cornerRadius: cornerRadius)
          .strokeBorder(gradient, lineWidth: 4)
          .blur(radius: 6)
          .opacity(0.7)
        RoundedRectangle(cornerRadius: cornerRadius)
          .strokeBorder(gradient, lineWidth: 2.5)
      }
    }
    .allowsHitTesting(false)
  }
}
