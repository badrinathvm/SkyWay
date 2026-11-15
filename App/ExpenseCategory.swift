import Foundation
import FoundationModels

/// What an expense was for, as an accountant would file it.
@Generable
enum ExpenseCategory: String, CaseIterable, Identifiable, Codable, Sendable {
  case meals
  case travel
  case lodging
  case fuel
  case office
  case software
  case equipment
  case other

  var id: Self { self }

  var title: String {
    switch self {
    case .meals: "Meals"
    case .travel: "Travel"
    case .lodging: "Lodging"
    case .fuel: "Fuel"
    case .office: "Office Supplies"
    case .software: "Software"
    case .equipment: "Equipment"
    case .other: "Other"
    }
  }

  var systemImage: String {
    switch self {
    case .meals: "fork.knife"
    case .travel: "airplane"
    case .lodging: "bed.double.fill"
    case .fuel: "fuelpump.fill"
    case .office: "paperclip"
    case .software: "app.badge"
    case .equipment: "desktopcomputer"
    case .other: "tag.fill"
    }
  }

  /// A best guess from words on the receipt, for when Apple Intelligence isn't available.
  static func guess(from text: String) -> ExpenseCategory {
    let text = text.lowercased()
    let keywords: [(ExpenseCategory, [String])] = [
      (.fuel, ["fuel", "gasoline", "unleaded", "diesel", "shell", "chevron", "exxon", "gallons"]),
      (.lodging, ["hotel", "inn", "suites", "resort", "lodging", "airbnb", "nightly"]),
      (.travel, ["airline", "airways", "flight", "uber", "lyft", "taxi", "parking", "toll", "rail"]),
      (.meals, ["restaurant", "cafe", "coffee", "grill", "kitchen", "pizza", "bar", "tip", "server", "table"]),
      (.software, ["subscription", "software", "license", "app store", "cloud"]),
      (.equipment, ["laptop", "monitor", "camera", "printer", "electronics", "best buy"]),
      (.office, ["staples", "office", "paper", "ink", "toner", "pens", "supplies"]),
    ]
    return keywords.first { $0.1.contains(where: text.contains) }?.0 ?? .other
  }
}
