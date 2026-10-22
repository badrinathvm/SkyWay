import AppIntents
import SwiftUI

struct TravelView: View {
  var trip: Trip

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 16) {
          TripSummaryCard(trip: trip)

          ForEach(TravelAction.featured) { action in
            TravelActionRow(action: action)
          }

          HStack(spacing: 16) {
            ForEach(TravelAction.quick) { action in
              QuickActionTile(action: action)
            }
          }
        }
        .padding()
        .frame(maxWidth: .infinity)
      }
      .background(Color(.systemGroupedBackground))
      .navigationTitle("Travel")
      // Annotate the Travel screen with the trip so Siri and Apple Intelligence
      // can resolve "my trip" or "this trip" from onscreen context.
      .userActivity(TripEntity.viewTripActivityType) { activity in
        activity.title = trip.title
        activity.appEntityIdentifier = EntityIdentifier(for: TripEntity.self, identifier: trip.id)
      }
    }
  }
}

private struct TripSummaryCard: View {
  var trip: Trip

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(trip.title)
        .font(.title2.bold())
      Text("\(trip.flightNumber) · \(trip.originCode) → \(trip.destinationCode)")
        .font(.subheadline)
        .foregroundStyle(.secondary)
      Label("Departs \(trip.departure.formatted(date: .omitted, time: .shortened)) from gate \(trip.gate)", systemImage: "clock")
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.tint)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(20)
    .background(.background, in: .rect(cornerRadius: 20))
  }
}

private struct TravelActionRow: View {
  var action: TravelAction

  var body: some View {
    Button {} label: {
      HStack(spacing: 16) {
        Image(systemName: action.systemImage)
          .font(.title3)
          .foregroundStyle(.primary)
          .frame(width: 52, height: 52)
          .background(.tint.opacity(0.12), in: .circle)

        VStack(alignment: .leading, spacing: 4) {
          Text(action.title)
            .font(.headline)
          Text(action.subtitle)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.leading)

        Spacer(minLength: 0)

        Image(systemName: "chevron.right")
          .font(.body.weight(.semibold))
          .foregroundStyle(.tint)
      }
      .padding(20)
      .frame(maxWidth: .infinity)
      .background(.background, in: .rect(cornerRadius: 20))
      .contentShape(.rect(cornerRadius: 20))
    }
    .buttonStyle(.plain)
  }
}

private struct QuickActionTile: View {
  var action: TravelAction

  var body: some View {
    Button {} label: {
      VStack(spacing: 12) {
        Image(systemName: action.systemImage)
          .font(.title2)
          .foregroundStyle(.tint)
          .frame(width: 52, height: 52)
          .background(.tint.opacity(0.12), in: .circle)
        Text(action.title)
          .font(.headline)
      }
      .padding(20)
      .frame(maxWidth: .infinity)
      .background(.background, in: .rect(cornerRadius: 20))
      .contentShape(.rect(cornerRadius: 20))
    }
    .buttonStyle(.plain)
  }
}
