import SwiftUI
import TipKit

/// Shown inside the composer to explain the + button, with a button that starts choosing items.
struct ComposerContextTip: Tip {
  static let chooseItemsActionID = "choose-items"

  var title: Text {
    Text("Ask About What's on Screen")
  }

  var message: Text? {
    Text("Tap \(Image(systemName: "plus")) to choose cards to share with the assistant.")
  }

  var image: Image? {
    Image(systemName: "sparkles")
  }

  var actions: [Action] {
    Action(id: Self.chooseItemsActionID, title: "Choose Items")
  }

  var rules: [Rule] {
    // Shares the parameter with the bar tip, so using the feature from anywhere retires both.
    #Rule(ScreenContextTip.$hasChosenContext) { $0 == false }
  }

  var options: [any TipOption] {
    MaxDisplayCount(2)
  }
}

enum SkywayTips {
  /// Shows at most one screen-context tip at a time, whichever becomes eligible first.
  @MainActor static let screenContext = TipGroup(.firstAvailable) {
    ScreenContextTip()
    ComposerContextTip()
  }

  /// Records that the person used screen context, which retires every screen-context tip.
  static func didChooseContext() {
    ScreenContextTip.hasChosenContext = true
  }
}
