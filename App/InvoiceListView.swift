import SwiftUI

/// Every invoice, newest first. Invoices are created with Siri, so the list refreshes whenever
/// Skyway comes back to the foreground.
struct InvoiceListView: View {
  @State private var invoices: [Invoice] = []
  @State private var selectedInvoice: Invoice?
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
        ToolbarItem(placement: .primaryAction) {
          NavigationLink(value: InvoiceListRoute.monthlyReport) {
            Label("Monthly Report", systemImage: "chart.bar.doc.horizontal")
          }
        }
      }
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
          Text("Invoiced in \(Date.now.formatted(.dateTime.month(.wide)))")
            .font(.subheadline)
            .foregroundStyle(.secondary)
          Text(MonthlyReport.usd(invoicedThisMonth))
            .font(.largeTitle.weight(.bold))
            .monospacedDigit()
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
