import AppIntents

/// Lists recent expenses so Siri can answer "What did I spend on meals this week?"
struct GetRecentExpensesIntent: AppIntent {
  static let title: LocalizedStringResource = "Get Recent Expenses"
  static let description = IntentDescription(
    "Lists the person's most recent Skyway expenses, newest purchase first, with each one's supplier, total, currency, tax, category and purchase date. Use it to answer questions about spending. It doesn't log, change or delete expenses.",
    searchKeywords: ["expenses", "spending", "spent", "receipts", "purchases", "how much did I spend", "this month"]
  )

  /// Enough for about a month of typical spending, while staying short enough for Siri to read.
  static let resultLimit = 50

  init() {}

  /// Returns the expenses without a spoken reply, so Siri can go on to answer the question,
  /// like adding up one category, rather than reading the whole list out.
  @MainActor
  func perform() async throws -> some IntentResult & ReturnsValue<[ExpenseEntity]> {
    .result(value: ExpenseStore.recentExpenses(limit: Self.resultLimit).map(\.entity))
  }
}

@available(iOS 27.3, *)
extension GetRecentExpensesIntent: ToolIntent {}
