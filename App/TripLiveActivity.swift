import ActivityKit
import Foundation

/// Keeps a Live Activity in step with the trip in progress, so its miles and deduction stay in
/// view on CarPlay while the driver follows a heading-up map in Apple Maps or Google Maps.
@MainActor
final class TripLiveActivity {
  private var activity: Activity<TripActivityAttributes>?
  private var shownState: TripActivityAttributes.ContentState?
  private var lastUpdate = Date.distantPast

  /// Starts one for `trip`, or picks up the one already running after a relaunch.
  func start(for trip: DriveTrip) {
    if activity == nil {
      activity = Activity<TripActivityAttributes>.activities.first { $0.attributes.startDate == trip.startDate }
    }
    // A trip from an earlier launch that ended without its activity, such as after a crash.
    for stale in Activity<TripActivityAttributes>.activities where stale.id != activity?.id {
      Task { await stale.end(nil, dismissalPolicy: .immediate) }
    }
    guard activity == nil else { return }
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
      // The trip is still tracked, and CarPlay's own trip screen still shows it.
      print("Live Activities are turned off for Skyway in Settings.")
      return
    }
    let state = TripActivityAttributes.ContentState(miles: trip.miles, isParked: false)
    do {
      activity = try Activity.request(
        attributes: TripActivityAttributes(startDate: trip.startDate, deductionPerMile: DriveTrip.deductionPerMile),
        content: ActivityContent(state: state, staleDate: nil)
      )
      shownState = state
    } catch {
      print("Couldn't start the trip's Live Activity: \(error)")
    }
  }

  /// Updates the miles shown, at most every 10 seconds, and only when the tenth of a mile shown
  /// or the parked status changes, so it stays within the system's update budget.
  func update(miles: Double, isParked: Bool) {
    guard let activity else { return }
    let state = TripActivityAttributes.ContentState(miles: miles, isParked: isParked)
    if let shownState, shownState.milesText == state.milesText, shownState.isParked == isParked { return }
    guard Date.now.timeIntervalSince(lastUpdate) >= 10 else { return }
    lastUpdate = .now
    shownState = state
    Task { await activity.update(ActivityContent(state: state, staleDate: nil)) }
  }

  /// Ends it, showing the trip's final miles briefly before it goes.
  func end(miles: Double?) {
    guard let activity else { return }
    self.activity = nil
    shownState = nil
    let content = miles.map {
      ActivityContent(state: TripActivityAttributes.ContentState(miles: $0, isParked: true), staleDate: nil)
    }
    Task { await activity.end(content, dismissalPolicy: .after(.now.addingTimeInterval(60))) }
  }
}
