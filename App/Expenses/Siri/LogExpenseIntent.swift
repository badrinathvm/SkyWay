import AppIntents

/// "Log a $42 lunch at Nopa in Skyway": saves an expense without a receipt.
struct LogExpenseIntent: AppIntent {
  static let title: LocalizedStringResource = "Log Expense"
  static let description = IntentDescription(
    "Saves a business expense in Skyway, like a $42 lunch at Nopa, for bookkeeping and tax deductions. Use this for a purchase the person already made and paid for. It doesn't bill a client or send money.",
    searchKeywords: ["expense", "receipt", "spent", "purchase", "paid", "bought", "business expense", "deduction", "reimbursement"]
  )

  @Parameter(
    title: "Supplier",
    description: "The business that was paid, like Nopa or United Airlines",
    requestValueDialog: "Where was the expense?"
  )
  var supplier: String

  @Parameter(
    title: "Amount",
    description: "The total paid, including tax and tip, as a number, like 42.50. In the currency named by the Currency parameter.",
    requestValueDialog: "How much was it?"
  )
  var amount: Double

  @Parameter(
    title: "Currency",
    description: "The three-letter ISO 4217 code of the currency paid in, like USD, EUR or GBP. Leave empty when the person doesn't name a currency, to use their local currency. Never convert the amount between currencies."
  )
  var currencyCode: String?

  @Parameter(
    title: "Category",
    description: "What the expense was for. Leave empty unless the person says, and Skyway files it the way they filed this supplier before."
  )
  var category: ExpenseCategory?

  @Parameter(
    title: "Purchase Date",
    description: "The day the purchase was made, in the person's time zone. Leave empty for today."
  )
  var date: Date?

  @Parameter(
    title: "Notes",
    description: "What the expense was for, in the person's words, like \"Client lunch with Maria\""
  )
  var notes: String?

  init() {}

  @MainActor
  func perform() async throws -> some IntentResult & ReturnsValue<ExpenseEntity> & ProvidesDialog {
    let supplier = supplier.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !supplier.isEmpty else {
      throw ExpenseIntentError.missingSupplier
    }
    guard amount > 0 else {
      throw ExpenseIntentError.invalidAmount
    }
    let code = currencyCode?.trimmingCharacters(in: .whitespaces).uppercased() ?? ""
    if !code.isEmpty, !Locale.commonISOCurrencyCodes.contains(code) {
      throw ExpenseIntentError.unknownCurrency(code)
    }
    let purchaseDate = date ?? .now
    guard purchaseDate <= .now.addingTimeInterval(86_400) else {
      throw ExpenseIntentError.futureDate
    }

    let expense = try ExpenseStore.logExpense(
      supplier: supplier,
      total: amount,
      currencyCode: code.isEmpty ? Expense.defaultCurrencyCode : code,
      category: category,
      date: purchaseDate,
      notes: notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    )
    let day = Calendar.current.isDateInToday(expense.date)
      ? "today"
      : "on \(expense.date.formatted(date: .abbreviated, time: .omitted))"
    return .result(
      value: expense.entity,
      dialog: "Logged \(expense.totalText) at \(expense.supplier) \(day), under \(expense.category.title)."
    )
  }
}

@available(iOS 27.3, *)
extension LogExpenseIntent: ToolIntent {}
