import AppIntents

/// Lists recent invoices so Siri can fill in vague requests like "bill John the usual".
struct GetRecentInvoicesIntent: AppIntent {
  static let title: LocalizedStringResource = "Get Recent Invoices"
  static let description = IntentDescription(
    "Lists your most recent Skyway invoices, newest first, with each one's number, client, service, amount, the date it was issued, its due date, and its payment status: draft, sent, overdue, or paid. It doesn't create or change invoices.",
    searchKeywords: ["invoices", "past invoices", "billing history", "last invoice", "what did I bill", "clients", "who owes me", "unpaid", "overdue", "outstanding"]
  )

  /// How many invoices to return, so the list stays short enough for Siri to read out.
  static let resultLimit = 10

  init() {}

  /// Returns the invoices without a spoken reply. A reply here becomes Siri's whole answer, which
  /// stops Siri from going on to use them, like billing "the usual" or asking which John.
  func perform() async throws -> some IntentResult & ReturnsValue<[InvoiceEntity]> {
    .result(value: InvoiceStore.invoices.prefix(Self.resultLimit).map(\.entity))
  }
}

@available(iOS 27.3, *)
extension GetRecentInvoicesIntent: ToolIntent {}
