import CoreLocation
import Foundation

/// A place at the departure airport a driver might head to.
struct AirportSpot: Identifiable, Hashable {
  enum Kind: String {
    case dropOff, parking, cellPhoneLot, rentalReturn
  }

  var id: Kind { kind }
  var kind: Kind
  var title: String
  var subtitle: String
  var summary: String
  var systemImage: String
  var latitude: Double
  var longitude: Double

  var coordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }

  /// Opens turn-by-turn directions in Apple Maps.
  var directionsURL: URL? {
    var components = URLComponents()
    components.scheme = "maps"
    components.queryItems = [
      URLQueryItem(name: "daddr", value: "\(latitude),\(longitude)"),
      URLQueryItem(name: "dirflg", value: "d"),
    ]
    return components.url
  }

  /// Sample spots for JFK Terminal 4, home of the B gates.
  static func spots(for trip: Trip) -> [AirportSpot] {
    [
      AirportSpot(kind: .dropOff, title: "Terminal 4 Departures", subtitle: "Upper level curbside", summary: "Closest to security for gate \(trip.gate)", systemImage: "figure.walk.departure", latitude: 40.6443, longitude: -73.7822),
      AirportSpot(kind: .parking, title: "Blue Parking Lot", subtitle: "Short-term · $9/hr", summary: "Walk to Terminal 4", systemImage: "parkingsign", latitude: 40.6460, longitude: -73.7855),
      AirportSpot(kind: .cellPhoneLot, title: "Cell Phone Lot", subtitle: "Free · 1 hr limit", summary: "Wait here for pickups", systemImage: "iphone.gen3", latitude: 40.6590, longitude: -73.7995),
      AirportSpot(kind: .rentalReturn, title: "Rental Car Return", subtitle: "Federal Circle", summary: "AirTrain to Terminal 4", systemImage: "car.fill", latitude: 40.6603, longitude: -73.8030),
    ]
  }
}
