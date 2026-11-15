import SwiftUI
import VisionKit

/// The system document camera. Every page scanned in one session is one receipt,
/// so a long receipt can be captured in parts.
struct DocumentScanner: UIViewControllerRepresentable {
  var onFinish: ([UIImage]) -> Void

  static var isSupported: Bool { VNDocumentCameraViewController.isSupported }

  func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
    let controller = VNDocumentCameraViewController()
    controller.delegate = context.coordinator
    return controller
  }

  func updateUIViewController(_ controller: VNDocumentCameraViewController, context: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(onFinish: onFinish)
  }

  final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
    var onFinish: ([UIImage]) -> Void

    init(onFinish: @escaping ([UIImage]) -> Void) {
      self.onFinish = onFinish
    }

    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
      onFinish((0..<scan.pageCount).map(scan.imageOfPage(at:)))
    }

    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
      onFinish([])
    }

    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
      onFinish([])
    }
  }
}
