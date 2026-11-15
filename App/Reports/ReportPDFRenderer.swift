import UIKit

/// Draws the report as a US Letter PDF: a summary, then tables of expenses, business trips and
/// invoices, starting a new page whenever the current one fills up.
struct ReportPDFRenderer {
  var report: MonthlyReport

  private static let pageSize = CGSize(width: 612, height: 792)
  private static let margin: CGFloat = 48
  private static var contentWidth: CGFloat { pageSize.width - margin * 2 }

  func render() -> Data {
    let format = UIGraphicsPDFRendererFormat()
    format.documentInfo = [
      kCGPDFContextTitle as String: "Skyway Report, \(report.title)",
      kCGPDFContextCreator as String: "Skyway",
    ]
    let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: Self.pageSize), format: format)
    return renderer.pdfData { context in
      var page = Page(context: context)
      page.begin()
      drawHeader(on: &page)
      drawSummary(on: &page)
      drawExpenses(on: &page)
      drawTrips(on: &page)
      drawInvoices(on: &page)
    }
  }

  // MARK: - Sections

  private func drawHeader(on page: inout Page) {
    page.text("Skyway Monthly Report", font: .systemFont(ofSize: 22, weight: .bold))
    page.text(report.title, font: .systemFont(ofSize: 15, weight: .medium), color: .darkGray)
    page.text(
      "Created \(Date.now.formatted(date: .long, time: .shortened))",
      font: .systemFont(ofSize: 10), color: .gray
    )
    page.space(18)
  }

  private func drawSummary(on page: inout Page) {
    page.sectionTitle("Summary")
    page.row(["Spent", MonthlyReport.text(for: report.expenseTotals)], widths: [0.4, 0.6], alignRight: [1])
    if !report.taxTotals.isEmpty {
      page.row(["Tax included", MonthlyReport.text(for: report.taxTotals)], widths: [0.4, 0.6], alignRight: [1])
    }
    page.row(["Invoiced", MonthlyReport.usd(report.invoicedTotal)], widths: [0.4, 0.6], alignRight: [1])
    page.row(
      ["Business miles", "\(report.businessMiles.formatted(.number.precision(.fractionLength(1)))) mi"],
      widths: [0.4, 0.6], alignRight: [1]
    )
    page.row(["Mileage deduction", MonthlyReport.usd(report.mileageDeduction)], widths: [0.4, 0.6], alignRight: [1])
    if report.unclassifiedTripCount > 0 {
      page.space(4)
      page.text(
        "\(report.unclassifiedTripCount) trips aren't marked business or personal yet, so they aren't counted.",
        font: .systemFont(ofSize: 9), color: .gray
      )
    }
    page.space(16)

    guard !report.categoryTotals.isEmpty else { return }
    page.sectionTitle("Spending by Category")
    for total in report.categoryTotals {
      page.row([total.category.title, MonthlyReport.text(for: total.amounts)], widths: [0.4, 0.6], alignRight: [1])
    }
    page.space(16)
  }

  private static let tableWidths: [CGFloat] = [0.16, 0.38, 0.24, 0.22]

  private func drawExpenses(on page: inout Page) {
    guard !report.expenses.isEmpty else { return }
    page.sectionTitle("Expenses")
    page.row(["Date", "Supplier", "Category", "Total"], widths: Self.tableWidths, alignRight: [3], isHeader: true)
    for expense in report.expenses {
      page.row(
        [day(expense.date), expense.supplier, expense.category.title, expense.total.formatted(.currency(code: expense.currencyCode))],
        widths: Self.tableWidths, alignRight: [3]
      )
    }
    page.space(16)
  }

  private func drawTrips(on page: inout Page) {
    guard !report.businessTrips.isEmpty else { return }
    page.sectionTitle("Business Trips")
    page.row(["Date", "Route", "Miles", "Deduction"], widths: Self.tableWidths, alignRight: [2, 3], isHeader: true)
    for trip in report.businessTrips {
      page.row(
        [day(trip.startDate), trip.routeText, trip.milesText, trip.deductionText],
        widths: Self.tableWidths, alignRight: [2, 3]
      )
    }
    page.space(16)
  }

  private func drawInvoices(on page: inout Page) {
    guard !report.invoices.isEmpty else { return }
    page.sectionTitle("Invoices")
    page.row(["Issued", "Client", "Invoice", "Amount"], widths: Self.tableWidths, alignRight: [3], isHeader: true)
    for invoice in report.invoices {
      page.row(
        [day(invoice.createdAt), invoice.clientName, invoice.number, invoice.amountText],
        widths: Self.tableWidths, alignRight: [3]
      )
    }
  }

  private func day(_ date: Date) -> String {
    date.formatted(date: .abbreviated, time: .omitted)
  }

  // MARK: - Layout

  /// Where the next line goes, and the page break when there's no room for it.
  private struct Page {
    var context: UIGraphicsPDFRendererContext
    var y: CGFloat = 0

    private var bottom: CGFloat { ReportPDFRenderer.pageSize.height - ReportPDFRenderer.margin }

    mutating func begin() {
      context.beginPage()
      y = ReportPDFRenderer.margin
    }

    mutating func space(_ height: CGFloat) {
      y += height
    }

    mutating func text(_ string: String, font: UIFont, color: UIColor = .black) {
      let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
      let bounds = (string as NSString).boundingRect(
        with: CGSize(width: ReportPDFRenderer.contentWidth, height: .greatestFiniteMagnitude),
        options: .usesLineFragmentOrigin, attributes: attributes, context: nil
      )
      makeRoom(for: bounds.height)
      (string as NSString).draw(
        in: CGRect(x: ReportPDFRenderer.margin, y: y, width: ReportPDFRenderer.contentWidth, height: bounds.height),
        withAttributes: attributes
      )
      y += ceil(bounds.height) + 2
    }

    mutating func sectionTitle(_ title: String) {
      // Keep a title with at least two rows below it.
      makeRoom(for: 60)
      text(title, font: .systemFont(ofSize: 13, weight: .semibold))
      y += 2
    }

    /// One line of a table. Each cell is cut short with "…" rather than wrapped, so rows line up.
    mutating func row(_ cells: [String], widths: [CGFloat], alignRight: Set<Int> = [], isHeader: Bool = false) {
      let height: CGFloat = 18
      makeRoom(for: height)
      let font = UIFont.systemFont(ofSize: 10, weight: isHeader ? .semibold : .regular)
      var x = ReportPDFRenderer.margin
      for (index, cell) in cells.enumerated() {
        let width = ReportPDFRenderer.contentWidth * widths[index]
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignRight.contains(index) ? .right : .left
        paragraph.lineBreakMode = .byTruncatingTail
        let attributes: [NSAttributedString.Key: Any] = [
          .font: font,
          .foregroundColor: isHeader ? UIColor.darkGray : UIColor.black,
          .paragraphStyle: paragraph,
        ]
        (cell as NSString).draw(in: CGRect(x: x, y: y + 3, width: width - 6, height: height - 3), withAttributes: attributes)
        x += width
      }
      // A hairline under each row.
      let line = UIBezierPath()
      line.move(to: CGPoint(x: ReportPDFRenderer.margin, y: y + height))
      line.addLine(to: CGPoint(x: ReportPDFRenderer.margin + ReportPDFRenderer.contentWidth, y: y + height))
      line.lineWidth = isHeader ? 0.75 : 0.25
      (isHeader ? UIColor.darkGray : UIColor.lightGray).setStroke()
      line.stroke()
      y += height
    }

    private mutating func makeRoom(for height: CGFloat) {
      if y + height > bottom {
        begin()
      }
    }
  }
}
