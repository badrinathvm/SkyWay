import Foundation
import SwiftData

/// A business purchase backed by a receipt, like "Blue Bottle Coffee, $8.50, Meals".
@Model
final class Expense {
  var id: UUID
  var supplier: String
  var date: Date
  /// The amount paid, including tax, in `currencyCode`.
  var total: Double
  var tax: Double
  /// An ISO 4217 code, like "USD". Receipts can be in any currency, unlike invoices.
  var currencyCode: String
  /// `ExpenseCategory.rawValue`, stored as text so it can be used in fetch predicates.
  var categoryRawValue: String
  var notes: String
  /// The receipt's pages, saved by `ReceiptImageStore`. A long receipt can have several.
  var receiptFileNames: [String]
  /// The text read from the receipt, kept so the person can check what the app read.
  var recognizedText: String
  var createdAt: Date

  init(
    supplier: String = "",
    date: Date = .now,
    total: Double = 0,
    tax: Double = 0,
    currencyCode: String = Expense.defaultCurrencyCode,
    category: ExpenseCategory = .other,
    notes: String = "",
    receiptFileNames: [String] = [],
    recognizedText: String = ""
  ) {
    id = UUID()
    self.supplier = supplier
    self.date = date
    self.total = total
    self.tax = tax
    self.currencyCode = currencyCode
    categoryRawValue = category.rawValue
    self.notes = notes
    self.receiptFileNames = receiptFileNames
    self.recognizedText = recognizedText
    createdAt = .now
  }

  var category: ExpenseCategory {
    get { ExpenseCategory(rawValue: categoryRawValue) ?? .other }
    set { categoryRawValue = newValue.rawValue }
  }

  var totalText: String {
    total.formatted(.currency(code: currencyCode))
  }

  /// The name to show, even before the person types a supplier.
  var displayName: String {
    supplier.isEmpty ? "New Expense" : supplier
  }

  /// True for an expense entered by hand and left without any details.
  var isBlank: Bool {
    supplier.isEmpty && total == 0 && receiptFileNames.isEmpty && notes.isEmpty
  }

  static var defaultCurrencyCode: String {
    Locale.current.currency?.identifier ?? "USD"
  }

  /// The month's spending per currency, largest first, like ["$412.80", "€36.00"].
  static func monthlyTotals(of expenses: [Expense], containing date: Date = .now) -> [String] {
    let calendar = Calendar.current
    let totals = expenses
      .filter { calendar.isDate($0.date, equalTo: date, toGranularity: .month) }
      .reduce(into: [String: Double]()) { $0[$1.currencyCode, default: 0] += $1.total }
    return totals
      .sorted { $0.value > $1.value }
      .map { $0.value.formatted(.currency(code: $0.key)) }
  }
}
