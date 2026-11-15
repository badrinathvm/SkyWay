import Foundation

/// One month of bookkeeping: what was spent, what was invoiced, and the business miles driven.
/// A value snapshot, so it can be exported off the main actor.
struct MonthlyReport: Sendable {
  /// An expense as it appears in the report.
  struct ExpenseLine: Identifiable, Sendable {
    var id: UUID
    var date: Date
    var supplier: String
    var category: ExpenseCategory
    var total: Double
    var tax: Double
    var currencyCode: String
    var notes: String
  }

  /// An amount in one currency. Amounts in different currencies are never added together.
  struct CurrencyAmount: Identifiable, Sendable {
    var currencyCode: String
    var amount: Double
    var id: String { currencyCode }
    var text: String { amount.formatted(.currency(code: currencyCode)) }
  }

  struct CategoryTotal: Identifiable, Sendable {
    var category: ExpenseCategory
    var amounts: [CurrencyAmount]
    var id: ExpenseCategory { category }
  }

  /// The first instant of the month up to the first instant of the next.
  var month: DateInterval
  /// Oldest first, as a bookkeeper reads them.
  var expenses: [ExpenseLine]
  var businessTrips: [DriveTrip]
  /// Trips in the month not yet marked business or personal, which can't count yet.
  var unclassifiedTripCount: Int
  var invoices: [Invoice]

  init(month date: Date, expenses: [Expense], trips: [DriveTrip], invoices: [Invoice]) {
    month = Self.interval(containing: date)
    let month = month
    self.expenses = expenses
      .filter { month.contains($0.date) }
      .sorted { $0.date < $1.date }
      .map {
        ExpenseLine(
          id: $0.id, date: $0.date, supplier: $0.displayName, category: $0.category,
          total: $0.total, tax: $0.tax, currencyCode: $0.currencyCode, notes: $0.notes
        )
      }
    let monthTrips = trips.filter { $0.endDate != nil && month.contains($0.startDate) }
    businessTrips = monthTrips.filter { $0.purpose == .business }.sorted { $0.startDate < $1.startDate }
    unclassifiedTripCount = monthTrips.filter { $0.purpose == nil }.count
    self.invoices = invoices.filter { month.contains($0.createdAt) }.sorted { $0.createdAt < $1.createdAt }
  }

  static func interval(containing date: Date) -> DateInterval {
    Calendar.current.dateInterval(of: .month, for: date) ?? DateInterval(start: date, duration: 0)
  }

  /// "November 2026".
  var title: String {
    month.start.formatted(.dateTime.month(.wide).year())
  }

  var isEmpty: Bool {
    expenses.isEmpty && businessTrips.isEmpty && invoices.isEmpty
  }

  // MARK: - Totals

  /// Spending per currency, largest first.
  var expenseTotals: [CurrencyAmount] { Self.totals(expenses, \.total) }

  /// Tax included in the spending, per currency.
  var taxTotals: [CurrencyAmount] { Self.totals(expenses.filter { $0.tax > 0 }, \.tax) }

  /// Spending per category, largest first.
  var categoryTotals: [CategoryTotal] {
    Dictionary(grouping: expenses, by: \.category)
      .map { CategoryTotal(category: $0.key, amounts: Self.totals($0.value, \.total)) }
      .sorted { ($0.amounts.first?.amount ?? 0) > ($1.amounts.first?.amount ?? 0) }
  }

  var businessMiles: Double {
    businessTrips.reduce(0) { $0 + $1.miles }
  }

  /// In US dollars, at the IRS rate on each trip's date (`MileageRate`).
  var mileageDeduction: Double {
    businessTrips.reduce(0) { $0 + $1.deduction }
  }

  /// In US dollars, since invoices are only in dollars.
  var invoicedTotal: Double {
    invoices.reduce(0) { $0 + $1.amount }
  }

  /// "$84.20 and €12.00", or "$0.00" when nothing was spent.
  static func text(for amounts: [CurrencyAmount]) -> String {
    amounts.isEmpty
      ? 0.formatted(.currency(code: Expense.defaultCurrencyCode))
      : amounts.map(\.text).formatted(.list(type: .and))
  }

  static func usd(_ amount: Double) -> String {
    amount.formatted(.currency(code: "USD"))
  }

  private static func totals(_ lines: [ExpenseLine], _ amount: KeyPath<ExpenseLine, Double>) -> [CurrencyAmount] {
    lines
      .reduce(into: [String: Double]()) { $0[$1.currencyCode, default: 0] += $1[keyPath: amount] }
      .map { CurrencyAmount(currencyCode: $0.key, amount: $0.value) }
      .sorted { $0.amount > $1.amount }
  }
}
