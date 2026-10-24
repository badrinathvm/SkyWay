import SwiftUI

struct FlightStatusView: View {
  var assistant: FlightAssistant

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(spacing: 12) {
          FlightStatusCard(trip: assistant.trip, boardingTime: assistant.boardingTime)
            .padding(.bottom, 8)

          if assistant.messages.isEmpty {
            SuggestionList(assistant: assistant)
          } else {
            ForEach(assistant.messages) { message in
              MessageBubble(message: message)
            }
          }
        }
        .padding()
        .frame(maxWidth: .infinity)
      }
      .defaultScrollAnchor(.bottom, for: .sizeChanges)
      .scrollDismissesKeyboard(.interactively)
      .background(Color(.systemGroupedBackground))
      .navigationTitle("Flight status")
      .animation(.smooth, value: assistant.messages)
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
    .background(.background, in: .rect(cornerRadius: 20))
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

private struct SuggestionList: View {
  var assistant: FlightAssistant

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Try asking")
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)
      ForEach(FlightAssistant.suggestions, id: \.self) { suggestion in
        Button(suggestion, systemImage: "sparkles") {
          assistant.send(suggestion)
        }
        .buttonStyle(.bordered)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct MessageBubble: View {
  var message: ChatMessage

  var body: some View {
    HStack {
      if isUser { Spacer(minLength: 48) }
      Text(message.text)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .foregroundStyle(isUser ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
        .background(isUser ? AnyShapeStyle(.tint) : AnyShapeStyle(.background), in: .rect(cornerRadius: 18))
      if !isUser { Spacer(minLength: 48) }
    }
    .accessibilityLabel("\(isUser ? "You" : "Skyway"): \(message.text)")
  }

  private var isUser: Bool { message.sender == .user }
}
