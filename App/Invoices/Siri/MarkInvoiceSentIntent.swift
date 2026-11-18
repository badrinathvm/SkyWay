import AppIntents

/// "I sent Maria's invoice": records that a draft went to the client, which starts its payment reminders.
struct MarkInvoiceSentIntent: AppIntent {
  static let title: LocalizedStringResource = "Record Invoice as Sent"
  static let description = IntentDescription(
    "Updates a Skyway invoice's payment status from draft to sent, after the person has already shared it with their client themselves, so Skyway reminds them on its due date if it's still unpaid. It doesn't send, email or share the invoice; Skyway has no way to send invoices.",
    searchKeywords: ["already sent", "I sent it", "I emailed it", "mark sent", "gave invoice to client", "invoice status"]
  )

  @Parameter(
    title: "Invoice",
    description: "The draft invoice the person sent, found by its client or number",
    requestValueDialog: "Which invoice did you send?"
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
    switch current.status {
    case .paid:
      return .result(value: current.entity, dialog: "\(current.number) for \(current.clientName) is already paid.")
    case .sent:
      return .result(value: current.entity, dialog: "\(current.number) for \(current.clientName) is already marked sent.")
    case .draft:
      guard let sent = InvoiceStore.markSent(id: current.id) else {
        throw InvoiceError.notFound
      }
      let due = sent.dueDate.formatted(date: .abbreviated, time: .omitted)
      return .result(
        value: sent.entity,
        dialog: "Marked \(sent.number) for \(sent.clientName) as sent. It's due \(due)."
      )
    }
  }
}

@available(iOS 27.3, *)
extension MarkInvoiceSentIntent: ToolIntent {}
