import Foundation

struct ChatMessage: Identifiable, Hashable {
  enum Sender {
    case user
    case assistant
  }

  var id = UUID()
  var sender: Sender
  var text: String
  var date = Date.now
}
