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
  /// Where the invoice is in being billed. Whether it's overdue is worked out from this and
  /// the due date, in `paymentState`.
  var status: Status
  /// When the person marked it sent to the client.
  var sentAt: Date?
  /// When the person marked it paid.
  var paidAt: Date?

  /// The steps the person moves an invoice through.
  enum Status: String, Codable, Sendable {
    /// Created, but not sent to the client yet.
    case draft
    /// Sent to the client and waiting for payment.
    case sent
    case paid
  }

  /// Invoices are due two weeks after they're created.
  static let paymentTermDays = 14

  init(
    number: String,
    clientName: String,
    service: String,
    amount: Double,
    createdAt: Date = .now,
    status: Status = .draft
  ) {
    id = UUID().uuidString
    self.number = number
    self.clientName = clientName
    self.service = service
    self.amount = amount
    self.createdAt = createdAt
    dueDate = Self.dueDate(from: createdAt)
    self.status = status
  }

  private enum CodingKeys: String, CodingKey {
    case id, number, clientName, service, amount, createdAt, dueDate, status, sentAt, paidAt
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    number = try container.decode(String.self, forKey: .number)
    clientName = try container.decode(String.self, forKey: .clientName)
    service = try container.decode(String.self, forKey: .service)
    amount = try container.decode(Double.self, forKey: .amount)
    createdAt = try container.decode(Date.self, forKey: .createdAt)
    dueDate = try container.decode(Date.self, forKey: .dueDate)
    // Invoices saved before statuses existed had already gone out, so they count as sent.
    status = try container.decodeIfPresent(Status.self, forKey: .status) ?? .sent
    sentAt = try container.decodeIfPresent(Date.self, forKey: .sentAt)
    paidAt = try container.decodeIfPresent(Date.self, forKey: .paidAt)
  }

  /// Draft, sent, overdue or paid, for showing the person where the invoice stands.
  func paymentState(now: Date = .now) -> PaymentState {
    switch status {
    case .draft: .draft
    case .paid: .paid
    case .sent: isPastDue(now: now) ? .overdue : .sent
    }
  }

  /// True once the due date has gone by: an invoice due today isn't late until tomorrow.
  func isPastDue(now: Date = .now) -> Bool {
    Calendar.current.startOfDay(for: now) > Calendar.current.startOfDay(for: dueDate)
  }

  /// Still owed by the client: sent or overdue, not a draft and not paid.
  var isOutstanding: Bool { status == .sent }

  static func dueDate(from date: Date) -> Date {
    Calendar.current.date(byAdding: .day, value: paymentTermDays, to: date) ?? date
  }

  var amountText: String { Self.format(amount) }

  /// Opens the invoice in Skyway, like skyway://invoice/<id>.
  var url: URL {
    URL(string: "skyway://invoice/\(id)")!
  }

  static func format(_ amount: Double) -> String {
    amount.formatted(.currency(code: "USD"))
  }
}
