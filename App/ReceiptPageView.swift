import SwiftUI

/// One receipt page, full size, zoomable.
struct ReceiptPageView: View {
  var fileName: String
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Group {
        if let image = ReceiptImageStore.image(named: fileName) {
          ScrollView([.horizontal, .vertical]) {
            Image(uiImage: image)
              .resizable()
              .scaledToFit()
              .containerRelativeFrame(.horizontal)
              .accessibilityLabel("Receipt")
          }
        } else {
          ContentUnavailableView("Receipt Unavailable", systemImage: "receipt")
        }
      }
      .navigationTitle("Receipt")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Done", systemImage: "xmark") {
            dismiss()
          }
        }
      }
    }
  }
}
