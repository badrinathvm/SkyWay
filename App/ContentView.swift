import SwiftUI

struct ContentView: View {
  @State private var selectedTab: AppTab = .travel
  @State private var isShowingBoardingPass = false
  @State private var assistant = FlightAssistant(trip: .sample)
  private let trip = Trip.sample

  var body: some View {
    TabView(selection: $selectedTab) {
      Tab(AppTab.home.title, systemImage: AppTab.home.systemImage, value: AppTab.home) {
        PlaceholderTabView(tab: .home)
      }
//      Tab(AppTab.bookFlight.title, systemImage: AppTab.bookFlight.systemImage, value: AppTab.bookFlight) {
//        PlaceholderTabView(tab: .bookFlight)
//      }
      Tab(AppTab.travel.title, systemImage: AppTab.travel.systemImage, value: AppTab.travel) {
        TravelView(trip: trip, assistant: assistant)
      }
//      Tab(AppTab.myTrips.title, systemImage: AppTab.myTrips.systemImage, value: AppTab.myTrips) {
//        PlaceholderTabView(tab: .myTrips)
//      }
      Tab(AppTab.flightStatus.title, systemImage: AppTab.flightStatus.systemImage, value: AppTab.flightStatus) {
        FlightStatusView(assistant: assistant)
      }
      Tab(AppTab.settings.title, systemImage: AppTab.settings.systemImage, value: AppTab.settings, role: .prominent) {
        SearchView(trip: trip)
      }
    }
    .tabBarMinimizeBehavior(.onScrollDown)
    .tabViewBottomAccessory(isEnabled: hasAccessory) {
      switch selectedTab {
      case .flightStatus:
         BoardingPassAccessory(trip: trip) {
             isShowingBoardingPass = true
           }
      default:
         MessageComposerAccessory(assistant: assistant)
      }
    }
    // Above the content and the tab bar, so the lens can travel from the assistant bar to any item.
    .overlay {
      if selectedTab == .travel {
        ContextLens(context: assistant.screenContext)
      }
    }
    .sheet(isPresented: $isShowingBoardingPass) {
      BoardingPassView(trip: trip)
    }
  }

  private var hasAccessory: Bool {
    switch selectedTab {
    case .travel: !assistant.isComposing
    case .flightStatus: true
    default: false
    }
  }
}
