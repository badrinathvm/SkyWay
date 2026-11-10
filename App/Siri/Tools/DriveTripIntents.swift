import AppIntents

/// Starts tracking a drive hands-free: "Start a trip in Skyway".
struct StartDriveTripIntent: AppIntent {
  static let title: LocalizedStringResource = "Start a Trip"
  static let description = IntentDescription("Starts tracking the miles you drive from where you are now.")

  @MainActor
  func perform() async throws -> some IntentResult & ProvidesDialog {
    let store = DriveTripStore.shared
    guard store.activeTrip == nil else {
      return .result(dialog: "You already have a trip in progress.")
    }
    store.startTrip()
    return .result(dialog: "Your trip has started. Say “End my trip in Skyway” when you arrive.")
  }
}

/// Ends the drive in progress and files it as business or personal. Siri asks which if it wasn't said.
struct EndDriveTripIntent: AppIntent {
  static let title: LocalizedStringResource = "End Trip"
  static let description = IntentDescription("Ends the trip in progress and saves it as a business or personal trip.")

  @Parameter(title: "Purpose")
  var purpose: DriveTrip.Purpose

  @MainActor
  func perform() async throws -> some IntentResult & ProvidesDialog {
    let store = DriveTripStore.shared
    guard store.activeTrip != nil else {
      throw DriveTripError.noTripInProgress
    }
    _ = await store.endingAddress()
    guard let trip = store.endTrip(as: purpose) else {
      throw DriveTripError.noTripInProgress
    }
    if purpose == .business {
      return .result(dialog: "Saved a \(trip.milesText) business trip, worth about \(trip.deductionText).")
    }
    return .result(dialog: "Saved a \(trip.milesText) personal trip.")
  }
}
