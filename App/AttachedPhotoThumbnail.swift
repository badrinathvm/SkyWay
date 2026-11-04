import SwiftUI

/// The photo attached to a draft question, with a button to remove it.
struct AttachedPhotoThumbnail: View {
  var image: UIImage
  var onRemove: () -> Void

  var body: some View {
    Image(uiImage: image)
      .resizable()
      .scaledToFill()
      .frame(width: 64, height: 64)
      .clipShape(.rect(cornerRadius: 12))
      .accessibilityLabel("Attached photo")
      .overlay(alignment: .topTrailing) {
        Button("Remove Photo", systemImage: "xmark", action: onRemove)
          .labelStyle(.iconOnly)
          .font(.caption2.weight(.bold))
          .foregroundStyle(.white)
          .frame(width: 22, height: 22)
          .background(.black.opacity(0.6), in: .circle)
          .buttonStyle(.plain)
          .offset(x: 6, y: -6)
      }
      .padding(.top, 6)
      .padding(.trailing, 6)
  }
}
