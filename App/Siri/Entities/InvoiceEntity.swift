import AppIntents

/// Exposes an invoice to Siri and Shortcuts, so a created invoice can be passed to later steps.
struct InvoiceEntity: AppEntity {
  static let typeDisplayRepresentation: TypeDisplayRepresentation = "Invoice"
  static let defaultQuery = InvoiceEntityQuery()

  var id: String

  @Property(title: "Number", description: "The invoice number, like INV-0001")
  var number: String

  @Property(title: "Client", description: "The full name of the person or business billed")
  var clientName: String

  @Property(title: "Service", description: "The work billed, like gardening")
  var service: String

  @Property(title: "Amount", description: "The total billed, in US dollars")
  var amount: Double

  @Property(title: "Issued", description: "The date the invoice was created")
  var createdAt: Date

  @Property(title: "Due Date", description: "The date payment is due, 14 days after it was issued")
  var dueDate: Date

  init(invoice: Invoice) {
    id = invoice.id
    number = invoice.number
    clientName = invoice.clientName
    service = invoice.service
    amount = invoice.amount
    createdAt = invoice.createdAt
    dueDate = invoice.dueDate
  }

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(
      title: "\(number) · \(clientName)",
      subtitle: "\(service) · \(Invoice.format(amount)) · Due \(dueDate.formatted(date: .abbreviated, time: .omitted))",
      image: .init(systemName: "doc.text")
    )
  }
}

extension Invoice {
  var entity: InvoiceEntity { InvoiceEntity(invoice: self) }
}

struct InvoiceEntityQuery: EntityQuery {
  func entities(for identifiers: [InvoiceEntity.ID]) async throws -> [InvoiceEntity] {
    InvoiceStore.invoices(with: identifiers).map(\.entity)
  }

  func suggestedEntities() async throws -> [InvoiceEntity] {
    InvoiceStore.invoices.map(\.entity)
  }
}
