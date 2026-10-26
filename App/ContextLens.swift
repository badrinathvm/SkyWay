import SwiftUI

/// A glass bubble that follows the person's finger while they drag from the assistant bar's +.
/// The item under it lights up, and releasing it there asks about that item.
struct ContextLens: View {
  var context: ScreenContext
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private static let size: CGFloat = 84

  var body: some View {
    GeometryReader { proxy in
      if let location = context.lensLocation {
        let origin = proxy.frame(in: .global).origin
        lens
          .scaleEffect(context.isLensActive || reduceMotion ? 1 : 0.3)
          .opacity(context.isLensActive ? 1 : 0)
          .position(x: location.x - origin.x, y: location.y - origin.y)
      }
    }
    .ignoresSafeArea()
    .allowsHitTesting(false)
    .animation(.bouncy, value: context.isLensActive)
    .animation(.snappy, value: isHovering)
    .sensoryFeedback(.selection, trigger: context.hoveredID) { _, new in new != nil }
    .accessibilityHidden(true)
  }

  private var isHovering: Bool { context.hoveredID != nil }

  private var lens: some View {
    Image(systemName: "sparkles")
      .font(.title.weight(.semibold))
      .foregroundStyle(.tint)
      .symbolEffect(.bounce, value: context.hoveredID)
      .frame(width: Self.size, height: Self.size)
      .glassEffect(.regular, in: .circle)
      .overlay {
        if isHovering {
          ContextGlow(cornerRadius: Self.size / 2)
            .transition(.opacity)
        }
      }
      .scaleEffect(isHovering ? 1.08 : 1)
      .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
  }
}
