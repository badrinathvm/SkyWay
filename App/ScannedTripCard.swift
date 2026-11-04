import SwiftUI

/// The flight the assistant read from a boarding pass or itinerary photo,
/// and whether it matches the trip already in Skyway.
struct ScannedTripCard: View {
  var scannedTrip: ScannedTrip
  var trip: Trip?

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .firstTextBaseline) {
        Label(scannedTrip.flightNumber, systemImage: "airplane")
          .font(.headline)
        Spacer(minLength: 8)
        if let trip {
          matchBadge(isMatch: scannedTrip.isSameFlight(as: trip))
        }
      }

      Text("\(scannedTrip.originCode) → \(scannedTrip.destinationCode)")
        .font(.title3.bold())

      if !scannedTrip.details.isEmpty {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
          ForEach(scannedTrip.details, id: \.label) { detail in
            GridRow {
              Text(detail.label)
                .foregroundStyle(.secondary)
              Text(detail.value)
            }
            .font(.subheadline)
          }
        }
      }
    }
    .padding(16)
    .frame(maxWidth: 280, alignment: .leading)
    .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
    .overlay {
      RoundedRectangle(cornerRadius: 18)
        .strokeBorder(.separator)
    }
    .accessibilityElement(children: .combine)
  }

  private func matchBadge(isMatch: Bool) -> some View {
    Label(
      isMatch ? "Your trip" : "Different flight",
      systemImage: isMatch ? "checkmark.seal.fill" : "exclamationmark.triangle.fill"
    )
    .font(.caption.weight(.semibold))
    .foregroundStyle(isMatch ? .green : .orange)
  }
}
