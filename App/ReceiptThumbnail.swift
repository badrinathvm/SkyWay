import SwiftUI

/// A small preview of one receipt page.
struct ReceiptThumbnail: View {
  var fileName: String
  @State private var image: UIImage?

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 10)
        .fill(.quaternary)
      if let image {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
      } else {
        Image(systemName: "receipt")
          .font(.title2)
          .foregroundStyle(.secondary)
      }
    }
    .frame(width: 96, height: 128)
    .clipShape(.rect(cornerRadius: 10))
    .task(id: fileName) {
      image = ReceiptImageStore.image(named: fileName)?.preparingThumbnail(of: CGSize(width: 288, height: 384))
    }
  }
}
