import SwiftUI
import TipKit

/// Teaches people they can share what's on screen with the assistant.
struct ScreenContextTip: Tip {
  /// Donated each time the Travel tab appears.
  static let travelViewed = Event(id: "travelViewed")

  /// Set once the person has chosen items to share, so the tip stops showing.
  @Parameter
  static var hasChosenContext: Bool = false

  var title: Text {
    Text("Ask About What's on Screen")
  }

  var message: Text? {
    Text("Tap \(Image(systemName: "plus")) or touch and hold the bar to choose cards to share with the assistant.")
  }

  var image: Image? {
    Image(systemName: "sparkles")
  }

  var rules: [Rule] {
    #Rule(Self.travelViewed) { $0.donations.count >= 2 }
    #Rule(Self.$hasChosenContext) { $0 == false }
  }

  var options: [any TipOption] {
    MaxDisplayCount(2)
  }
}

enum SkywayTips {
  /// The screen-context tips, shown one at a time. New ones can join this group.
  @MainActor static let screenContext = TipGroup(.firstAvailable) {
    ScreenContextTip()
  }

  /// Records that the person used screen context, which retires every screen-context tip.
  static func didChooseContext() {
    ScreenContextTip.hasChosenContext = true
  }
}
