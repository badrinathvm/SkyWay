import Foundation

/// An invoice billed to a client for one service, like "Gardening for John, $450".
struct Invoice: Identifiable, Hashable, Codable, Sendable {
  /// Created once and saved, so Siri and Shortcuts can find the invoice again.
  var id: String
  var number: String
  var clientName: String
  var service: String
  /// In US dollars.
  var amount: Double
  var createdAt: Date
  var dueDate: Date

  /// Invoices are due two weeks after they're created.
  static let paymentTermDays = 14

  init(number: String, clientName: String, service: String, amount: Double, createdAt: Date = .now) {
    id = UUID().uuidString
    self.number = number
    self.clientName = clientName
    self.service = service
    self.amount = amount
    self.createdAt = createdAt
    dueDate = Self.dueDate(from: createdAt)
  }

  static func dueDate(from date: Date) -> Date {
    Calendar.current.date(byAdding: .day, value: paymentTermDays, to: date) ?? date
  }

  var amountText: String { Self.format(amount) }

  static func format(_ amount: Double) -> String {
    amount.formatted(.currency(code: "USD"))
  }
}
