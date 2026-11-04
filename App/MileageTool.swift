import Foundation
import FoundationModels

/// Lets the model answer questions about the drives logged for mileage,
/// like "How many business miles did I drive this month?"
struct MileageTool: Tool {
  let name = "getMileage"
  let description = """
    Summarizes the drives the person logged for mileage deductions in a time period: \
    the number of trips, miles, the business deduction, and the most recent trips. \
    Also says whether a drive is in progress.
    """

  @Generable
  enum Period: String {
    case today
    case thisWeek
    case thisMonth
    case thisYear
    case allTime
  }

  @Generable
  struct Arguments {
    @Guide(description: "The time period to summarize. Use allTime when the person doesn't name one.")
    var period: Period
  }

  func call(arguments: Arguments) async throws -> String {
    let (trips, activeTrip) = await MainActor.run {
      (DriveTripStore.shared.trips, DriveTripStore.shared.activeTrip)
    }
    return Self.summary(of: trips, activeTrip: activeTrip, in: arguments.period)
  }

  static func summary(of trips: [DriveTrip], activeTrip: DriveTrip?, in period: Period, now: Date = .now) -> String {
    let calendar = Calendar.current
    let inPeriod = trips.filter { trip in
      switch period {
      case .today: calendar.isDateInToday(trip.startDate)
      case .thisWeek: calendar.isDate(trip.startDate, equalTo: now, toGranularity: .weekOfYear)
      case .thisMonth: calendar.isDate(trip.startDate, equalTo: now, toGranularity: .month)
      case .thisYear: calendar.isDate(trip.startDate, equalTo: now, toGranularity: .year)
      case .allTime: true
      }
    }

    var lines: [String] = []
    if let activeTrip {
      lines.append("A drive is in progress: \(activeTrip.milesText) so far, started \(activeTrip.startTimeText).")
    }
    guard !inPeriod.isEmpty else {
      lines.append("No drives were logged in this period.")
      return lines.joined(separator: "\n")
    }

    let business = inPeriod.filter { $0.purpose == .business }
    let personal = inPeriod.filter { $0.purpose == .personal }
    let deduction = business.reduce(0) { $0 + $1.deduction }
    lines.append("\(inPeriod.count) drives, \(miles(inPeriod)) in total.")
    lines.append("Business: \(business.count) drives, \(miles(business)), deduction \(deduction.formatted(.currency(code: "USD"))).")
    lines.append("Personal: \(personal.count) drives, \(miles(personal)).")
    lines.append("Most recent:")
    lines.append(contentsOf: inPeriod.prefix(5).map { "• \($0.summaryText), \($0.routeText)" })
    return lines.joined(separator: "\n")
  }

  private static func miles(_ trips: [DriveTrip]) -> String {
    let total = trips.reduce(0) { $0 + $1.miles }
    return "\(total.formatted(.number.precision(.fractionLength(1)))) mi"
  }
}
