import AppIntents
import SwiftUI

/// The card Siri shows while asking the person to confirm a seat change. Only reads state.
struct SeatChangeConfirmationSnippetIntent: SnippetIntent {
  static let title: LocalizedStringResource = "Seat Change Confirmation"
  static let isDiscoverable = false

  @Parameter(title: "Trip")
  var trip: TripEntity

  @Parameter(title: "New Seat")
  var newSeat: String

  init() {}

  init(trip: TripEntity, newSeat: String) {
    self.trip = trip
    self.newSeat = newSeat
  }

  func perform() async throws -> some IntentResult & ShowsSnippetView {
    guard let booking = TripStore.trips(with: [trip.id]).first, let seat = Seat(newSeat) else {
      throw TripError.noUpcomingTrip
    }
    return .result(view: SeatChangeConfirmationCard(trip: booking, newSeat: seat, fee: SeatMap.forTrip(booking).fee(for: seat)))
  }
}

/// The card Siri shows after the seat changed, with an Undo button. Only reads state.
struct SeatChangeResultSnippetIntent: SnippetIntent {
  static let title: LocalizedStringResource = "Seat Changed"
  static let isDiscoverable = false

  @Parameter(title: "Trip")
  var trip: TripEntity

  @Parameter(title: "Previous Seat")
  var previousSeat: String

  init() {}

  init(trip: TripEntity, previousSeat: String) {
    self.trip = trip
    self.previousSeat = previousSeat
  }

  func perform() async throws -> some IntentResult & ShowsSnippetView {
    guard let booking = TripStore.trips(with: [trip.id]).first else {
      throw TripError.noUpcomingTrip
    }
    return .result(view: SeatChangeResultCard(trip: booking, previousSeat: previousSeat))
  }
}
