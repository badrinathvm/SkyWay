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

  /// Saves a new invoice with the next number.
  static func createInvoice(clientName: String, service: String, amount: Double) -> Invoice {
    let invoice = Invoice(number: nextNumber, clientName: clientName, service: service, amount: amount)
    UserDefaults.standard.set(UserDefaults.standard.integer(forKey: lastNumberKey) + 1, forKey: lastNumberKey)
    save([invoice] + invoices)
    return invoice
  }

  static func deleteInvoice(id: Invoice.ID) {
    save(invoices.filter { $0.id != id })
  }

  private static func save(_ invoices: [Invoice]) {
    guard let data = try? JSONEncoder().encode(invoices) else { return }
    UserDefaults.standard.set(data, forKey: storageKey)
  }
}
