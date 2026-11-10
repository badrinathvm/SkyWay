import AppIntents

enum TripError: Error, CustomLocalizedStringResourceConvertible {
  case noUpcomingTrip

  var localizedStringResource: LocalizedStringResource {
    switch self {
    case .noUpcomingTrip: "You don't have any upcoming trips in Skyway."
    }
  }
}
