import AppIntents

/// "Acme paid me" or "Mark INV-0002 as paid": records a client's payment.
struct MarkInvoicePaidIntent: AppIntent {
  static let title: LocalizedStringResource = "Mark Invoice Paid"
  static let description = IntentDescription(
    "Records that a client paid a Skyway invoice in full, which stops its payment reminders. Use it when the person says a client paid them. It doesn't send or receive money.",
    searchKeywords: ["paid", "payment received", "got paid", "settled", "client paid", "mark paid"]
  )

  @Parameter(
    title: "Invoice",
    description: "The unpaid invoice the client paid, found by its client or number",
    requestValueDialog: "Which invoice was paid?"
  )
  var invoice: InvoiceEntity

  init() {}

  init(invoice: InvoiceEntity) {
    self.invoice = invoice
  }

  func perform() async throws -> some IntentResult & ReturnsValue<InvoiceEntity> & ProvidesDialog {
    guard let current = InvoiceStore.invoices(with: [invoice.id]).first else {
      throw InvoiceError.notFound
    }
    guard current.status != .paid else {
      return .result(value: current.entity, dialog: "\(current.number) for \(current.clientName) is already marked paid.")
    }
    guard let paid = InvoiceStore.markPaid(id: current.id) else {
      throw InvoiceError.notFound
    }
    return .result(
      value: paid.entity,
      dialog: "Marked \(paid.number) for \(paid.clientName), \(paid.amountText), as paid."
    )
  }
}

@available(iOS 27.3, *)
extension MarkInvoicePaidIntent: ToolIntent {}
