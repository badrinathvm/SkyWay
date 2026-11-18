import AppIntents

/// Exposes an invoice to Siri and Shortcuts, so a created invoice can be passed to later steps.
struct InvoiceEntity: AppEntity {
  static let typeDisplayRepresentation: TypeDisplayRepresentation = "Invoice"
  static let defaultQuery = InvoiceEntityQuery()

  /// Property titles carry their meaning, because `@Property(description:)` needs iOS 27.3 and
  /// this entity also ships on 27.0. Siri reads them to answer follow-ups about invoices it listed.
  var id: String

  @Property(title: "Invoice Number (like INV-0002)")
  var number: String

  @Property(title: "Client Billed")
  var clientName: String

  @Property(title: "Service Billed For")
  var service: String

  @Property(title: "Amount Owed (US Dollars)")
  var amount: Double

  @Property(title: "Date Issued")
  var createdAt: Date

  @Property(title: "Payment Due Date")
  var dueDate: Date

  @Property(title: "Payment Status")
  var paymentState: Invoice.PaymentState

  init(invoice: Invoice) {
    id = invoice.id
    number = invoice.number
    clientName = invoice.clientName
    service = invoice.service
    amount = invoice.amount
    createdAt = invoice.createdAt
    dueDate = invoice.dueDate
    paymentState = invoice.paymentState()
  }

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(
      title: "\(number) · \(clientName)",
      subtitle: "\(service) · \(Invoice.format(amount)) · \(paymentState == .sent ? "Due \(dueDate.formatted(date: .abbreviated, time: .omitted))" : paymentState.title)",
      image: .init(systemName: "doc.text")
    )
  }
}

extension Invoice {
  var entity: InvoiceEntity { InvoiceEntity(invoice: self) }
}

/// Enumerable, since a person's invoices are a short list: Siri can look through all of them to
/// find the one a request means, like "Acme's invoice".
struct InvoiceEntityQuery: EnumerableEntityQuery {
  func allEntities() async throws -> [InvoiceEntity] {
    InvoiceStore.invoices.map(\.entity)
  }

  func entities(for identifiers: [InvoiceEntity.ID]) async throws -> [InvoiceEntity] {
    InvoiceStore.invoices(with: identifiers).map(\.entity)
  }

  func suggestedEntities() async throws -> [InvoiceEntity] {
    InvoiceStore.invoices.map(\.entity)
  }
}
