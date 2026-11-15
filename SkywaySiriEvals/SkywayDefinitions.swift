import AppIntentsTesting

/// Skyway's intents and skills, looked up by name the same way Siri finds them.
enum SkywayDefinitions {
  static let app = IntentDefinitions(bundleIdentifier: "com.badarinathvm.skyway")

  // Seat selection
  static let changeSeat = app.intents["ChangeSeatIntent"]
  static let getAvailableSeats = app.intents["GetAvailableSeatsIntent"]
  static let getCurrentTrip = app.intents["GetCurrentTripIntent"]

  // Invoicing
  static let createInvoice = app.intents["CreateInvoiceIntent"]
  static let getRecentInvoices = app.intents["GetRecentInvoicesIntent"]
  static let invoice = app.entities["InvoiceEntity"]

  // Test setup, from the app's debug build
  static let resetDemoData = app.intents["ResetDemoDataIntent"]

  // App Skills in Skills.skillsbundle
  static let seatSelection = app.skills["seat-selection"]
  static let invoicing = app.skills["invoicing"]
}
