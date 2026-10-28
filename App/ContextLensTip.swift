import SwiftUI
import TipKit

/// Teaches people they can drag + onto a single item, right after they picked one the slow way.
struct ContextLensTip: Tip {
  /// Donated when the person asks about exactly one item they picked in selection mode.
  static let askedAboutOneItem = Event(id: "askedAboutOneItem")

  /// Set once the person has dragged the lens, which retires this tip and the peek.
  @Parameter
  static var hasUsedLens: Bool = false

  var title: Text {
    Text("Faster Next Time")
  }

  var message: Text? {
    Text("Drag \(Image(systemName: "plus")) straight onto a card to ask about just that card.")
  }

  var image: Image? {
    Image(systemName: "hand.draw")
  }

  var rules: [Rule] {
    #Rule(Self.askedAboutOneItem) { $0.donations.count >= 1 }
    #Rule(Self.$hasUsedLens) { $0 == false }
  }

  var options: [any TipOption] {
    MaxDisplayCount(2)
  }

  static func didAskAboutOneItem() {
    Task { await askedAboutOneItem.donate() }
  }

  // MARK: Peek

  private static let peekCountKey = "contextLensPeekCount"
  private static let maxPeeks = 2
  @MainActor private static var hasPeekedThisLaunch = false

  /// Whether the lens should demonstrate itself, at most once per launch and twice ever.
  @MainActor static var shouldPeek: Bool {
    !hasUsedLens && !hasPeekedThisLaunch
      && UserDefaults.standard.integer(forKey: peekCountKey) < maxPeeks
  }

  /// Lets the peek play again, for testing.
  static func resetPeeks() {
    UserDefaults.standard.removeObject(forKey: peekCountKey)
  }

  @MainActor static func didPeek() {
    hasPeekedThisLaunch = true
    UserDefaults.standard.set(UserDefaults.standard.integer(forKey: peekCountKey) + 1, forKey: peekCountKey)
  }
}
