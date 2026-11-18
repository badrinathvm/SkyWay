import AppIntents

/// "Undo that" or "Delete Maria's invoice": the spoken version of the Undo button on the
/// created-invoice card, for when there's no card to tap, like on AirPods or in CarPlay.
///
/// Separate from `DeleteInvoiceIntent`, which backs that button: a tap is already a deliberate
/// undo, so it deletes straight away, while a spoken request confirms first.
struct DiscardInvoiceIntent: AppIntent {
  static let title: LocalizedStringResource = "Delete Invoice"
  static let description = IntentDescription(
    "Permanently deletes a Skyway invoice after the person confirms, for one created by mistake or that they want to undo. It doesn't tell the client anything. To record that a client paid, use Mark Invoice Paid instead.",
    searchKeywords: ["undo", "undo invoice", "cancel invoice", "remove invoice", "void", "made a mistake", "scrap"]
  )

  @Parameter(
    title: "Invoice",
    description: "The invoice to delete, found by its client or number, or the one just created",
    requestValueDialog: "Which invoice should I delete?"
  )
  var invoice: InvoiceEntity

  init() {}

  init(invoice: InvoiceEntity) {
    self.invoice = invoice
  }

  func perform() async throws -> some IntentResult & ProvidesDialog {
    guard let current = InvoiceStore.invoices(with: [invoice.id]).first else {
      throw InvoiceError.notFound
    }

    try await requestConfirmation(
      actionName: .custom(
        acceptLabel: "Delete Invoice",
        acceptAlternatives: ["Yes", "Delete it", "Undo it"],
        denyLabel: "Keep It",
        denyAlternatives: ["No", "Cancel", "Keep it"],
        destructive: true
      ),
      dialog: confirmationDialog(for: current)
    )

    InvoiceStore.deleteInvoice(id: current.id)
    return .result(dialog: "Deleted \(current.number) for \(current.clientName).")
  }

  private func confirmationDialog(for invoice: Invoice) -> IntentDialog {
    let summary = "\(invoice.number) for \(invoice.clientName), \(invoice.amountText) for \(invoice.service.lowercased())"
    switch invoice.status {
    case .paid:
      return "\(summary) is marked paid. Delete it anyway?"
    case .sent:
      return "You've already sent \(summary). Delete it anyway?"
    case .draft:
      return "Delete \(summary)?"
    }
  }
}

@available(iOS 27.3, *)
extension DiscardInvoiceIntent: ToolIntent {}
