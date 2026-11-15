import AppIntents

/// Runs when the person taps Undo on the created invoice. Siri then redraws the card.
struct DeleteInvoiceIntent: AppIntent {
  static let title: LocalizedStringResource = "Delete Invoice"
  static let isDiscoverable = false

  @Parameter(title: "Invoice ID")
  var invoiceID: String

  init() {}

  init(invoiceID: String) {
    self.invoiceID = invoiceID
  }

  func perform() async throws -> some IntentResult {
    guard !InvoiceStore.invoices(with: [invoiceID]).isEmpty else {
      throw InvoiceError.notFound
    }
    InvoiceStore.deleteInvoice(id: invoiceID)
    return .result()
  }
}
