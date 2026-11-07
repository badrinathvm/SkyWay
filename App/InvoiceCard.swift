import AppIntents
import SwiftUI

/// An invoice as Siri shows it, styled like a printed receipt: a themed header, the line item,
/// a timeline to the due date, a rubber stamp for its status, and a torn bottom edge.
struct InvoiceCard: View {
  var number: String
  var clientName: String
  var service: String
  var amount: Double
  var dueDate: Date
  var issuedDate: Date = .now
  var status: Status

  enum Status {
    /// In Siri, waiting for the person to confirm.
    case draft
    /// In Siri, just created, with View Invoice and Undo buttons.
    case created(Invoice)
    /// In the app, where there's nothing to confirm or undo.
    case saved
    /// Undone from Siri.
    case deleted
  }

  private var theme: InvoiceTheme { InvoiceTheme(service: service) }

  /// Voided invoices turn gray. Siri doesn't draw `saturation`, so the color itself changes.
  private var color: Color { isDeleted ? .gray : theme.color }

  var body: some View {
    VStack(spacing: 0) {
      header
      VStack(alignment: .leading, spacing: 14) {
        billTo
        lineItem
        DueTimeline(issued: issuedDate, due: dueDate, color: color)
        footer
      }
      .padding(.horizontal, 16)
      .padding(.top, 14)
      .padding(.bottom, 20)
    }
    .background(.background, in: TornEdge())
    .clipShape(TornEdge())
    .overlay(alignment: .topTrailing) {
      StatusStamp(status: status)
        .offset(x: -16, y: 90)
    }
    .padding(12)
  }

  private var header: some View {
    ZStack(alignment: .leading) {
      LinearGradient(colors: [color, color.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing)
      Image(systemName: theme.symbol)
        .font(.system(size: 96, weight: .bold))
        .foregroundStyle(.white.opacity(0.18))
        .rotationEffect(.degrees(-15))
        .frame(maxWidth: .infinity, alignment: .trailing)
        .offset(x: 18, y: 10)
        .accessibilityHidden(true)
      HStack(alignment: .bottom) {
        VStack(alignment: .leading, spacing: 2) {
          Text("INVOICE")
            .font(.caption2.weight(.heavy))
            .tracking(3)
            .opacity(0.8)
          Text(number)
            .font(.headline.monospaced())
        }
        Spacer()
        Text(Invoice.format(amount))
          .font(.system(.largeTitle, design: .rounded, weight: .bold))
          .monospacedDigit()
          .minimumScaleFactor(0.6)
          .lineLimit(1)
      }
      .foregroundStyle(.white)
      .padding(16)
    }
    .frame(height: 80)
    .clipped()
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Invoice \(number), \(Invoice.format(amount))")
  }

  private var billTo: some View {
    HStack(spacing: 12) {
      Text(initials)
        .font(.system(.headline, design: .rounded, weight: .bold))
        .foregroundStyle(.white)
        .frame(width: 44, height: 44)
        .background(color.gradient, in: .circle)
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 2) {
        Text("BILL TO")
          .font(.caption2.weight(.semibold))
          .tracking(1.5)
          .foregroundStyle(.secondary)
        Text(clientName)
          .font(.title3.bold())
      }
    }
    .accessibilityElement(children: .combine)
  }

  private var lineItem: some View {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
      Label(service.prefix(1).uppercased() + service.dropFirst(), systemImage: theme.symbol)
        .font(.body.weight(.medium))
        .labelStyle(ThemedLabelStyle(color: color))
        .fixedSize()
      DottedLeader()
        .stroke(.tertiary, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [0.1, 5]))
        .frame(height: 1)
        .accessibilityHidden(true)
      Text(Invoice.format(amount))
        .font(.body.weight(.semibold))
        .monospacedDigit()
        .fixedSize()
    }
    .accessibilityElement(children: .combine)
  }

  @ViewBuilder
  private var footer: some View {
    switch status {
    case .draft:
      Label("Check the details, then create it below", systemImage: "hand.point.down.fill")
        .font(.footnote)
        .foregroundStyle(.secondary)
    case .created(let invoice):
      HStack {
        // A link rather than an intent button: Siri and Spotlight open the app for links.
        Link(destination: invoice.url) {
          Label("View Invoice", systemImage: "arrow.up.forward.app")
        }
        .buttonStyle(.borderedProminent)
        Spacer()
        Button(intent: DeleteInvoiceIntent(invoiceID: invoice.id)) {
          Label("Undo", systemImage: "arrow.uturn.backward")
        }
        .buttonStyle(.bordered)
      }
      .buttonBorderShape(.capsule)
      .tint(color)
    case .saved:
      Label("Saved in Skyway", systemImage: "checkmark.seal.fill")
        .font(.footnote.weight(.semibold))
        .foregroundStyle(.green)
    case .deleted:
      Label("This invoice was voided", systemImage: "xmark.bin.fill")
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
  }

  private var initials: String {
    let letters = clientName.split(separator: " ").prefix(2).compactMap(\.first)
    return letters.isEmpty ? "?" : String(letters).uppercased()
  }

  private var isDeleted: Bool {
    if case .deleted = status { true } else { false }
  }
}

