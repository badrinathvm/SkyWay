// xcode: set sdk=iOS

import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
  case home
  case bookFlight
  case travel
  case myTrips
  case flightStatus
  case search
  case settings

  var id: Self { self }

  var title: String {
    switch self {
    case .home: "Home"
    case .bookFlight: "Book flight"
    case .travel: "Travel"
    case .myTrips: "My trips"
    case .flightStatus: "Flight status"
    case .search: "Search"
    case .settings: "Settings"
    }
  }

  var systemImage: String {
    switch self {
    case .home: "house.fill"
    case .bookFlight: "airplane"
    case .travel: "suitcase.rolling.fill"
    case .myTrips: "ticket.fill"
    case .flightStatus: "clock.fill"
    case .search: "magnifyingglass"
    case .settings: "gear"
    }
  }
}
