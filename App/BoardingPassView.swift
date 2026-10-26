import AppIntents
import CoreImage.CIFilterBuiltins
import SwiftUI

struct BoardingPassView: View {
  var trip: Trip
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 24) {
          HStack {
            AirportCode(code: trip.originCode, label: "From")
            Spacer()
            Image(systemName: "airplane")
              .font(.title2)
              .foregroundStyle(.tint)
              .accessibilityHidden(true)
            Spacer()
            AirportCode(code: trip.destinationCode, label: "To")
          }

          Divider()

          Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 16) {
            GridRow {
              PassDetail(label: "Passenger", value: trip.passengerName)
              PassDetail(label: "Flight", value: trip.flightNumber)
            }
            GridRow {
              PassDetail(label: "Departs", value: trip.departure.formatted(date: .omitted, time: .shortened))
              PassDetail(label: "Gate", value: trip.gate)
            }
            GridRow {
              PassDetail(label: "Seat", value: trip.seat)
              PassDetail(label: "Group", value: trip.boardingGroup)
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)

          Divider()

          qrCode
            .frame(width: 200, height: 200)
            .accessibilityLabel("Boarding pass QR code")

          Text("Confirmation \(trip.confirmationCode)")
            .font(.footnote.monospaced())
            .foregroundStyle(.secondary)
        }
        .padding(24)
        .cardBackground(cornerRadius: 24)
        .padding()
        .frame(maxWidth: .infinity)
      }
      .background(Color(.systemGroupedBackground))
      .navigationTitle(trip.title)
      .navigationBarTitleDisplayMode(.inline)
      .userActivity(TripEntity.viewTripActivityType) { activity in
        activity.title = trip.title
        activity.appEntityIdentifier = EntityIdentifier(for: TripEntity.self, identifier: trip.id)
      }
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done", systemImage: "checkmark") { dismiss() }
        }
      }
    }
  }

  @ViewBuilder
  private var qrCode: some View {
    if let image = Self.makeQRCode(from: trip.boardingPassPayload) {
      Image(uiImage: image)
        .interpolation(.none)
        .resizable()
        .scaledToFit()
    } else {
      Image(systemName: "qrcode")
        .resizable()
        .scaledToFit()
    }
  }

  private static func makeQRCode(from string: String) -> UIImage? {
    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(string.utf8)
    filter.correctionLevel = "M"
    guard let output = filter.outputImage,
          let cgImage = CIContext().createCGImage(output, from: output.extent)
    else { return nil }
    return UIImage(cgImage: cgImage)
  }
}

private struct AirportCode: View {
  var code: String
  var label: String

  var body: some View {
    VStack(spacing: 2) {
      Text(label)
        .font(.caption)
        .foregroundStyle(.secondary)
      Text(code)
        .font(.largeTitle.bold())
    }
    .accessibilityElement(children: .combine)
  }
}

private struct PassDetail: View {
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
