import SwiftUI

struct MessageBubble: View {
  var message: ChatMessage

  var body: some View {
    HStack {
      if isUser { Spacer(minLength: 48) }
      Text(message.text)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .foregroundStyle(isUser ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
        .background(isUser ? AnyShapeStyle(.tint) : AnyShapeStyle(.fill.tertiary), in: .rect(cornerRadius: 18))
      if !isUser { Spacer(minLength: 48) }
    }
    .accessibilityLabel("\(isUser ? "You" : "Skyway"): \(message.text)")
  }

  private var isUser: Bool { message.sender == .user }
}
