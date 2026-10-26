import AppIntents
import SwiftUI

struct TravelView: View {
  var trip: Trip
  @Bindable var assistant: FlightAssistant

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 16) {
          TripSummaryCard(trip: trip)
            .assistantContext(trip.summaryContextItem)

          // Not a card: any view can be shared as context.
          Label("\(trip.arrivalWeather) in \(trip.destinationCity) on arrival", systemImage: "sun.max.fill")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .symbolRenderingMode(.multicolor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .assistantContext(trip.weatherContextItem, cornerRadius: 16)
            .frame(maxWidth: .infinity, alignment: .leading)

          ForEach(TravelAction.featured) { action in
            TravelActionRow(action: action)
              .assistantContext(action.contextItem)
          }

          HStack(spacing: 16) {
            ForEach(TravelAction.quick) { action in
              QuickActionTile(action: action)
                .assistantContext(action.contextItem)
            }
          }
        }
        .padding()
        .frame(maxWidth: .infinity)
      }
      .scrollDismissesKeyboard(.interactively)
      // Tapping outside the composer dismisses it, so it doesn't need a close button.
      .simultaneousGesture(TapGesture().onEnded {
        guard assistant.isComposing else { return }
        withAnimation(.smooth) {
          assistant.stopComposing()
        }
      })
      .background(Color(.systemGroupedBackground))
      .navigationTitle("Travel")
      .environment(\.screenContext, assistant.screenContext)
      .task { await ScreenContextTip.travelViewed.donate() }
      .sheet(isPresented: $assistant.isShowingAnswerSheet, onDismiss: assistant.endSession) {
        AssistantAnswerSheet(assistant: assistant)
      }
      .safeAreaInset(edge: .bottom) {
        if assistant.isComposing {
          AssistantComposer(assistant: assistant)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
      }
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
    .cardBackground()
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
      .cardBackground()
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
      .cardBackground()
        .contentShape(.rect(cornerRadius: 20))
    }
    .buttonStyle(.plain)
  }
}
