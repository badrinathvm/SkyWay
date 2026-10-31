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
