import UIKit

struct ChatMessage: Identifiable, Hashable {
  enum Sender {
    case user
    case assistant
  }

  var id = UUID()
  var sender: Sender
  var text: String
  /// A photo the person attached to their question.
  var image: UIImage?
  /// Flight details the assistant read from an attached photo.
  var scannedTrip: ScannedTrip?
  /// Whether the assistant is still writing this message.
  var isPending = false
  var date = Date.now
}