/// A tilted rubber stamp: DRAFT, ISSUED, or VOID.
private struct StatusStamp: View {
  var status: InvoiceCard.Status

  var body: some View {
    Text(title)
      .font(.system(.subheadline, design: .rounded, weight: .black))
      .tracking(2.5)
      .padding(.horizontal, 10)
      .padding(.vertical, 4)
      .overlay {
        RoundedRectangle(cornerRadius: 6)
          .strokeBorder(style: StrokeStyle(lineWidth: 2.5, dash: [14, 1.5]))
      }
      .foregroundStyle(color.opacity(0.85))
      .rotationEffect(.degrees(-12))
      .accessibilityLabel("Status: \(title.lowercased())")
  }

  private var title: String {
    switch status {
    case .draft: "DRAFT"
    case .created, .saved: "ISSUED"
    case .deleted: "VOID"
    }
  }

  private var color: Color {
    switch status {
    case .draft: .orange
    case .created, .saved: .green
    case .deleted: .red
    }
  }
}

/// Today on the left, the due date on the right, joined by a bar.
private struct DueTimeline: View {
  var issued: Date
  var due: Date
  var color: Color

  var body: some View {
    VStack(spacing: 6) {
      HStack(spacing: 6) {
        Circle().fill(color).frame(width: 8, height: 8)
        Capsule()
          .fill(LinearGradient(colors: [color, color.opacity(0.15)], startPoint: .leading, endPoint: .trailing))
          .frame(height: 3)
        Image(systemName: "flag.checkered")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      HStack {
        Text("Issued \(issued.formatted(.dateTime.month(.abbreviated).day()))")
        Spacer()
        Text("Net \(Invoice.paymentTermDays)")
          .foregroundStyle(.tertiary)
        Spacer()
        Text("Due \(due.formatted(.dateTime.month(.abbreviated).day()))")
      }
      .font(.caption.weight(.medium))
      .foregroundStyle(.secondary)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Due \(due.formatted(date: .long, time: .omitted)), \(Invoice.paymentTermDays) days from today")
  }
}

/// Puts the label's icon in a small tinted circle.
private struct ThemedLabelStyle: LabelStyle {
  var color: Color

  func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: 8) {
      configuration.icon
        .font(.caption)
        .foregroundStyle(color)
        .frame(width: 26, height: 26)
        .background(color.opacity(0.15), in: .circle)
      configuration.title
    }
  }
}

/// A horizontal line through the middle, drawn dotted like a receipt's leader.
private struct DottedLeader: Shape {
  func path(in rect: CGRect) -> Path {
    Path { path in
      path.move(to: CGPoint(x: rect.minX, y: rect.midY))
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
    }
  }
}

/// A card with rounded top corners and a zigzag bottom, like paper torn from a receipt roll.
private struct TornEdge: Shape {
  var toothWidth: CGFloat = 12
  var toothHeight: CGFloat = 6
  var cornerRadius: CGFloat = 16

  func path(in rect: CGRect) -> Path {
    Path { path in
      let bottom = rect.maxY - toothHeight
      path.move(to: CGPoint(x: rect.minX, y: bottom))
      path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))
      path.addQuadCurve(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
      path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))
      path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + cornerRadius), control: CGPoint(x: rect.maxX, y: rect.minY))
      path.addLine(to: CGPoint(x: rect.maxX, y: bottom))
      let teeth = max(1, Int(rect.width / toothWidth))
      let step = rect.width / CGFloat(teeth)
      for tooth in 0..<teeth {
        let x = rect.maxX - CGFloat(tooth) * step
        path.addLine(to: CGPoint(x: x - step / 2, y: rect.maxY))
        path.addLine(to: CGPoint(x: x - step, y: bottom))
      }
      path.closeSubpath()
    }
  }
}
