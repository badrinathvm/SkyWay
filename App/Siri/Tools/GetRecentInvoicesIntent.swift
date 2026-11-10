import AppIntents

/// Lists recent invoices so Siri can fill in vague requests like "bill John the usual".
struct GetRecentInvoicesIntent: AppIntent {
  static let title: LocalizedStringResource = "Get Recent Invoices"
  static let description = IntentDescription(
    "Lists your most recent Skyway invoices, newest first, with each one's number, client, service, amount, and the date it was issued. It doesn't create or change invoices.",
    searchKeywords: ["invoices", "past invoices", "billing history", "last invoice", "what did I bill", "clients"]
  )

  /// How many invoices to report, so the answer stays short enough to read out.
  static let resultLimit = 10

  init() {}

  func perform() async throws -> some IntentResult & ReturnsValue<[InvoiceEntity]> & ProvidesDialog {
    let invoices = Array(InvoiceStore.invoices.prefix(Self.resultLimit))
    guard !invoices.isEmpty else {
      return .result(value: [], dialog: "You haven't created any invoices in Skyway yet.")
    }
    let list = invoices.map {
      "\($0.number) for \($0.clientName), \($0.service.lowercased()), \($0.amountText), issued \($0.createdAt.formatted(date: .abbreviated, time: .omitted))"
    }
    return .result(
      value: invoices.map(\.entity),
      dialog: "Your recent invoices: \(list.formatted(.list(type: .and)))."
    )
  }
}

@available(iOS 27.3, *)
extension GetRecentInvoicesIntent: ToolIntent {}
