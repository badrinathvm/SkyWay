import Foundation

struct TravelAction: Identifiable, Hashable {
  /// Stable across launches so Siri and Apple Intelligence can look the action up by identifier.
  var id: String
  var title: String
  var subtitle: String
  var systemImage: String

  static let featured: [TravelAction] = [
    TravelAction(id: "inflight-menu", title: "Inflight menu", subtitle: "See what's on your flight", systemImage: "fork.knife"),
    TravelAction(id: "upgrade-seat", title: "Upgrade your seat", subtitle: "Find more room on your flight", systemImage: "carseat.right.fill"),
    TravelAction(id: "terminal-guide", title: "View terminal guide", subtitle: "Get step-by-step directions around the airport.", systemImage: "mappin.and.ellipse"),
    TravelAction(id: "check-in-options", title: "See check-in options", subtitle: "Edit your check-in selections", systemImage: "checkmark.seal.fill"),
    TravelAction(id: "track-bags", title: "Track your bags", subtitle: "See where your checked bags are", systemImage: "suitcase.fill"),
    TravelAction(id: "wifi-entertainment", title: "Wi-Fi & entertainment", subtitle: "Stay connected in the air", systemImage: "wifi"),
  ]

  static let quick: [TravelAction] = [
    TravelAction(id: "change-flight", title: "Change flight", subtitle: "", systemImage: "arrow.triangle.swap"),
    TravelAction(id: "cancel-trip", title: "Cancel trip", subtitle: "", systemImage: "xmark.circle"),
  ]

  static let all = featured + quick
}
