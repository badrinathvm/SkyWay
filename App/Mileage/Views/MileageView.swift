import SwiftUI

/// Every drive logged from CarPlay or Siri, by month, where a trip can be marked business or
/// personal. Only business trips count toward the mileage deduction.
struct MileageView: View {
  private var store = DriveTripStore.shared

  var body: some View {
    Group {
      if store.trips.isEmpty, store.activeTrip == nil {
        ContentUnavailableView {
          Label("No Trips", systemImage: "car")
        } description: {
          Text("Start a trip from Skyway in CarPlay, or say, “Start a trip in Skyway.”")
        }
      } else {
        list
      }
    }
    .navigationTitle("Mileage")
    .navigationBarTitleDisplayMode(.inline)
  }

  private var list: some View {
    List {
      Section {
        summary
      }

      if let activeTrip = store.activeTrip {
        Section("In Progress") {
          LabeledContent {
            Text(activeTrip.milesText)
              .monospacedDigit()
          } label: {
            Label("Started \(activeTrip.startTimeText)", systemImage: "location.fill")
          }
        }
      }

      if !unclassifiedTrips.isEmpty {
        Section {
          ForEach(unclassifiedTrips) { trip in
            MileageTripRow(trip: trip)
          }
        } header: {
          Text("Needs a Purpose")
        } footer: {
          Text("Mark these business or personal. Only business trips count toward your deduction.")
        }
      }

      ForEach(monthSections, id: \.month) { section in
        Section(section.month.formatted(.dateTime.month(.wide).year())) {
          ForEach(section.trips) { trip in
            MileageTripRow(trip: trip)
          }
        }
      }
    }
  }

  private var summary: some View {
    let report = MonthlyReport(month: .now, expenses: [], trips: store.trips, invoices: [])
    return VStack(alignment: .leading, spacing: 4) {
      Text("Business Miles in \(Date.now.formatted(.dateTime.month(.wide)))")
        .font(.subheadline)
        .foregroundStyle(.secondary)
      Text("\(report.businessMiles.formatted(.number.precision(.fractionLength(1)))) mi")
        .font(.largeTitle.weight(.bold))
        .monospacedDigit()
      Text("\(MonthlyReport.usd(report.mileageDeduction)) deduction at \(MileageRate.text(for: MileageRate.perMile(on: .now)))")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .padding(.vertical, 4)
    .accessibilityElement(children: .combine)
  }

  private var unclassifiedTrips: [DriveTrip] {
    store.trips.filter { $0.purpose == nil }
  }

  /// Trips with a purpose, grouped by the month they started in, newest month first.
  private var monthSections: [(month: Date, trips: [DriveTrip])] {
    Dictionary(grouping: store.trips.filter { $0.purpose != nil }) {
      MonthlyReport.interval(containing: $0.startDate).start
    }
    .map { (month: $0.key, trips: $0.value.sorted { $0.startDate > $1.startDate }) }
    .sorted { $0.month > $1.month }
  }
}
