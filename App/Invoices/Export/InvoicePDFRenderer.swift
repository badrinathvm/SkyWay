import UIKit

/// Draws one invoice as a US Letter page: who it's from and to, the number and dates, the
/// line item and total, how to pay, and a PAID stamp once it's paid.
struct InvoicePDFRenderer {
  var invoice: Invoice
  var business: BusinessProfile

  private static let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
  private static let margin: CGFloat = 56
  private static var width: CGFloat { pageRect.width - margin * 2 }

  func render() -> Data {
    let format = UIGraphicsPDFRendererFormat()
    format.documentInfo = [
      kCGPDFContextTitle as String: "Invoice \(invoice.number)",
      kCGPDFContextAuthor as String: business.name,
      kCGPDFContextCreator as String: "Skyway",
    ]
    return UIGraphicsPDFRenderer(bounds: Self.pageRect, format: format).pdfData { context in
      context.beginPage()
      draw()
    }
  }

  private func draw() {
    let margin = Self.margin
    let accent = UIColor(InvoiceTheme(service: invoice.service).color)

    // A colored band across the top, in the service's theme color.
    accent.setFill()
    UIRectFill(CGRect(x: 0, y: 0, width: Self.pageRect.width, height: 8))

    // Title and number on the left, the sender on the right.
    var y: CGFloat = 52
    draw("INVOICE", at: CGPoint(x: margin, y: y), font: .systemFont(ofSize: 28, weight: .heavy), color: accent)
    draw(invoice.number, at: CGPoint(x: margin, y: y + 36), font: .monospacedSystemFont(ofSize: 13, weight: .medium), color: .darkGray)

    let from = [business.name, business.address, business.email]
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .joined(separator: "\n")
    if !from.isEmpty {
      drawBlock(from, in: CGRect(x: margin + Self.width / 2, y: y + 4, width: Self.width / 2, height: 90), font: .systemFont(ofSize: 11), alignment: .right)
    }

    // Bill to, and the dates.
    y = 150
    drawLabel("BILL TO", at: CGPoint(x: margin, y: y))
    draw(invoice.clientName, at: CGPoint(x: margin, y: y + 16), font: .systemFont(ofSize: 15, weight: .semibold))

    let dates = [
      ("ISSUED", day(invoice.createdAt)),
      ("DUE", day(invoice.dueDate)),
      ("TERMS", "Net \(Invoice.paymentTermDays)"),
    ]
    for (index, (label, value)) in dates.enumerated() {
      let x = margin + Self.width / 2 + CGFloat(index) * (Self.width / 6)
      drawLabel(label, at: CGPoint(x: x, y: y))
      draw(value, at: CGPoint(x: x, y: y + 16), font: .systemFont(ofSize: 11, weight: .medium))
    }

    // The line item table.
    y = 230
    drawRule(at: y, weight: 1, color: .darkGray)
    drawLabel("DESCRIPTION", at: CGPoint(x: margin, y: y + 8))
    drawBlock("AMOUNT", in: CGRect(x: margin, y: y + 8, width: Self.width, height: 14), font: .systemFont(ofSize: 9, weight: .semibold), color: .gray, alignment: .right)
    y += 30
    let service = invoice.service.prefix(1).uppercased() + invoice.service.dropFirst()
    draw(service, at: CGPoint(x: margin, y: y), font: .systemFont(ofSize: 13))
    drawBlock(invoice.amountText, in: CGRect(x: margin, y: y, width: Self.width, height: 18), font: .systemFont(ofSize: 13), alignment: .right)
    y += 30
    drawRule(at: y, weight: 0.5, color: .lightGray)

    // The total.
    y += 14
    drawBlock("Total Due", in: CGRect(x: margin + Self.width / 2, y: y + 4, width: Self.width / 4, height: 20), font: .systemFont(ofSize: 13, weight: .semibold))
    drawBlock(
      invoice.status == .paid ? Invoice.format(0) : invoice.amountText,
      in: CGRect(x: margin, y: y, width: Self.width, height: 28),
      font: .systemFont(ofSize: 22, weight: .bold), alignment: .right
    )
    if let paidAt = invoice.paidAt, invoice.status == .paid {
      drawBlock(
        "\(invoice.amountText) paid \(day(paidAt))",
        in: CGRect(x: margin, y: y + 30, width: Self.width, height: 16),
        font: .systemFont(ofSize: 10), color: .gray, alignment: .right
      )
    }

    // How to pay.
    let instructions = business.paymentInstructions.trimmingCharacters(in: .whitespacesAndNewlines)
    if !instructions.isEmpty, invoice.status != .paid {
      y += 80
      drawLabel("HOW TO PAY", at: CGPoint(x: margin, y: y))
      drawBlock(instructions, in: CGRect(x: margin, y: y + 16, width: Self.width, height: 80), font: .systemFont(ofSize: 11))
    }

    if invoice.status == .paid {
      drawPaidStamp(center: CGPoint(x: Self.pageRect.midX + 40, y: 420))
    }

    // Footer.
    drawBlock(
      "Thank you for your business.",
      in: CGRect(x: margin, y: Self.pageRect.height - margin - 14, width: Self.width, height: 14),
      font: .systemFont(ofSize: 10), color: .gray, alignment: .center
    )
  }

  // MARK: - Drawing helpers

  private func day(_ date: Date) -> String {
    date.formatted(date: .abbreviated, time: .omitted)
  }

  private func draw(_ text: String, at point: CGPoint, font: UIFont, color: UIColor = .black) {
    (text as NSString).draw(at: point, withAttributes: [.font: font, .foregroundColor: color])
  }

  private func drawLabel(_ text: String, at point: CGPoint) {
    draw(text, at: point, font: .systemFont(ofSize: 9, weight: .semibold), color: .gray)
  }

  private func drawBlock(
    _ text: String,
    in rect: CGRect,
    font: UIFont,
    color: UIColor = .black,
    alignment: NSTextAlignment = .left
  ) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    (text as NSString).draw(
      with: rect,
      options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine],
      attributes: [.font: font, .foregroundColor: color, .paragraphStyle: paragraph],
      context: nil
    )
  }

  private func drawRule(at y: CGFloat, weight: CGFloat, color: UIColor) {
    let path = UIBezierPath()
    path.move(to: CGPoint(x: Self.margin, y: y))
    path.addLine(to: CGPoint(x: Self.margin + Self.width, y: y))
    path.lineWidth = weight
    color.setStroke()
    path.stroke()
  }

  /// A tilted green PAID stamp, like a rubber stamp on paper.
  private func drawPaidStamp(center: CGPoint) {
    guard let context = UIGraphicsGetCurrentContext() else { return }
    context.saveGState()
    context.translateBy(x: center.x, y: center.y)
    context.rotate(by: -.pi / 12)
    let green = UIColor.systemGreen.withAlphaComponent(0.75)
    let box = CGRect(x: -80, y: -28, width: 160, height: 56)
    let border = UIBezierPath(roundedRect: box, cornerRadius: 8)
    border.lineWidth = 4
    green.setStroke()
    border.stroke()
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    ("PAID" as NSString).draw(
      in: box.insetBy(dx: 0, dy: 8),
      withAttributes: [
        .font: UIFont.systemFont(ofSize: 32, weight: .black),
        .foregroundColor: green,
        .paragraphStyle: paragraph,
        .kern: 6,
      ]
    )
    context.restoreGState()
  }
}
