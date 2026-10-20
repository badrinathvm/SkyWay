import Foundation

struct TravelAction: Identifiable {
  var id: String { title }
  var title: String
  var subtitle: String
  var systemImage: String

  static let featured: [TravelAction] = [
    TravelAction(title: "Inflight menu", subtitle: "See what's on your flight", systemImage: "fork.knife"),
    TravelAction(title: "Upgrade your seat", subtitle: "Find more room on your flight", systemImage: "carseat.right.fill"),
    TravelAction(title: "View terminal guide", subtitle: "Get step-by-step directions around the airport.", systemImage: "mappin.and.ellipse"),
    TravelAction(title: "See check-in options", subtitle: "Edit your check-in selections", systemImage: "checkmark.seal.fill"),
    TravelAction(title: "Track your bags", subtitle: "See where your checked bags are", systemImage: "suitcase.fill"),
    TravelAction(title: "Wi-Fi & entertainment", subtitle: "Stay connected in the air", systemImage: "wifi"),
  ]

  static let quick: [TravelAction] = [
    TravelAction(title: "Change flight", subtitle: "", systemImage: "arrow.triangle.swap"),
    TravelAction(title: "Cancel trip", subtitle: "", systemImage: "xmark.circle"),
  ]
}
