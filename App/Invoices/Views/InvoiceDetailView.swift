import SwiftUI

/// An invoice's details and where it stands, with actions to mark it sent or paid and to
/// share it as a PDF. Opened from the Invoices tab, a payment reminder, or Siri.
struct InvoiceDetailView: View {
  @State private var invoice: Invoice
  @Environment(\.dismiss) private var dismiss
  @State private var isConfirmingDelete = false
  @State private var isEditingBusiness = false
  @State private var areRemindersDenied = false
  @AppStorage(BusinessProfile.Key.name) private var businessName = ""

  init(invoice: Invoice) {
    _invoice = State(initialValue: invoice)
  }

  private var state: Invoice.PaymentState { invoice.paymentState() }

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
            status: .saved(state)
          )
          .padding(-12)
          .listRowInsets(EdgeInsets())
          .listRowBackground(Color.clear)
        }

        statusSection

        Section("Details") {
          LabeledContent("Client", value: invoice.clientName)
          LabeledContent("Service", value: invoice.service.prefix(1).uppercased() + invoice.service.dropFirst())
          LabeledContent("Amount", value: invoice.amountText)
          LabeledContent("Issued", value: invoice.createdAt.formatted(date: .long, time: .shortened))
          LabeledContent("Due", value: invoice.dueDate.formatted(date: .long, time: .omitted))
          LabeledContent("Payment terms", value: "Net \(Invoice.paymentTermDays)")
        }

        if businessName.isEmpty {
          Section {
            Button("Add Business Details", systemImage: "building.2") {
              isEditingBusiness = true
            }
          } footer: {
            Text("Your name and how to pay appear on the invoice PDF.")
          }
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
          Menu("Share", systemImage: "square.and.arrow.up") {
            ShareLink(
              item: InvoicePDFFile(invoice: invoice),
              preview: SharePreview("Invoice \(invoice.number)", image: Image(systemName: "doc.richtext"))
            ) {
              Label("PDF", systemImage: "doc.richtext")
            }
            ShareLink(item: invoice.shareText, subject: Text("Invoice \(invoice.number)")) {
              Label("Text", systemImage: "text.alignleft")
            }
          }
        }
      }
      .sheet(isPresented: $isEditingBusiness) {
        BusinessProfileView()
      }
      .sensoryFeedback(.success, trigger: invoice.status)
      .task(id: invoice.status) {
        areRemindersDenied = await InvoiceReminders.areDenied()
      }
    }
  }

  private var statusSection: some View {
    Section {
      LabeledContent("Status") {
        HStack(spacing: 6) {
          Image(systemName: state.systemImage)
            .accessibilityHidden(true)
          Text(state.title)
        }
        .foregroundStyle(state.color)
      }
      if let sentAt = invoice.sentAt {
        LabeledContent("Sent", value: sentAt.formatted(date: .abbreviated, time: .omitted))
      }
      if let paidAt = invoice.paidAt {
        LabeledContent("Paid", value: paidAt.formatted(date: .abbreviated, time: .omitted))
      }
      statusButton
    } header: {
      Text("Payment")
    } footer: {
      statusFooter
    }
  }

  @ViewBuilder
  private var statusButton: some View {
    switch invoice.status {
    case .draft:
      Button("Mark as Sent", systemImage: "paperplane") {
        Task {
          // Ask now, when it's clear what reminders are for.
          await InvoiceReminders.requestAuthorizationIfNeeded()
          change(InvoiceStore.markSent(id: invoice.id))
        }
      }
    case .sent:
      Button("Mark as Paid", systemImage: "checkmark.circle") {
        change(InvoiceStore.markPaid(id: invoice.id))
      }
    case .paid:
      Button("Mark as Unpaid", systemImage: "arrow.uturn.backward") {
        change(InvoiceStore.markUnpaid(id: invoice.id))
      }
    }
  }

  @ViewBuilder
  private var statusFooter: some View {
    switch invoice.status {
    case .draft:
      Text("Mark it sent once you've shared it with \(invoice.clientName), and Skyway reminds you when payment is due.")
    case .sent where areRemindersDenied:
      Text("Notifications are off for Skyway, so there won't be a payment reminder. Turn them on in Settings › Apps › Skyway › Notifications.")
    case .sent:
      Text("Skyway reminds you on \(invoice.dueDate.formatted(date: .abbreviated, time: .omitted)) and again 3 days later if it's still unpaid.")
    case .paid:
      EmptyView()
    }
  }

  private func change(_ updated: Invoice?) {
    guard let updated else { return }
    withAnimation(.snappy) {
      invoice = updated
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
