import Foundation

struct TravelAction: Identifiable, Hashable {
  /// Stable across launches so Siri and Apple Intelligence can look the action up by identifier.
  var id: String
  var title: String
  var subtitle: String
  var systemImage: String
  /// A question to suggest when this action is shared with the assistant.
  var question: String

  static let featured: [TravelAction] = [
    TravelAction(id: "inflight-menu", title: "Inflight menu", subtitle: "See what's on your flight", systemImage: "fork.knife", question: "What's on the inflight menu?"),
    TravelAction(id: "upgrade-seat", title: "Upgrade your seat", subtitle: "Find more room on your flight", systemImage: "carseat.right.fill", question: "Can I upgrade my seat?"),
    TravelAction(id: "terminal-guide", title: "View terminal guide", subtitle: "Get step-by-step directions around the airport.", systemImage: "mappin.and.ellipse", question: "How do I get to my gate?"),
    TravelAction(id: "check-in-options", title: "See check-in options", subtitle: "Edit your check-in selections", systemImage: "checkmark.seal.fill", question: "Am I checked in?"),
    TravelAction(id: "track-bags", title: "Track your bags", subtitle: "See where your checked bags are", systemImage: "suitcase.fill", question: "Where are my bags?"),
    TravelAction(id: "wifi-entertainment", title: "Wi-Fi & entertainment", subtitle: "Stay connected in the air", systemImage: "wifi", question: "Is there Wi-Fi on board?"),
  ]

  static let quick: [TravelAction] = [
    TravelAction(id: "change-flight", title: "Change flight", subtitle: "", systemImage: "arrow.triangle.swap", question: "Can I change my flight?"),
    TravelAction(id: "cancel-trip", title: "Cancel trip", subtitle: "", systemImage: "xmark.circle", question: "Can I cancel my trip?"),
  ]

  static let all = featured + quick
}

extension TravelAction {
  var contextItem: ContextItem {
    ContextItem(
      id: id,
      title: title,
      detail: subtitle.isEmpty ? title : "\(title): \(subtitle)",
      systemImage: systemImage,
      suggestion: question,
      // Leave destructive actions out unless the person picks them.
      isSelectedByDefault: id != "cancel-trip",
      sortOrder: 2 + (TravelAction.all.firstIndex(of: self) ?? 0)
    )
  }
}
