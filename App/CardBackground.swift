import SwiftUI

extension View {
  /// A card on a grouped background. The secondary grouped color lifts it off the background
  /// in dark mode, where `.background` would be black on black, and a hairline keeps its edge visible.
  func cardBackground(cornerRadius: CGFloat = 20) -> some View {
    background {
      RoundedRectangle(cornerRadius: cornerRadius)
        .fill(Color(.secondarySystemGroupedBackground))
        .strokeBorder(.separator, lineWidth: 0.5)
    }
  }
}
