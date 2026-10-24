import SwiftUI

extension EnvironmentValues {
  /// Whether cards should glow to show they're part of the onscreen context.
  @Entry var isHighlightingCards = false
}

extension View {
  /// Adds an animated glowing border when `isHighlightingCards` is set in the environment.
  func cardHighlight(cornerRadius: CGFloat) -> some View {
    modifier(CardHighlight(cornerRadius: cornerRadius))
  }
}

private struct CardHighlight: ViewModifier {
  var cornerRadius: CGFloat
  @Environment(\.isHighlightingCards) private var isHighlighting
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private static let colors: [Color] = [.blue, .purple, .pink, .orange, .yellow, .cyan, .blue]

  func body(content: Content) -> some View {
    content
      .overlay {
        if isHighlighting {
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
          .transition(.opacity)
        }
      }
      .scaleEffect(isHighlighting ? 0.98 : 1)
      .animation(.smooth, value: isHighlighting)
  }
}
