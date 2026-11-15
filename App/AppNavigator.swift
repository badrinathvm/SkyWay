import Foundation
import Observation

/// Screens that App Intents can ask the app to show, like an invoice opened from Siri.
@MainActor
@Observable
final class AppNavigator {
  static let shared = AppNavigator()

  /// The invoice shown in a sheet, or nil when none is open.
  var presentedInvoice: Invoice?

  /// Shows the screen a skyway:// link points to, like skyway://invoice/<id> from a Siri card.
  func open(_ url: URL) {
    guard url.scheme == "skyway", url.host() == "invoice",
      let id = url.pathComponents.dropFirst().first,
      let invoice = InvoiceStore.invoices(with: [id]).first
    else {
      return
    }
    presentedInvoice = invoice
  }
}
