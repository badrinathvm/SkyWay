import AppIntents
import SwiftUI

/// Shown in Siri before the change: the current seat, the new seat, and any fee.
struct SeatChangeConfirmationCard: View {
  var trip: Trip
  var newSeat: Seat
  var fee: Int?

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      FlightHeader(trip: trip)
      HStack(spacing: 12) {
        SeatChip(title: "Current", seat: trip.seat, position: Seat(trip.seat)?.position, isHighlighted: false)
        Image(systemName: "arrow.right")
          .font(.title3.weight(.semibold))
          .foregroundStyle(.secondary)
          .accessibilityHidden(true)
        SeatChip(title: "New", seat: newSeat.description, position: newSeat.position, isHighlighted: true)
      }
      if let fee {
        Label("Extra legroom · $\(fee), charged to your card on file", systemImage: "creditcard")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      } else {
        Label("No fee for this seat", systemImage: "checkmark.seal")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
    .padding()
  }
}

/// Shown in Siri after the change, with a button to go back to the old seat.
struct SeatChangeResultCard: View {
  var trip: Trip
  var previousSeat: String

  private var isUndone: Bool { trip.seat == previousSeat }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      FlightHeader(trip: trip)
      HStack(spacing: 24) {
        PassField(label: "Seat", value: trip.seat)
        PassField(label: "Gate", value: trip.gate)
        PassField(label: "Group", value: trip.boardingGroup)
        PassField(label: "Boards", value: trip.boardingTime.formatted(date: .omitted, time: .shortened))
      }
      if isUndone {
        Label("Change undone. You're back in \(previousSeat).", systemImage: "arrow.uturn.backward")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      } else {
        HStack {
          Label("Moved from \(previousSeat)", systemImage: "checkmark.circle.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.green)
          Spacer()
          Button(intent: UndoSeatChangeIntent(trip: trip.entity, seat: previousSeat)) {
            Label("Undo", systemImage: "arrow.uturn.backward")
          }
          .buttonStyle(.bordered)
        }
      }
    }
    .padding()
  }
}

private struct FlightHeader: View {
  var trip: Trip

  var body: some View {
    HStack {
      Image(systemName: "airplane")
        .font(.title3)
        .foregroundStyle(.tint)
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 2) {
        Text("Flight \(trip.flightNumber)")
          .font(.headline)
        Text("\(trip.originCode) → \(trip.destinationCode) · \(trip.departure.formatted(date: .abbreviated, time: .shortened))")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
    .accessibilityElement(children: .combine)
  }
}

private struct SeatChip: View {
  var title: String
  var seat: String
  var position: Seat.Position?
  var isHighlighted: Bool

  var body: some View {
    VStack(spacing: 4) {
      Text(title)
        .font(.caption)
        .foregroundStyle(.secondary)
      Label(seat, systemImage: "carseat.left.fill")
        .font(.title2.bold())
        .foregroundStyle(isHighlighted ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
      if let position {
        Text(position.title)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 12)
    .background(.fill.tertiary, in: .rect(cornerRadius: 12))
    .accessibilityElement(children: .combine)
  }
}

private struct PassField: View {
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
