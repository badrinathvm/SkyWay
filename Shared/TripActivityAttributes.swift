import ActivityKit
import Foundation

/// A mileage trip in progress, shown as a Live Activity on the Lock Screen, in the Dynamic Island,
/// and on the CarPlay screen next to Maps.
struct TripActivityAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    var miles: Double
    var isParked: Bool
  }

  var startDate: Date
  /// Dollars per mile, passed in so the widget extension needn't know the app's rate.
  var deductionPerMile: Double
}

extension TripActivityAttributes.ContentState {
  var milesText: String {
    "\(miles.formatted(.number.precision(.fractionLength(1)))) mi"
  }

  func estimatedDeductionText(perMile rate: Double) -> String {
    (miles * rate).formatted(.currency(code: "USD"))
  }
}
