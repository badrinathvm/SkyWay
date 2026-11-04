import PhotosUI
import SwiftUI

extension View {
  /// Presents the photo library and puts the chosen photo in `image`, ready to attach to a question.
  func photoAttachmentPicker(isPresented: Binding<Bool>, image: Binding<UIImage?>) -> some View {
    modifier(PhotoAttachmentPicker(isPresented: isPresented, image: image))
  }
}

private struct PhotoAttachmentPicker: ViewModifier {
  @Binding var isPresented: Bool
  @Binding var image: UIImage?
  @State private var selection: PhotosPickerItem?

  func body(content: Content) -> some View {
    content
      .photosPicker(isPresented: $isPresented, selection: $selection, matching: .images)
      .task(id: selection) {
        guard let selection else { return }
        if let data = try? await selection.loadTransferable(type: Data.self),
           let loaded = UIImage(data: data) {
          withAnimation(.smooth) {
            image = loaded
          }
        }
        self.selection = nil
      }
  }
}
