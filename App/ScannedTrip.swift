import FoundationModels

/// Flight details read from a photo of a boarding pass or itinerary.
@Generable
struct ScannedTrip: Hashable {
  @Guide(description: "The airline and flight number, like SW 214.")
  var flightNumber: String

  @Guide(description: "The three-letter airport code the flight leaves from.")
  var originCode: String

  @Guide(description: "The three-letter airport code the flight arrives at.")
  var destinationCode: String

  @Guide(description: "The departure date and time exactly as printed.")
  var departure: String?

  var passengerName: String?
  var gate: String?
  var seat: String?
  var boardingGroup: String?
  var confirmationCode: String?

  /// Whether this is the same flight as one already in Skyway.
  func isSameFlight(as trip: Trip) -> Bool {
    let normalized = { (text: String) in text.filter { !$0.isWhitespace }.uppercased() }
    if let confirmationCode, normalized(confirmationCode) == normalized(trip.confirmationCode) {
      return true
    }
    return normalized(flightNumber) == normalized(trip.flightNumber)
      && normalized(originCode) == trip.originCode
      && normalized(destinationCode) == trip.destinationCode
  }

  /// Labeled details for the scanned trip card, skipping anything the photo didn't show.
  var details: [(label: String, value: String)] {
    [
      ("Departs", departure),
      ("Gate", gate),
      ("Seat", seat),
      ("Group", boardingGroup),
      ("Passenger", passengerName),
      ("Confirmation", confirmationCode),
    ]
    .compactMap { label, value in
      guard let value, !value.isEmpty else { return nil }
      return (label, value)
    }
  }
}
