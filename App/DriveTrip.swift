import CoreLocation
import Foundation

/// A drive logged for mileage, from Start a Trip to End Trip.
struct DriveTrip: Identifiable, Codable, Hashable, Sendable {
  enum Purpose: String, Codable, CaseIterable, Sendable {
    case business, personal

    var title: String {
      switch self {
      case .business: "Business"
      case .personal: "Personal"
      }
    }
  }

  struct Coordinate: Codable, Hashable, Sendable {
    var latitude: Double
    var longitude: Double

    init(_ coordinate: CLLocationCoordinate2D) {
      latitude = coordinate.latitude
      longitude = coordinate.longitude
    }

    var location: CLLocation { CLLocation(latitude: latitude, longitude: longitude) }
  }

  /// An approximate deduction rate, in dollars per mile driven.
  static let deductionPerMile = 0.16

  var id = UUID()
  var startDate: Date
  var endDate: Date?
  var start: Coordinate?
  var end: Coordinate?
  /// Filled in from the first and last GPS fixes, so nobody has to enter an address.
  var startAddress: String?
  var endAddress: String?
  var miles = 0.0
  var purpose: Purpose?

  /// What the trip would be worth as a business trip, shown while driving.
  var estimatedDeduction: Double { miles * Self.deductionPerMile }

  /// Only business trips count toward the deduction.
  var deduction: Double { purpose == .business ? estimatedDeduction : 0 }

  func duration(now: Date = .now) -> TimeInterval {
    (endDate ?? now).timeIntervalSince(startDate)
  }

  // MARK: Display

  var milesText: String {
    "\(miles.formatted(.number.precision(.fractionLength(1)))) mi"
  }

  var estimatedDeductionText: String {
    estimatedDeduction.formatted(.currency(code: "USD"))
  }

  var deductionText: String {
    deduction.formatted(.currency(code: "USD"))
  }

  func minutesText(now: Date = .now) -> String {
    "\(Int(duration(now: now) / 60)) min"
  }

  var startTimeText: String {
    startDate.formatted(date: .omitted, time: .shortened)
  }

  var routeText: String {
    "\(startAddress ?? "Start") → \(endAddress ?? "End")"
  }

  /// "Today 8:12 AM", "Yesterday 6:05 PM", or "Oct 29" for older trips.
  var dayText: String {
    let calendar = Calendar.current
    if calendar.isDateInToday(startDate) {
      return "Today \(startTimeText)"
    } else if calendar.isDateInYesterday(startDate) {
      return "Yesterday \(startTimeText)"
    }
    return startDate.formatted(.dateTime.month(.abbreviated).day())
  }

  /// For a recent-trips row, such as "Today 8:12 AM · 14.2 mi · Business · $2.27".
  var summaryText: String {
    var parts = [dayText, milesText]
    if let purpose {
      parts.append(purpose.title)
    }
    if purpose == .business {
      parts.append(deductionText)
    }
    return parts.joined(separator: " · ")
  }
}
