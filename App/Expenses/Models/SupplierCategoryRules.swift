import Foundation

/// Remembers how the person files each supplier, like "Blue Bottle Coffee is Meals", and files
/// new expenses from that supplier the same way. A choice the person made beats a guess.
enum SupplierCategoryRules {
  private static let storageKey = "expenses.supplierCategories"

  /// The category the person last chose for this supplier, if they've ever chosen one.
  static func category(for supplier: String) -> ExpenseCategory? {
    let key = normalized(supplier)
    guard !key.isEmpty, let rawValue = rules[key] else { return nil }
    return ExpenseCategory(rawValue: rawValue)
  }

  /// Saves the person's choice, to apply to this supplier's future expenses.
  static func remember(_ category: ExpenseCategory, for supplier: String) {
    let key = normalized(supplier)
    guard !key.isEmpty else { return }
    var rules = rules
    rules[key] = category.rawValue
    UserDefaults.standard.set(rules, forKey: storageKey)
  }

  private static var rules: [String: String] {
    UserDefaults.standard.dictionary(forKey: storageKey) as? [String: String] ?? [:]
  }

  /// The supplier's name without case, punctuation, or store numbers, so "Blue Bottle Coffee #12"
  /// and "BLUE BOTTLE COFFEE" are the same supplier.
  static func normalized(_ supplier: String) -> String {
    String(supplier.lowercased().map { $0.isLetter ? $0 : " " })
      .split(separator: " ")
      .joined(separator: " ")
  }
}
