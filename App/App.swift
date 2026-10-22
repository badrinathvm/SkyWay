// xcode: set sdk=iOS

import SwiftUI

@main
struct AppDefinition: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
        .task { await TripStore.indexInSpotlight() }
    }
  }
}
