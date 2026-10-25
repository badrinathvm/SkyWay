import SwiftUI
import TipKit

/// The text field and send button, pinned above the keyboard while composing.
struct AssistantComposer: View {
  @Bindable var assistant: FlightAssistant
  @FocusState private var isFocused: Bool
  @State private var plusBounce = 0
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      // An inline tip, since a popover would collide with the keyboard.
      if let tip = SkywayTips.screenContext.currentTip as? ComposerContextTip {
        TipView(tip) { action in
          if action.id == ComposerContextTip.chooseItemsActionID {
            chooseContext()
          }
        }
        .tipBackground(.clear)
      }

      inputRow
    }
    .padding(12)
    .glassEffect(in: .rect(cornerRadius: 28))
    .padding(.horizontal)
    .padding(.bottom, 8)
    .onAppear { isFocused = true }
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
      Button("Close", systemImage: "xmark") {
        withAnimation(.smooth) {
          assistant.stopComposing()
        }
      }
      .labelStyle(.iconOnly)
      .buttonStyle(.bordered)
      .buttonBorderShape(.circle)

      addMenu

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

  /// Ways to add context to the question. New sources, like photos or a boarding pass, go here.
  private var addMenu: some View {
    Menu {
      Button(hasSelection ? "Change Selection" : "Add What's on Screen", systemImage: "sparkles.rectangle.stack") {
        chooseContext()
      }
      if hasSelection {
        Button("Remove Selection", systemImage: "xmark.circle", role: .destructive) {
          withAnimation(.smooth) {
            assistant.screenContext.clear()
          }
        }
      }
    } label: {
      Label("Add", systemImage: "plus")
    }
    .labelStyle(.iconOnly)
    .fontWeight(.semibold)
    .buttonStyle(.bordered)
    .buttonBorderShape(.circle)
    .symbolEffect(.bounce, value: plusBounce)
    .accessibilityLabel("Add Context")
  }

  private var hasSelection: Bool {
    assistant.screenContext.mode == .locked
  }

  private var placeholder: String {
    let count = assistant.screenContext.mode == .off ? 0 : assistant.screenContext.selectedIDs.count
    return switch count {
    case 0: "Ask about your trip…"
    case 1: "Ask about 1 selected item…"
    default: "Ask about \(count) selected items…"
    }
  }

  private func chooseContext() {
    isFocused = false
    SkywayTips.didChooseContext()
    withAnimation(.smooth) {
      assistant.chooseContextFromComposer()
    }
  }

  private func send() {
    guard assistant.canSend else { return }
    isFocused = false
    withAnimation(.smooth) {
      assistant.sendDraftToSheet()
    }
  }
}
