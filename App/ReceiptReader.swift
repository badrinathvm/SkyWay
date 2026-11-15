import Foundation
import FoundationModels
import UIKit
import Vision

/// Reads a receipt's pages: Vision recognizes the text on device, then Apple Intelligence
/// picks out the supplier, date, total, tax, currency and category. Where the model can see
/// images, it gets the photos as well as the text: the photo shows the layout (which line is
/// the total, not the subtotal), and the text keeps the numbers exact. When Apple Intelligence
/// isn't available, simple text rules fill in what they can.
struct ReceiptReader {
  /// What was read from one receipt.
  struct Reading {
    var supplier: String
    var date: Date?
    var total: Double
    var tax: Double
    var currencyCode: String
    var category: ExpenseCategory
    var text: String
    var usedAppleIntelligence: Bool
  }

  enum ReadingError: LocalizedError {
    case noText

    var errorDescription: String? {
      switch self {
      case .noText: "No text was found on the receipt. Try a sharper, well-lit photo."
      }
    }
  }

  /// Reads the pages of one receipt, in order. A long receipt photographed in parts is one receipt.
  func read(_ pages: [UIImage]) async throws -> Reading {
    var lines: [String] = []
    for page in pages {
      lines += try await recognizeLines(in: page)
    }
    let text = lines.joined(separator: "\n")
    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw ReadingError.noText
    }

    let rules = Self.readWithRules(text)
    guard SystemLanguageModel.default.isAvailable,
      let extraction = await extract(from: text, pages: pages)
    else {
      return rules
    }
    // The model can do arithmetic it shouldn't, like adding the tax to a total that already
    // includes it. Only trust an amount that's actually printed on the receipt.
    let printedAmounts = Set(text.split(whereSeparator: \.isNewline).flatMap { Self.amounts(in: String($0)) })
    let isPrinted = { (amount: Double) in printedAmounts.contains { abs($0 - amount) < 0.005 } }
    return Reading(
      supplier: extraction.supplier.isEmpty ? rules.supplier : extraction.supplier,
      date: Self.parseISODate(extraction.date) ?? rules.date,
      total: extraction.total > 0 && isPrinted(extraction.total) ? extraction.total : rules.total,
      tax: extraction.tax == 0 || isPrinted(extraction.tax) ? extraction.tax : rules.tax,
      currencyCode: Self.validCurrencyCode(extraction.currencyCode) ?? rules.currencyCode,
      category: extraction.category,
      text: text,
      usedAppleIntelligence: true
    )
  }

  private func recognizeLines(in image: UIImage) async throws -> [String] {
    guard let cgImage = image.cgImage else { return [] }
    var request = RecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    let observations = try await request.perform(on: cgImage)
    return observations.compactMap { $0.topCandidates(1).first?.string }
  }

  /// The most pages sent to the model as images. Later pages of a long receipt still reach it
  /// as text, so a multi-page scan doesn't overflow the model's context.
  private static let maxImagePages = 3

  /// Asks the model for the receipt's details, with the photos when it can see images.
  /// Returns nil if the model couldn't answer, so the text rules are used instead.
  private func extract(from text: String, pages: [UIImage]) async -> ReceiptExtraction? {
    let images = SystemLanguageModel.default.capabilities.contains(.vision)
      ? pages.prefix(Self.maxImagePages).compactMap(\.cgImage)
      : []
    if !images.isEmpty, let extraction = try? await extract(from: text, images: images) {
      return extraction
    }
    // Text alone, for models without vision, or when the request with images failed,
    // such as for exceeding the context size.
    return try? await extract(from: text, images: [])
  }

  private func extract(from text: String, images: [CGImage]) async throws -> ReceiptExtraction {
    let session = LanguageModelSession(instructions: """
      You read purchase receipts. You may get photos of the receipt and the text recognized \
      from them. The recognized text may contain mistakes; use the photo to tell which amount \
      is the total and to correct misread characters. Report only what the receipt shows; \
      don't invent details.
      """)
    // Receipts are short, but a cap keeps a long multi-page scan inside the model's context.
    let response = try await session.respond(generating: ReceiptExtraction.self) {
      if images.isEmpty {
        "Read this receipt."
      } else {
        "Read the receipt in these photos."
        for image in images {
          Attachment(image)
        }
      }
      "Text recognized from the receipt:"
      String(text.prefix(3000))
    }
    return response.content
  }

  // MARK: - Text rules

  /// A reading from patterns in the text alone: the first line is usually the business,
  /// and the total is on a line that says "total" (but not "subtotal").
  static func readWithRules(_ text: String) -> Reading {
    let lines = text.split(whereSeparator: \.isNewline).map { $0.trimmingCharacters(in: .whitespaces) }
    let supplier = lines.first { line in
      line.count > 2 && line.contains(where: \.isLetter) && amounts(in: line).isEmpty
    } ?? ""

    let totalLines = lines.filter {
      let line = $0.lowercased()
      return line.contains("total") && !line.contains("subtotal") && !line.contains("sub total")
    }
    let total = totalLines.flatMap(amounts(in:)).max() ?? lines.flatMap(amounts(in:)).max() ?? 0
    let tax = lines
      .filter { ["tax", "vat", "gst", "hst"].contains(where: $0.lowercased().contains) }
      .flatMap(amounts(in:))
      .first { $0 < total } ?? 0

    return Reading(
      supplier: supplier,
      date: firstDate(in: text),
      total: total,
      tax: tax,
      currencyCode: currencyCode(in: text),
      category: .guess(from: text),
      text: text,
      usedAppleIntelligence: false
    )
  }

  /// Money amounts with two decimal places, like 12.50 or 1,204.99.
  private static func amounts(in line: String) -> [Double] {
    line.matches(of: #/\d{1,3}(?:,\d{3})*[.,]\d{2}(?!\d)/#).compactMap {
      var digits = String($0.output)
      // "12,50" is a European decimal comma; "1,204.99" uses a thousands separator.
      if digits.dropLast(3).contains(",") || digits.contains(".") {
        digits.removeAll { $0 == "," }
      } else {
        digits = digits.replacingOccurrences(of: ",", with: ".")
      }
      return Double(digits)
    }
  }

  private static func firstDate(in text: String) -> Date? {
    guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
      return nil
    }
    let range = NSRange(text.startIndex..., in: text)
    // Ignore dates in the future, like a "return by" date or a misread number.
    return detector.matches(in: text, range: range)
      .compactMap(\.date)
      .first { $0 <= .now.addingTimeInterval(86_400) }
  }

  private static func currencyCode(in text: String) -> String {
    if text.contains("€") || text.contains("EUR") { return "EUR" }
    if text.contains("£") || text.contains("GBP") { return "GBP" }
    if text.contains("₹") || text.contains("INR") { return "INR" }
    if text.contains("¥") || text.contains("JPY") { return "JPY" }
    if text.contains("CAD") { return "CAD" }
    if text.contains("AUD") { return "AUD" }
    return Expense.defaultCurrencyCode
  }

  private static func parseISODate(_ text: String) -> Date? {
    // In the local time zone: "2026-11-12" is the 12th where the purchase was made, not
    // midnight UTC, which is still the 11th in the Americas.
    let strategy = Date.ISO8601FormatStyle(timeZone: .current).year().month().day()
    guard let date = try? Date(text, strategy: strategy) else { return nil }
    return date <= .now.addingTimeInterval(86_400) ? date : nil
  }

  private static func validCurrencyCode(_ code: String) -> String? {
    let code = code.uppercased()
    return Locale.commonISOCurrencyCodes.contains(code) ? code : nil
  }
}
