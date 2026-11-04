import Foundation
import FoundationModels

/// What Skyway knows about the flight beyond the trip itself: the details behind each Travel card.
/// Used by the model through `TravelInfoTool`, and by the keyword fallback when the model is unavailable.
enum TravelKnowledge {
  @Generable
  enum Topic: String, CaseIterable {
    case inflightMenu
    case seatUpgrade
    case terminalDirections
    case checkedBags
    case wifiAndEntertainment
    case changeFlight
    case cancelTrip
    case checkIn
    case arrivalWeather
    case flightStatus
  }

  static func details(about topic: Topic, for trip: Trip) -> String {
    let departure = trip.departure.formatted(date: .omitted, time: .shortened)
    let boarding = trip.boardingTime.formatted(date: .omitted, time: .shortened)

    return switch topic {
    case .inflightMenu:
      """
      On \(trip.flightNumber) to \(trip.destinationCity) you can choose from:
      • Breakfast: Greek yogurt parfait with granola and berries
      • Snack box: hummus, pita chips, olives, and dark chocolate
      • Hot meal: chicken teriyaki rice bowl
      • Drinks: coffee, tea, juices, soft drinks, and beer and wine for purchase
      Pre-order by \(boarding) to make sure your first choice is available.
      """
    case .seatUpgrade:
      "Yes. Extra legroom seats are available on \(trip.flightNumber) for $49, including 12C (aisle) and 12F (window) near your current seat \(trip.seat). Tap Upgrade your seat on the Travel tab to choose one."
    case .terminalDirections:
      """
      To get to gate \(trip.gate) at \(trip.originCode):
      1. After security, follow signs for Concourse B.
      2. Take the moving walkway toward gates B15–B30.
      3. Gate \(trip.gate) is on your right, past the coffee shop.
      It's about a 9-minute walk. Boarding starts at \(boarding), so aim to be there by then.
      """
    case .checkedBags:
      "Your checked bag was scanned at \(trip.originCode) bag drop and is checked through to \(trip.destinationCode). After landing, collect it from the baggage claim carousel shown on the arrivals board."
    case .wifiAndEntertainment:
      "Yes. \(trip.flightNumber) has free messaging Wi-Fi, and full browsing for $8. Movies and TV stream to your own device through the Skyway Entertainment portal once you're above 10,000 feet."
    case .changeFlight:
      "You can change \(trip.flightNumber) up to 1 hour before departure. Later flights to \(trip.destinationCity) today leave at 9:15 AM and 1:40 PM. Tap Change flight on the Travel tab to see fares."
    case .cancelTrip:
      "You can cancel this trip from the Travel tab. Since your fare is refundable, you'll get credit for the full amount, using confirmation code \(trip.confirmationCode)."
    case .checkIn:
      "You're checked in for \(trip.flightNumber). Your boarding pass is ready in the boarding pass bar on the Flight status tab."
    case .arrivalWeather:
      "It's forecast to be \(trip.arrivalWeather) in \(trip.destinationCity) when you land."
    case .flightStatus:
      "Flight \(trip.flightNumber) is on time, departing at \(departure) from gate \(trip.gate)."
    }
  }
}
