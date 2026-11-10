import AppIntents

/// Opens Skyway to an invoice's details, from the View Invoice button in Siri or from Shortcuts.
struct OpenInvoiceIntent: OpenIntent {
  static let title: LocalizedStringResource = "Open Invoice"
  static let description = IntentDescription("Opens Skyway and shows an invoice's details.")
  static var supportedModes: IntentModes { [.background, .foreground(.dynamic)] }

  @Parameter(title: "Invoice")
  var target: InvoiceEntity

  init() {}

  init(invoice: InvoiceEntity) {
    target = invoice
  }

  @MainActor
  func perform() async throws -> some IntentResult {
    guard let invoice = InvoiceStore.invoices(with: [target.id]).first else {
      throw InvoiceError.notFound
    }
    AppNavigator.shared.presentedInvoice = invoice
    // A button in a Siri card can start this in the background; bring Skyway forward to show the invoice.
    if systemContext.currentMode == .background, systemContext.currentMode.canContinueInForeground {
      try await continueInForeground(nil, alwaysConfirm: false)
    }
    return .result()
  }
}
