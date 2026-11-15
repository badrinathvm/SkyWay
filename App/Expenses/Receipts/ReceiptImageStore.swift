import UIKit

/// Saves receipt photos as JPEG files in Application Support, named by `Expense.receiptFileNames`.
enum ReceiptImageStore {
  private static var directory: URL {
    URL.applicationSupportDirectory.appending(path: "Receipts", directoryHint: .isDirectory)
  }

  /// Saves the image and returns its file name, or nil if it couldn't be written.
  static func save(_ image: UIImage) -> String? {
    guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
    let fileName = "\(UUID().uuidString).jpg"
    do {
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      try data.write(to: directory.appending(path: fileName), options: .atomic)
      return fileName
    } catch {
      return nil
    }
  }

  static func image(named fileName: String) -> UIImage? {
    UIImage(contentsOfFile: directory.appending(path: fileName).path(percentEncoded: false))
  }

  static func deleteImage(named fileName: String) {
    try? FileManager.default.removeItem(at: directory.appending(path: fileName))
  }
}

extension UIImage {
  /// The image drawn upright and no larger than `maxDimension`, so text recognition sees it
  /// the right way up and saved receipts stay small.
  func normalizedForReceipt(maxDimension: CGFloat = 2000) -> UIImage {
    let scale = min(1, maxDimension / max(size.width, size.height))
    let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
      draw(in: CGRect(origin: .zero, size: targetSize))
    }
  }
}
