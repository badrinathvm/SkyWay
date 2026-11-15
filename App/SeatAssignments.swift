import Foundation

/// Seats the person picked after booking, saved across launches so changes from Siri stick.
enum SeatAssignments {
  static func storageKey(for confirmationCode: String) -> String {
    "seat.\(confirmationCode)"
  }

  /// The seat the person picked for the booking, or nil if they kept the original.
  static func savedSeat(for confirmationCode: String) -> String? {
    UserDefaults.standard.string(forKey: storageKey(for: confirmationCode))
  }

  /// Moves the booking to `seat`, returning the seat it had before.
  @discardableResult
  static func changeSeat(of trip: Trip, to seat: Seat) async -> String {
    let previous = trip.seat
    UserDefaults.standard.set(seat.description, forKey: storageKey(for: trip.confirmationCode))
    // Keep Siri and Spotlight up to date with the new seat.
    await TripStore.indexInSpotlight()
    return previous
  }
}

extension Trip {
  /// The trip with the seat the person picked, if they changed it.
  var withSavedSeat: Trip {
    var trip = self
    if let seat = SeatAssignments.savedSeat(for: confirmationCode) {
      trip.seat = seat
    }
    return trip
  }
}
