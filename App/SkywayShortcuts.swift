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
  }
}
