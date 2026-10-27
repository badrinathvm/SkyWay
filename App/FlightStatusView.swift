import SwiftUI

struct FlightStatusView: View {
  var assistant: FlightAssistant
  /// Whether the assistant chat is open, kept per window.
  @SceneStorage("isAssistantInspectorPresented") private var isShowingAssistant = false

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 16) {
          FlightStatusCard(trip: assistant.trip, boardingTime: assistant.boardingTime)
          TripDetailsCard(trip: assistant.trip)
        }
        .padding()
        .frame(maxWidth: .infinity)
      }
      .background(Color(.systemGroupedBackground))
      .navigationTitle("Flight status")
      .toolbar {
        Button("Assistant", systemImage: "bubble.left.and.text.bubble.right") {
          isShowingAssistant.toggle()
        }
      }
      // A trailing column in regular width, and a sheet in compact width.
      .inspector(isPresented: $isShowingAssistant) {
        AssistantChatView(assistant: assistant)
          .inspectorColumnWidth(min: 300, ideal: 360, max: 460)
      }
    }
  }
}

private struct FlightStatusCard: View {
  var trip: Trip
  var boardingTime: Date

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(trip.flightNumber)
          .font(.title2.bold())
        Spacer()
        Label("On time", systemImage: "checkmark.circle.fill")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.green)
      }
      Text("\(trip.originCode) → \(trip.destinationCode)")
        .font(.headline)
        .foregroundStyle(.secondary)
      HStack(spacing: 24) {
        StatusDetail(label: "Departs", value: trip.departure.formatted(date: .omitted, time: .shortened))
        StatusDetail(label: "Boards", value: boardingTime.formatted(date: .omitted, time: .shortened))
        StatusDetail(label: "Gate", value: trip.gate)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(20)
    .cardBackground()
  }
}

private struct StatusDetail: View {
  var label: String
  var value: String

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(label)
        .font(.caption)
        .foregroundStyle(.secondary)
      Text(value)
        .font(.headline)
    }
    .accessibilityElement(children: .combine)
  }
}

private struct TripDetailsCard: View {
  var trip: Trip

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Your trip")
        .font(.headline)
      HStack(spacing: 24) {
        StatusDetail(label: "Seat", value: trip.seat)
        StatusDetail(label: "Group", value: trip.boardingGroup)
        StatusDetail(label: "Confirmation", value: trip.confirmationCode)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(20)
    .cardBackground()
  }
}
