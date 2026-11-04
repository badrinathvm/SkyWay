import SwiftUI

/// The text field and send button, pinned above the keyboard while composing.
/// There's no close button: dropping focus, by scrolling or tapping outside, dismisses it.
struct AssistantComposer: View {
  @Bindable var assistant: FlightAssistant
  @FocusState private var isFocused: Bool
  @State private var plusBounce = 0
  @State private var isPickingPhoto = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      if showsAddChip {
        // Offer screen context right when someone is about to ask a question.
        Button("Add What's on Screen", systemImage: "rectangle.stack.badge.plus", action: chooseContext)
          .font(.subheadline.weight(.medium))
          .buttonStyle(.bordered)
          .buttonBorderShape(.capsule)
          .transition(.blurReplace)
      }

      if let image = assistant.draftImage {
        AttachedPhotoThumbnail(image: image) {
          withAnimation(.smooth) { assistant.draftImage = nil }
        }
        .transition(.scale.combined(with: .opacity))
      }

      inputRow
    }
    .padding(12)
    .glassEffect(in: .rect(cornerRadius: 28))
    .padding(.horizontal)
    .padding(.bottom, 8)
    .animation(.smooth, value: showsAddChip)
    .photoAttachmentPicker(isPresented: $isPickingPhoto, image: $assistant.draftImage)
    .onAppear {
      isFocused = true
      assistant.prepareToAnswer()
    }
    .onChange(of: isPickingPhoto) { _, picking in
      // Back to typing once a photo is chosen, or the picker is cancelled.
      if !picking {
        isFocused = true
      }
    }
    .onChange(of: isFocused) { _, focused in
      // Choosing context and sending already leave the composer, so this only catches dismissals.
      // Picking a photo also takes focus, but the person is still composing.
      if !focused && assistant.isComposing && !isPickingPhoto {
        withAnimation(.smooth) {
          assistant.stopComposing()
        }
      }
    }
    .task {
      // Draw the eye to + until the person has used it, once per composer.
      guard !ScreenContextTip.hasChosenContext, !reduceMotion else { return }
      try? await Task.sleep(for: .seconds(0.6))
      plusBounce += 1
    }
    .sensoryFeedback(.impact(weight: .light), trigger: assistant.messages.count)
  }

  private var inputRow: some View {
    HStack(spacing: 8) {
      // Starts choosing what's on screen, or changes the current selection.
      Button("Add Context", systemImage: "plus", action: chooseContext)
        .labelStyle(.iconOnly)
        .fontWeight(.semibold)
        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)
        .symbolEffect(.bounce, value: plusBounce)

      if assistant.canAttachPhotos {
        Button("Attach Photo", systemImage: "photo.badge.plus") {
          isPickingPhoto = true
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)
      }

      TextField(
        placeholder,
        text: $assistant.draft
      )
      .focused($isFocused)
      .submitLabel(.send)
      .onSubmit(send)

      Button("Send", systemImage: "arrow.up", action: send)
        .labelStyle(.iconOnly)
        .fontWeight(.semibold)
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.circle)
        .disabled(!assistant.canSend)
    }
  }

  private var showsAddChip: Bool {
    isFocused && assistant.screenContext.mode == .off
  }

  private var placeholder: String {
    if assistant.draftImage != nil {
      return "Ask about this photo…"
    }
    let count = assistant.screenContext.mode == .off ? 0 : assistant.screenContext.selectedIDs.count
    return switch count {
    case 0: "Ask about your trip…"
    case 1: "Ask about 1 selected item…"
    default: "Ask about \(count) selected items…"
    }
  }

  private func chooseContext() {
    SkywayTips.didChooseContext()
    withAnimation(.smooth) {
      assistant.chooseContextFromComposer()
    }
    isFocused = false
  }

  private func send() {
    guard assistant.canSend else { return }
    withAnimation(.smooth) {
      assistant.sendDraftToSheet()
    }
    isFocused = false
  }
}
