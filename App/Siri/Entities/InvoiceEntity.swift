import AppIntents

/// Exposes an invoice to Siri and Shortcuts, so a created invoice can be passed to later steps.
struct InvoiceEntity: AppEntity {
  static let typeDisplayRepresentation: TypeDisplayRepresentation = "Invoice"
  static let defaultQuery = InvoiceEntityQuery()

  var id: String

  @Property(title: "Number")
  var number: String

  @Property(title: "Client")
  var clientName: String

  @Property(title: "Service")
  var service: String

  @Property(title: "Amount")
  var amount: Double

  @Property(title: "Issued")
  var createdAt: Date

  @Property(title: "Due Date")
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
