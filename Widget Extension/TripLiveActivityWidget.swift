import ActivityKit
import SwiftUI
import WidgetKit

/// The trip in progress: its miles and estimated deduction, glanceable on CarPlay next to Maps.
struct TripLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: TripActivityAttributes.self) { context in
      TripActivityView(attributes: context.attributes, state: context.state)
        .activityBackgroundTint(.black.opacity(0.6))
        .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      let state = context.state
      let attributes = context.attributes
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Label(state.milesText, systemImage: "car.fill")
            .font(.title3.bold())
            .monospacedDigit()
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text("\(state.estimatedDeductionText(perMile: attributes.deductionPerMile)) est.")
            .font(.title3.bold())
            .monospacedDigit()
            .foregroundStyle(.green)
        }
        DynamicIslandExpandedRegion(.bottom) {
          TripStatusText(attributes: attributes, state: state)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
      } compactLeading: {
        Image(systemName: "car.fill")
          .foregroundStyle(.green)
          .accessibilityLabel("Trip in progress")
      } compactTrailing: {
        Text(state.milesText)
          .monospacedDigit()
      } minimal: {
        Image(systemName: "car.fill")
          .foregroundStyle(.green)
          .accessibilityLabel("Trip in progress, \(state.milesText)")
      }
    }
    .supplementalActivityFamilies([.small, .medium])
  }
}

/// The Lock Screen, StandBy, and the small layout CarPlay and Apple Watch show.
private struct TripActivityView: View {
  var attributes: TripActivityAttributes
  var state: TripActivityAttributes.ContentState
  @Environment(\.activityFamily) private var family

  var body: some View {
    switch family {
    case .small:
      // CarPlay's card is small and read at a glance, so just the two numbers and the status.
      VStack(alignment: .leading, spacing: 2) {
        Label("Trip", systemImage: "car.fill")
          .font(.caption.bold())
          .foregroundStyle(.green)
        Text(state.milesText)
          .font(.title2.bold())
          .monospacedDigit()
        Text("\(state.estimatedDeductionText(perMile: attributes.deductionPerMile)) est.")
          .font(.subheadline.bold())
          .monospacedDigit()
          .foregroundStyle(.green)
        TripStatusText(attributes: attributes, state: state)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(8)
    default:
      HStack(alignment: .center, spacing: 16) {
        Image(systemName: "car.fill")
          .font(.title)
          .foregroundStyle(.green)
          .accessibilityHidden(true)
        VStack(alignment: .leading, spacing: 4) {
          Text("Trip in Progress")
            .font(.headline)
          TripStatusText(attributes: attributes, state: state)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        Spacer()
        VStack(alignment: .trailing, spacing: 4) {
          Text(state.milesText)
            .font(.title2.bold())
            .monospacedDigit()
          Text("\(state.estimatedDeductionText(perMile: attributes.deductionPerMile)) est.")
            .font(.subheadline.bold())
            .monospacedDigit()
            .foregroundStyle(.green)
        }
      }
      .padding()
    }
  }
}

/// "Driving · 12:04" or "Parked · 12:04", with the time counting up on its own.
private struct TripStatusText: View {
  var attributes: TripActivityAttributes
  var state: TripActivityAttributes.ContentState

  var body: some View {
    HStack(spacing: 4) {
      Text(state.isParked ? "Parked" : "Driving")
      Text("·")
      Text(timerInterval: attributes.startDate...Date.distantFuture, countsDown: false)
        .monospacedDigit()
    }
  }
}
