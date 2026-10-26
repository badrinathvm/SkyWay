// xcode: set sdk=iOS

import SwiftUI
import TipKit

@main
struct AppDefinition: App {
  init() {
    #if DEBUG
    // Testing aids, toggled in Xcode under Product › Scheme › Edit Scheme › Run › Arguments.
    let arguments = ProcessInfo.processInfo.arguments
    if arguments.contains("-resetTips") {
      // Forget which tips were shown, dismissed, or ruled out, and every event donation.
      try? Tips.resetDatastore()
    }
    if arguments.contains("-showAllTips") {
      // Show every tip immediately, ignoring its rules.
      Tips.showAllTipsForTesting()
    }
    #endif
    try? Tips.configure()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .task { await TripStore.indexInSpotlight() }
    }
  }
}
