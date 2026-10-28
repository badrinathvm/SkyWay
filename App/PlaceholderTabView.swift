import SwiftUI

struct PlaceholderTabView: View {
  var tab: AppTab
    @State private var assistant = FlightAssistant(trip: .sample)
    @State private var isShowingAssistant = false

  var body: some View {
    NavigationStack {
      ContentUnavailableView(tab.title, systemImage: tab.systemImage, description: Text("Coming soon."))
        .navigationTitle(tab.title)
        // A trailing column in regular width, and a sheet in compact width.
        .toolbar {
          Button("Assistant", systemImage: "bubble.left.and.text.bubble.right") {
            isShowingAssistant.toggle()
          }
        }
        .inspector(isPresented: $isShowingAssistant) {
          AssistantChatView(assistant: assistant)
            .inspectorColumnWidth(min: 300, ideal: 360, max: 460)
        }
    }
  }
}
