import AppIntents

/// "Create an invoice for John, gardening, 450": shows a draft invoice in Siri, then saves it once confirmed.
struct CreateInvoiceIntent: AppIntent {
  static let title: LocalizedStringResource = "Create Invoice"
  static let description = IntentDescription(
    "Creates an invoice in US dollars that bills a client for a service, after you confirm. It's due in 14 days.",
    searchKeywords: ["invoice", "bill", "charge", "billing", "client", "payment request"]
  )

  @Parameter(
    title: "Client",
    description: "The name of the person or business being billed, like John",
    requestValueDialog: "Who's the invoice for?"
  )
  var clientName: String

  @Parameter(
    title: "Service",
    description: "The work being billed, like gardening",
    requestValueDialog: "What's the invoice for?"
  )
  var service: String

  @Parameter(
    title: "Amount",
    description: "The total to bill, in US dollars, like 450",
    requestValueDialog: "How much should I bill?"
  )
  var amount: Double

  init() {}

  init(clientName: String, service: String, amount: Double) {
    self.clientName = clientName
    self.service = service
    self.amount = amount
  }

  func perform() async throws -> some IntentResult & ReturnsValue<InvoiceEntity> & ProvidesDialog & ShowsSnippetIntent {
    let client = clientName.trimmingCharacters(in: .whitespacesAndNewlines)
    let work = service.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !client.isEmpty else {
      throw InvoiceError.missingClient
    }
    guard !work.isEmpty else {
      throw InvoiceError.missingService
    }
    guard amount > 0 else {
      throw InvoiceError.invalidAmount
    }

    try await requestConfirmation(
      actionName: .custom(
        acceptLabel: "Create Invoice",
        acceptAlternatives: ["Yes", "Create it", "Send it"],
        denyLabel: "Cancel",
        denyAlternatives: ["No", "Don't create it"],
        destructive: false
      ),
      dialog: "Create an invoice for \(client) for \(Invoice.format(amount)) for \(work.lowercased())?",
      snippetIntent: InvoiceDraftSnippetIntent(clientName: client, service: work, amount: amount)
    )

    let invoice = InvoiceStore.createInvoice(clientName: client, service: work, amount: amount)
    let due = invoice.dueDate.formatted(date: .abbreviated, time: .omitted)
    return .result(
      value: invoice.entity,
      dialog: "Created invoice \(invoice.number) for \(client): \(invoice.amountText) for \(work.lowercased()), due \(due).",
      snippetIntent: InvoiceCreatedSnippetIntent(invoice: invoice)
    )
  }
}

@available(iOS 27.3, *)
extension CreateInvoiceIntent: ToolIntent {}

enum InvoiceError: Error, CustomLocalizedStringResourceConvertible {
  case missingClient
  case missingService
  case invalidAmount
  case notFound

  var localizedStringResource: LocalizedStringResource {
    switch self {
    case .missingClient: "An invoice needs a client name, like John."
    case .missingService: "An invoice needs a service to bill for, like gardening."
    case .invalidAmount: "The amount needs to be more than $0, like 450."
    case .notFound: "That invoice isn't in Skyway anymore."
    }
  }
}
