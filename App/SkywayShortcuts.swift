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
  }
}
