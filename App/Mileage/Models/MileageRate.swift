import Foundation

/// The IRS standard mileage rate for business driving, by the date a trip was driven.
/// The rate can change mid-year, so a trip uses the rate in effect on the day it started.
enum MileageRate {
  /// When each rate took effect, oldest first, in US dollars per mile.
  ///
  /// Sources: IRS notices 2023-75 (2024), 2025-5 (2025), and IR-2025-128 (2026). The mid-year
  /// rise to 76¢ from July 1, 2026 (Announcement 2026-11) comes from tax news coverage and
  /// should be checked against irs.gov. Add each new rate here when the IRS announces it.
  private static let schedule: [(effective: DateComponents, perMile: Double)] = [
    (DateComponents(year: 2024, month: 1, day: 1), 0.67),
    (DateComponents(year: 2025, month: 1, day: 1), 0.70),
    (DateComponents(year: 2026, month: 1, day: 1), 0.725),
    (DateComponents(year: 2026, month: 7, day: 1), 0.76),
  ]

  /// The rate for a trip driven on `date`. Dates before the schedule use its first rate,
  /// and dates after the last change use the latest one.
  static func perMile(on date: Date) -> Double {
    let calendar = Calendar.current
    // The most recent rate that had taken effect by that day, in the person's time zone.
    return schedule.last { entry in
      guard let effective = calendar.date(from: entry.effective) else { return false }
      return effective <= date
    }?.perMile ?? schedule[0].perMile
  }

  /// "72.5¢/mi".
  static func text(for perMile: Double) -> String {
    "\((perMile * 100).formatted(.number.precision(.fractionLength(0...1))))¢/mi"
  }
}
