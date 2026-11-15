import SwiftData
import SwiftUI

/// A month's spending, invoices and business mileage, with CSV and PDF export.
struct MonthlyReportView: View {
  @Query private var expenses: [Expense]
  @State private var monthStart = MonthlyReport.interval(containing: .now).start
  @State private var invoices = InvoiceStore.invoices
  @Environment(\.scenePhase) private var scenePhase

  private var report: MonthlyReport {
    MonthlyReport(month: monthStart, expenses: expenses, trips: DriveTripStore.shared.trips, invoices: invoices)
  }

  private var isCurrentMonth: Bool {
    MonthlyReport.interval(containing: .now).start == monthStart
  }

  var body: some View {
    let report = report
    List {
      Section {
        monthSwitcher(report)
      }

      if report.isEmpty {
        ContentUnavailableView(
          "Nothing in \(report.title)",
          systemImage: "chart.bar.doc.horizontal",
          description: Text("Expenses, business trips and invoices from this month show up here.")
        )
        .listRowBackground(Color.clear)
      } else {
        summarySection(report)
        categorySection(report)
        invoiceSection(report)
        tripSection(report)
      }
    }
    .navigationTitle("Monthly Report")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Menu("Export", systemImage: "square.and.arrow.up") {
          ShareLink(
            item: ReportPDFFile(report: report),
            preview: SharePreview(report.fileName, image: Image(systemName: "doc.richtext"))
          ) {
            Label("PDF", systemImage: "doc.richtext")
          }
          ShareLink(
            item: ReportCSVFile(report: report),
            preview: SharePreview(report.fileName, image: Image(systemName: "tablecells"))
          ) {
            Label("Spreadsheet (CSV)", systemImage: "tablecells")
          }
        }
        .disabled(report.isEmpty)
      }
    }
    .onChange(of: scenePhase) {
      // Siri can add invoices while Skyway is in the background.
      if scenePhase == .active {
        invoices = InvoiceStore.invoices
      }
    }
  }

  private func monthSwitcher(_ report: MonthlyReport) -> some View {
    HStack {
      Button("Previous Month", systemImage: "chevron.left") {
        moveMonth(by: -1)
      }
      Spacer()
      Text(report.title)
        .font(.headline)
        .contentTransition(.numericText())
      Spacer()
      Button("Next Month", systemImage: "chevron.right") {
        moveMonth(by: 1)
      }
      .disabled(isCurrentMonth)
    }
    .labelStyle(.iconOnly)
    .buttonStyle(.borderless)
  }

  private func summarySection(_ report: MonthlyReport) -> some View {
    Section {
      LabeledContent("Spent", value: MonthlyReport.text(for: report.expenseTotals))
      if !report.taxTotals.isEmpty {
        LabeledContent("Tax Included", value: MonthlyReport.text(for: report.taxTotals))
      }
      LabeledContent("Invoiced", value: MonthlyReport.usd(report.invoicedTotal))
      LabeledContent(
        "Business Miles",
        value: "\(report.businessMiles.formatted(.number.precision(.fractionLength(1)))) mi"
      )
      LabeledContent("Mileage Deduction", value: MonthlyReport.usd(report.mileageDeduction))
    } header: {
      Text("Summary")
    } footer: {
      if report.unclassifiedTripCount > 0 {
        Text("^[\(report.unclassifiedTripCount) trip](inflect: true) isn't marked business or personal yet, so it isn't counted.")
      }
    }
    .monospacedDigit()
  }

  @ViewBuilder
  private func categorySection(_ report: MonthlyReport) -> some View {
    if !report.categoryTotals.isEmpty {
      Section("Spending by Category") {
        ForEach(report.categoryTotals) { total in
          LabeledContent {
            Text(MonthlyReport.text(for: total.amounts))
              .monospacedDigit()
          } label: {
            Label(total.category.title, systemImage: total.category.systemImage)
          }
        }
      }
    }
  }

  @ViewBuilder
  private func invoiceSection(_ report: MonthlyReport) -> some View {
    if !report.invoices.isEmpty {
      Section("Invoices") {
        ForEach(report.invoices) { invoice in
          InvoiceRow(invoice: invoice)
        }
      }
    }
  }

  @ViewBuilder
  private func tripSection(_ report: MonthlyReport) -> some View {
    if !report.businessTrips.isEmpty {
      Section("Business Trips") {
        ForEach(report.businessTrips) { trip in
          LabeledContent {
            Text(trip.deductionText)
              .monospacedDigit()
          } label: {
            Text(trip.routeText)
              .lineLimit(1)
            Text("\(trip.startDate.formatted(date: .abbreviated, time: .omitted)) · \(trip.milesText)")
          }
        }
      }
    }
  }

  private func moveMonth(by months: Int) {
    guard let date = Calendar.current.date(byAdding: .month, value: months, to: monthStart) else { return }
    withAnimation(.snappy) {
      monthStart = MonthlyReport.interval(containing: date).start
    }
  }
}
