#if DEBUG
import AppIntents
import Foundation

/// Puts the app in a known state before each Siri evaluation scenario: three seeded invoices, and
/// the upcoming trip back in its original seat. Debug builds only, and hidden from Siri and Shortcuts.
struct ResetDemoDataIntent: AppIntent {
  static let title: LocalizedStringResource = "Reset Demo Data"
  static let isDiscoverable = false

  func perform() async throws -> some IntentResult {
    let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
    let monthAgo = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
    InvoiceStore.replaceAll(with: [
      Invoice(number: "INV-0001", clientName: "John Appleseed", service: "Gardening", amount: 450, createdAt: weekAgo),
      Invoice(number: "INV-0002", clientName: "Maria Garcia", service: "Dog walking", amount: 40, createdAt: weekAgo),
      // A second John, so "bill John" is ambiguous.
      Invoice(number: "INV-0003", clientName: "John Rivera", service: "Pool cleaning", amount: 120, createdAt: monthAgo),
    ])

    UserDefaults.standard.removeObject(forKey: SeatAssignments.storageKey(for: Trip.sample.confirmationCode))
    await TripStore.indexInSpotlight()
    return .result()
  }
}
#endif
