import SwiftUI

/// One invoice in a list: the client, the invoice number and service, the amount and due date.
struct InvoiceRow: View {
  var invoice: Invoice

  var body: some View {
    let theme = InvoiceTheme(service: invoice.service)
    HStack(spacing: 12) {
      Image(systemName: theme.symbol)
        .font(.body.weight(.semibold))
        .foregroundStyle(theme.color)
        .frame(width: 36, height: 36)
        .background(theme.color.opacity(0.15), in: .circle)
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 2) {
        Text(invoice.clientName)
          .font(.body.weight(.medium))
          .lineLimit(1)
        Text("\(invoice.number) · \(invoice.service.prefix(1).uppercased() + invoice.service.dropFirst())")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }

      Spacer(minLength: 8)

      VStack(alignment: .trailing, spacing: 2) {
        Text(invoice.amountText)
          .font(.body.weight(.semibold))
          .monospacedDigit()
        Text("Due \(invoice.dueDate.formatted(.dateTime.month(.abbreviated).day()))")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
    .accessibilityElement(children: .combine)
  }
}
