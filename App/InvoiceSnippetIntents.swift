import AppIntents
import SwiftUI

/// The draft invoice Siri shows while asking the person to confirm. Only reads state.
struct InvoiceDraftSnippetIntent: SnippetIntent {
  static let title: LocalizedStringResource = "Invoice Draft"
  static let isDiscoverable = false

  @Parameter(title: "Client")
  var clientName: String

  @Parameter(title: "Service")
  var service: String

  @Parameter(title: "Amount")
  var amount: Double

  init() {}

  init(clientName: String, service: String, amount: Double) {
    self.clientName = clientName
    self.service = service
    self.amount = amount
  }

  func perform() async throws -> some IntentResult & ShowsSnippetView {
    .result(
      view: InvoiceCard(
        number: InvoiceStore.nextNumber,
        clientName: clientName,
        service: service,
        amount: amount,
        dueDate: Invoice.dueDate(from: .now),
        status: .draft
      )
    )
  }
}

/// The card Siri shows after the invoice is saved, with an Undo button. Only reads state.
///
/// Takes plain values rather than an `InvoiceEntity`, so it can still draw after Undo deletes the invoice.
struct InvoiceCreatedSnippetIntent: SnippetIntent {
  static let title: LocalizedStringResource = "Invoice Created"
  static let isDiscoverable = false

  @Parameter(title: "Invoice ID")
  var invoiceID: String

  @Parameter(title: "Number")
  var number: String

  @Parameter(title: "Client")
  var clientName: String

  @Parameter(title: "Service")
  var service: String

  @Parameter(title: "Amount")
  var amount: Double

  @Parameter(title: "Due Date")
  var dueDate: Date

  init() {}

  init(invoice: Invoice) {
    invoiceID = invoice.id
    number = invoice.number
    clientName = invoice.clientName
    service = invoice.service
    amount = invoice.amount
    dueDate = invoice.dueDate
  }

  func perform() async throws -> some IntentResult & ShowsSnippetView {
    let exists = !InvoiceStore.invoices(with: [invoiceID]).isEmpty
    return .result(
      view: InvoiceCard(
        number: number,
        clientName: clientName,
        service: service,
        amount: amount,
        dueDate: dueDate,
        status: exists ? .created(invoiceID: invoiceID) : .deleted
      )
    )
  }
}

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
