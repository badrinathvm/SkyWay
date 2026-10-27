import SwiftUI

/// The whole assistant conversation, shown in the Flight status inspector.
/// A trailing column on iPad and the iPhone Duo inner display, and a sheet on iPhone.
struct AssistantChatView: View {
  var assistant: FlightAssistant
  @State private var draft = ""
  @FocusState private var isPromptFocused: Bool

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 12) {
        if assistant.messages.isEmpty {
          suggestions
        } else {
          ForEach(assistant.messages) { message in
            MessageBubble(message: message)
              .transition(.move(edge: .bottom).combined(with: .opacity))
          }
        }
      }
      .padding()
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .defaultScrollAnchor(.bottom, for: .sizeChanges)
    .scrollDismissesKeyboard(.interactively)
    .safeAreaInset(edge: .bottom) {
      promptBar
    }
    .safeAreaInset(edge: .top, spacing: 0) {
      header
    }
    .animation(.smooth, value: assistant.messages)
    .sensoryFeedback(.impact(weight: .light), trigger: assistant.messages.count)
    // Used only when the inspector shows as a sheet, in compact width.
    .presentationDetents([.medium, .large])
    .presentationBackgroundInteraction(.enabled(upThrough: .medium))
  }

  private var header: some View {
    Label("Skyway Assistant", systemImage: "sparkles")
      .font(.headline)
      .foregroundStyle(.tint)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal)
      .padding(.vertical, 12)
      .accessibilityAddTraits(.isHeader)
  }

  private var suggestions: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Try asking")
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)
      ForEach(FlightAssistant.suggestions, id: \.self) { suggestion in
        Button(suggestion, systemImage: "sparkles") {
          assistant.send(suggestion)
        }
        .buttonStyle(.bordered)
      }
    }
  }

  private var promptBar: some View {
    HStack(spacing: 8) {
      TextField("Ask about your trip…", text: $draft)
        .focused($isPromptFocused)
        .submitLabel(.send)
        .onSubmit(send)
        .padding(.leading, 16)

      Button("Send", systemImage: "arrow.up", action: send)
        .labelStyle(.iconOnly)
        .fontWeight(.semibold)
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.circle)
        .disabled(!canSend)
    }
    .padding(6)
    .glassEffect(in: .capsule)
    .padding(.horizontal)
    .padding(.bottom, 8)
  }

  private var canSend: Bool {
    !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private func send() {
    guard canSend else { return }
    assistant.send(draft)
    draft = ""
  }
}
