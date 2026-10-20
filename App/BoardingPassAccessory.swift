import SwiftUI

struct BoardingPassAccessory: View {
  var trip: Trip
  var action: () -> Void
  @Environment(\.tabViewBottomAccessoryPlacement) private var placement

  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        Image(systemName: "qrcode")
          .font(isInline ? .footnote : .body)
          .foregroundStyle(.white)
          .frame(width: isInline ? 28 : 36, height: isInline ? 28 : 36)
          .background(.tint, in: .circle)

        VStack(alignment: .leading, spacing: 0) {
          Text("Boarding pass")
            .font(.subheadline.weight(.semibold))
          Text(trip.title)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .lineLimit(1)

        Spacer(minLength: 0)

        Image(systemName: "chevron.right")
          .font(.footnote.weight(.semibold))
          .foregroundStyle(.secondary)
      }
      .padding(.horizontal, isInline ? 8 : 12)
      .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Boarding pass, \(trip.title)")
    .accessibilityHint("Shows your boarding pass")
    .animation(.smooth, value: isInline)
  }

  private var isInline: Bool { placement == .inline }
}
