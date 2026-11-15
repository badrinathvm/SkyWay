import Foundation

/// The person's invoices, saved across launches so ones created from Siri stick.
enum InvoiceStore {
  private static let storageKey = "invoices"
  private static let lastNumberKey = "invoices.lastNumber"

  /// Every invoice, newest first.
  static var invoices: [Invoice] {
    guard let data = UserDefaults.standard.data(forKey: storageKey),
      let invoices = try? JSONDecoder().decode([Invoice].self, from: data)
    else {
      return []
    }
    return invoices
  }

  static func invoices(with identifiers: [Invoice.ID]) -> [Invoice] {
    invoices.filter { identifiers.contains($0.id) }
  }

  /// The number the next invoice gets, like INV-0004. Numbers keep counting up after an undo.
  static var nextNumber: String {
    String(format: "INV-%04d", UserDefaults.standard.integer(forKey: lastNumberKey) + 1)
  }

  /// The full name of the one past client whose first name is `name`, like "Maria Garcia" for
  /// "Maria". Returns `name` unchanged if it's already a full name, or if no client or several match.
  static func fullClientName(for name: String) -> String {
    guard !name.contains(" ") else { return name }
    let matches = Set(invoices.map(\.clientName).filter {
      $0.split(separator: " ").first?.caseInsensitiveCompare(name) == .orderedSame
    })
    return matches.count == 1 ? matches.first! : name
  }

  /// Saves a new invoice with the next number.
  static func createInvoice(clientName: String, service: String, amount: Double) -> Invoice {
    let invoice = Invoice(number: nextNumber, clientName: clientName, service: service, amount: amount)
    UserDefaults.standard.set(UserDefaults.standard.integer(forKey: lastNumberKey) + 1, forKey: lastNumberKey)
    save([invoice] + invoices)
    return invoice
  }

  static func deleteInvoice(id: Invoice.ID) {
    save(invoices.filter { $0.id != id })
    InvoiceReminders.cancel(invoiceID: id)
  }

  /// Marks the invoice sent to the client, which starts its payment reminders.
  @discardableResult
  static func markSent(id: Invoice.ID) -> Invoice? {
    update(id: id) {
      $0.status = .sent
      $0.sentAt = .now
      $0.paidAt = nil
    }
  }

  /// Marks the invoice paid, which stops its reminders.
  @discardableResult
  static func markPaid(id: Invoice.ID, on date: Date = .now) -> Invoice? {
    update(id: id) {
      // A draft paid straight away was sent, in effect, at the same time. An invoice already
      // marked sent keeps its date, or none if it was sent before Skyway tracked it.
      if $0.status == .draft {
        $0.sentAt = date
      }
      $0.status = .paid
      $0.paidAt = date
    }
  }

  /// Undoes Mark as Paid, for a payment recorded by mistake or one that bounced.
  @discardableResult
  static func markUnpaid(id: Invoice.ID) -> Invoice? {
    update(id: id) {
      $0.status = .sent
      $0.paidAt = nil
    }
  }

  /// Changes one invoice, saves, and brings its reminders in line with its new status.
  private static func update(id: Invoice.ID, _ change: (inout Invoice) -> Void) -> Invoice? {
    var all = invoices
    guard let index = all.firstIndex(where: { $0.id == id }) else { return nil }
    change(&all[index])
    save(all)
    InvoiceReminders.update(for: all[index])
    return all[index]
  }

  /// Replaces every invoice, and continues numbering after the highest one given.
  static func replaceAll(with invoices: [Invoice]) {
    let lastNumber = invoices.compactMap { Int($0.number.dropFirst("INV-".count)) }.max() ?? 0
    UserDefaults.standard.set(lastNumber, forKey: lastNumberKey)
    save(invoices.sorted { $0.createdAt > $1.createdAt })
    InvoiceReminders.rescheduleAll(invoices)
  }

  private static func save(_ invoices: [Invoice]) {
    guard let data = try? JSONEncoder().encode(invoices) else { return }
    UserDefaults.standard.set(data, forKey: storageKey)
  }
}
