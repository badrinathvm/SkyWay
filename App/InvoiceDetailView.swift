import SwiftUI

/// An invoice's details, opened from the View Invoice button in Siri.
struct InvoiceDetailView: View {
  var invoice: Invoice
  @Environment(\.dismiss) private var dismiss
  @State private var isConfirmingDelete = false

  var body: some View {
    NavigationStack {
      List {
        Section {
          InvoiceCard(
            number: invoice.number,
            clientName: invoice.clientName,
            service: invoice.service,
            amount: invoice.amount,
            dueDate: invoice.dueDate,
            issuedDate: invoice.createdAt,
            status: .saved
          )
          .padding(-12)
          .listRowInsets(EdgeInsets())
          .listRowBackground(Color.clear)
        }

        Section("Details") {
          LabeledContent("Client", value: invoice.clientName)
          LabeledContent("Service", value: invoice.service.prefix(1).uppercased() + invoice.service.dropFirst())
          LabeledContent("Amount", value: invoice.amountText)
          LabeledContent("Issued", value: invoice.createdAt.formatted(date: .long, time: .shortened))
          LabeledContent("Due", value: invoice.dueDate.formatted(date: .long, time: .omitted))
          LabeledContent("Payment terms", value: "Net \(Invoice.paymentTermDays)")
        }

        Section {
          Button("Delete Invoice", systemImage: "trash", role: .destructive) {
            isConfirmingDelete = true
          }
          .foregroundStyle(.red)
          .confirmationDialog("Delete \(invoice.number)?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Delete Invoice", role: .destructive) {
              InvoiceStore.deleteInvoice(id: invoice.id)
              dismiss()
            }
          } message: {
            Text("The \(invoice.amountText) invoice for \(invoice.clientName) will be removed.")
          }
        }
      }
      .navigationTitle(invoice.number)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Done", systemImage: "xmark") {
            dismiss()
          }
        }
        ToolbarItem(placement: .primaryAction) {
          ShareLink(item: invoice.shareText, subject: Text("Invoice \(invoice.number)")) {
            Label("Share", systemImage: "square.and.arrow.up")
          }
        }
      }
    }
  }
}

extension Invoice {
  /// A plain-text version of the invoice for Messages or Mail.
  var shareText: String {
    """
    Invoice \(number)
    Bill to: \(clientName)
    \(service.prefix(1).uppercased() + service.dropFirst()): \(amountText)
    Total due: \(amountText) by \(dueDate.formatted(date: .long, time: .omitted))
    """
  }
}
