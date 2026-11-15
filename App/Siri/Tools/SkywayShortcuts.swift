import AppIntents

struct SkywayShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: GetCurrentTripIntent(),
      phrases: [
        "Where am I travelling in \(.applicationName)",
        "Where am I traveling in \(.applicationName)",
        "Where is my trip in \(.applicationName)",
        "Where am I flying with \(.applicationName)",
        "Show my trip in \(.applicationName)",
        "\(.applicationName) trip",
      ],
      shortTitle: "Upcoming Trip",
      systemImageName: "airplane.departure"
    )
    AppShortcut(
      intent: ChangeSeatIntent(),
      phrases: [
        "Change my seat in \(.applicationName)",
        "Change seats in \(.applicationName)",
        "Pick a new seat in \(.applicationName)",
        "Move my seat in \(.applicationName)",
      ],
      shortTitle: "Change Seat",
      systemImageName: "carseat.left.fill"
    )
    AppShortcut(
      intent: CreateInvoiceIntent(),
      phrases: [
        "Create an invoice in \(.applicationName)",
        "Make an invoice in \(.applicationName)",
        "Bill a client in \(.applicationName)",
        "New \(.applicationName) invoice",
      ],
      shortTitle: "Create Invoice",
      systemImageName: "doc.text"
    )
    AppShortcut(
      intent: MarkInvoicePaidIntent(),
      phrases: [
        "Mark an invoice paid in \(.applicationName)",
        "Mark \(\.$invoice) paid in \(.applicationName)",
        "Record a payment in \(.applicationName)",
      ],
      shortTitle: "Mark Invoice Paid",
      systemImageName: "checkmark.circle"
    )
    AppShortcut(
      intent: LogExpenseIntent(),
      phrases: [
        "Log an expense in \(.applicationName)",
        "Add an expense in \(.applicationName)",
        "Log a receipt in \(.applicationName)",
        "New \(.applicationName) expense",
      ],
      shortTitle: "Log Expense",
      systemImageName: "receipt"
    )
    AppShortcut(
      intent: GetRecentExpensesIntent(),
      phrases: [
        "Show my expenses in \(.applicationName)",
        "What did I spend in \(.applicationName)",
        "My \(.applicationName) expenses",
      ],
      shortTitle: "Recent Expenses",
      systemImageName: "list.bullet.rectangle"
    )
    AppShortcut(
      intent: StartDriveTripIntent(),
      phrases: [
        "Start a trip in \(.applicationName)",
        "Start tracking miles in \(.applicationName)",
        "Start a drive in \(.applicationName)",
      ],
      shortTitle: "Start a Trip",
      systemImageName: "car.fill"
    )
    AppShortcut(
      intent: EndDriveTripIntent(),
      phrases: [
        "End my trip in \(.applicationName)",
        "End my \(\.$purpose) trip in \(.applicationName)",
        "Stop tracking miles in \(.applicationName)",
      ],
      shortTitle: "End Trip",
      systemImageName: "flag.checkered"
    )
  }
}
