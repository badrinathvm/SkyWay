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
    Text("Tap \(Image(systemName: "sparkles.rectangle.stack")) or touch and hold the bar to choose cards to share with the assistant.")
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
