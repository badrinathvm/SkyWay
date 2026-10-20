import SwiftUI

struct PlaceholderTabView: View {
  var tab: AppTab

  var body: some View {
    NavigationStack {
      ContentUnavailableView(tab.title, systemImage: tab.systemImage, description: Text("Coming soon."))
        .navigationTitle(tab.title)
    }
  }
}
