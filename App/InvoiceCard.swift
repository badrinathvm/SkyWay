import AppIntents
import SwiftUI

/// An invoice as Siri shows it: a draft to confirm, a created invoice with Undo, or one that was undone.
struct InvoiceCard: View {
  var number: String
  var clientName: String
  var service: String
  var amount: Double
  var dueDate: Date
  var status: Status

  enum Status {
    case draft
    case created(invoiceID: String)
    case deleted
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(alignment: .firstTextBaseline) {
        Label(number, systemImage: "doc.text.fill")
          .font(.headline)
          .foregroundStyle(.tint)
        Spacer()
        Text(statusTitle)
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
      }

      VStack(alignment: .leading, spacing: 2) {
        Text("Bill to")
          .font(.caption)
          .foregroundStyle(.secondary)
        Text(clientName)
          .font(.title3.bold())
      }
      .accessibilityElement(children: .combine)

      Divider()

      HStack {
        Text(service.prefix(1).uppercased() + service.dropFirst())
        Spacer()
        Text(Invoice.format(amount))
          .monospacedDigit()
      }
      .font(.body)
      .accessibilityElement(children: .combine)

      HStack {
        Text("Total")
          .font(.headline)
        Spacer()
        Text(Invoice.format(amount))
          .font(.title2.bold())
          .monospacedDigit()
      }
      .accessibilityElement(children: .combine)

      footer
    }
    .padding()
    .opacity(isDeleted ? 0.6 : 1)
  }

  @ViewBuilder
  private var footer: some View {
    let due = dueDate.formatted(date: .abbreviated, time: .omitted)
    switch status {
    case .draft:
      Label("Due \(due) · Net \(Invoice.paymentTermDays)", systemImage: "calendar")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    case .created(let invoiceID):
      HStack {
        Label("Created · Due \(due)", systemImage: "checkmark.circle.fill")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.green)
        Spacer()
        Button(intent: DeleteInvoiceIntent(invoiceID: invoiceID)) {
          Label("Undo", systemImage: "arrow.uturn.backward")
        }
        .buttonStyle(.bordered)
      }
    case .deleted:
      Label("Invoice deleted", systemImage: "trash")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
  }

  private var statusTitle: String {
    switch status {
    case .draft: "DRAFT"
    case .created: "CREATED"
    case .deleted: "DELETED"
    }
  }

  private var isDeleted: Bool {
    if case .deleted = status { true } else { false }
  }
}
