import AppIntents

enum DriveTripError: Error, CustomLocalizedStringResourceConvertible {
  case noTripInProgress

  var localizedStringResource: LocalizedStringResource {
    switch self {
    case .noTripInProgress: "You don't have a trip in progress in Skyway."
    }
  }
}
