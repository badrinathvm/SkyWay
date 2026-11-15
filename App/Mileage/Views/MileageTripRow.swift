import SwiftUI

/// One drive: where it went, when, how far, and what it's worth, with a menu to mark it
/// business or personal.
struct MileageTripRow: View {
  var trip: DriveTrip

  private var purpose: Binding<DriveTrip.Purpose?> {
    Binding {
      trip.purpose
    } set: { purpose in
      if let purpose {
        DriveTripStore.shared.setPurpose(purpose, for: trip.id)
      }
    }
  }

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: symbol)
        .font(.body.weight(.semibold))
        .foregroundStyle(color)
        .frame(width: 36, height: 36)
        .background(color.opacity(0.15), in: .circle)
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 2) {
        Text(trip.routeText)
          .font(.body.weight(.medium))
          .lineLimit(1)
        Text("\(trip.startDate.formatted(.dateTime.month(.abbreviated).day())) · \(trip.startTimeText) · \(trip.milesText)")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .monospacedDigit()
      }

      Spacer(minLength: 8)

      VStack(alignment: .trailing, spacing: 2) {
        Text(trip.purpose == .business ? trip.deductionText : "–")
          .font(.body.weight(.semibold))
          .monospacedDigit()
          .accessibilityLabel(trip.purpose == .business ? "Deduction \(trip.deductionText)" : "No deduction")
        purposeMenu
      }
    }
    .swipeActions(edge: .trailing) {
      if trip.purpose != .business {
        Button("Business", systemImage: "briefcase.fill") {
          purpose.wrappedValue = .business
        }
        .tint(.brown)
      }
      if trip.purpose != .personal {
        Button("Personal", systemImage: "car.fill") {
          purpose.wrappedValue = .personal
        }
        .tint(.gray)
      }
    }
  }

  private var purposeMenu: some View {
    Menu {
      Picker("Purpose", selection: purpose) {
        ForEach(DriveTrip.Purpose.allCases, id: \.self) { purpose in
          Text(purpose.title).tag(Optional(purpose))
        }
      }
    } label: {
      Text(trip.purpose?.title ?? "Set Purpose")
        .font(.subheadline)
    }
    .accessibilityLabel("Purpose")
    .accessibilityValue(trip.purpose?.title ?? "Not set")
  }

  private var symbol: String {
    switch trip.purpose {
    case .business: "briefcase.fill"
    case .personal: "car.fill"
    case nil: "questionmark"
    }
  }

  private var color: Color {
    switch trip.purpose {
    case .business: .brown
    case .personal: .red
    case nil: .orange
    }
  }
}
