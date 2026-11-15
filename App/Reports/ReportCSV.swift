import Foundation

/// The report as one spreadsheet table: every expense, business trip and invoice in the month,
/// with a Type column to filter by. Opens in Numbers, Excel, or Google Sheets.
enum ReportCSV {
  static let header = ["Type", "Date", "Description", "Category", "Amount", "Currency", "Tax", "Miles", "Notes"]

  static func make(_ report: MonthlyReport) -> String {
    var rows = [header]
    for expense in report.expenses {
      rows.append([
        "Expense", day(expense.date), expense.supplier, expense.category.title,
        number(expense.total), expense.currencyCode, number(expense.tax), "", expense.notes,
      ])
    }
    for trip in report.businessTrips {
      rows.append([
        "Mileage", day(trip.startDate), trip.routeText, "Business",
        number(trip.deduction), "USD", "", number(trip.miles, digits: 1),
        "\(trip.ratePerMileText) IRS rate",
      ])
    }
    for invoice in report.invoices {
      rows.append([
        "Invoice", day(invoice.createdAt), "\(invoice.number) \(invoice.clientName)", invoice.service,
        number(invoice.amount), "USD", "", "", invoiceNote(invoice),
      ])
    }
    // CRLF line endings, as RFC 4180 asks and Excel expects.
    return rows.map { $0.map(escape).joined(separator: ",") }.joined(separator: "\r\n") + "\r\n"
  }

  /// "Paid 2026-11-20", or the status and due date while it's unpaid.
  private static func invoiceNote(_ invoice: Invoice) -> String {
    if let paidAt = invoice.paidAt, invoice.status == .paid {
      return "Paid \(day(paidAt))"
    }
    return "\(invoice.paymentState().title), due \(day(invoice.dueDate))"
  }

  /// Quotes a field that has a comma, quote or line break, doubling any quotes inside it.
  static func escape(_ field: String) -> String {
    guard field.contains(where: { $0 == "," || $0 == "\"" || $0.isNewline }) else { return field }
    return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
  }

  /// "2026-11-12", in the person's time zone: unambiguous, and sorts correctly as text.
  private static func day(_ date: Date) -> String {
    Date.ISO8601FormatStyle(timeZone: .current).year().month().day().format(date)
  }

  /// Plain digits with a period, like 1204.50, so every spreadsheet reads it as a number.
  private static func number(_ value: Double, digits: Int = 2) -> String {
    String(format: "%.\(digits)f", locale: Locale(identifier: "en_US_POSIX"), value)
  }
}
