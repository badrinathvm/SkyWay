// xcode: set sdk=iOS

import SwiftUI
import TipKit

@main
struct AppDefinition: App {
  init() {
    try? Tips.configure()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .task { await TripStore.indexInSpotlight() }
    }
  }
}
