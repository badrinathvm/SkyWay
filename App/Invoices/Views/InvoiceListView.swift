import SwiftUI

/// Every invoice, newest first. Invoices are created with Siri, so the list refreshes whenever
/// Skyway comes back to the foreground.
struct InvoiceListView: View {
  @State private var invoices: [Invoice] = []
  @State private var selectedInvoice: Invoice?
  @State private var isEditingBusiness = false
  @Environment(\.scenePhase) private var scenePhase

  var body: some View {
    NavigationStack {
      Group {
        if invoices.isEmpty {
          ContentUnavailableView {
            Label("No Invoices", systemImage: "doc.text")
          } description: {
            Text("Ask Siri, “Bill John Appleseed $450 for gardening in Skyway.”")
          }
        } else {
          list
        }
      }
      .navigationTitle("Invoices")
      .navigationDestination(for: InvoiceListRoute.self) { _ in
        MonthlyReportView()
      }
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Business Details", systemImage: "building.2") {
            isEditingBusiness = true
          }
        }
        ToolbarItem(placement: .primaryAction) {
          NavigationLink(value: InvoiceListRoute.monthlyReport) {
            Label("Monthly Report", systemImage: "chart.bar.doc.horizontal")
          }
        }
      }
    }
    .sheet(isPresented: $isEditingBusiness) {
      BusinessProfileView()
    }
    .sheet(item: $selectedInvoice, onDismiss: reload) { invoice in
      InvoiceDetailView(invoice: invoice)
    }
    .onAppear(perform: reload)
    .onChange(of: scenePhase) {
      if scenePhase == .active {
        reload()
      }
    }
  }

  private var list: some View {
    List {
      Section {
        VStack(alignment: .leading, spacing: 4) {
          Text("Waiting to Be Paid")
            .font(.subheadline)
            .foregroundStyle(.secondary)
          Text(MonthlyReport.usd(total(of: outstanding)))
            .font(.largeTitle.weight(.bold))
            .monospacedDigit()
            .contentTransition(.numericText())
          if !overdue.isEmpty {
            Label("\(MonthlyReport.usd(total(of: overdue))) overdue", systemImage: "exclamationmark.circle.fill")
              .font(.subheadline.weight(.medium))
              .foregroundStyle(.red)
          }
          Text("\(MonthlyReport.usd(invoicedThisMonth)) invoiced in \(Date.now.formatted(.dateTime.month(.wide)))")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
      }

      Section("All Invoices") {
        ForEach(invoices) { invoice in
          Button {
            selectedInvoice = invoice
          } label: {
            InvoiceRow(invoice: invoice)
              .contentShape(.rect)
          }
          .buttonStyle(.plain)
          .accessibilityHint("Shows the invoice.")
        }
        .onDelete { offsets in
          for index in offsets {
            InvoiceStore.deleteInvoice(id: invoices[index].id)
          }
          reload()
        }
      }
    }
  }

  /// Sent, including overdue, and not yet paid.
  private var outstanding: [Invoice] {
    invoices.filter(\.isOutstanding)
  }

  private var overdue: [Invoice] {
    invoices.filter { $0.paymentState() == .overdue }
  }

  private func total(of invoices: [Invoice]) -> Double {
    invoices.reduce(0) { $0 + $1.amount }
  }

  private var invoicedThisMonth: Double {
    let month = MonthlyReport.interval(containing: .now)
    return invoices.filter { month.contains($0.createdAt) }.reduce(0) { $0 + $1.amount }
  }

  private func reload() {
    invoices = InvoiceStore.invoices
  }
}

/// Screens pushed from the invoice list.
private enum InvoiceListRoute: Hashable {
  case monthlyReport
}
