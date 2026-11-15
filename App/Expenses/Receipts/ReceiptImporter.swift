import SwiftData
import UIKit

/// Turns scanned pages or photos into saved expenses, reading each receipt as it goes.
@MainActor
@Observable
final class ReceiptImporter {
  /// How many receipts are left to read, for the progress overlay. Zero when idle.
  private(set) var remainingCount = 0
  var errorMessage: String?

  var isReading: Bool { remainingCount > 0 }

  private let reader = ReceiptReader()

  /// Reads each receipt (each one a list of pages) and saves an expense for it.
  /// Returns the new expenses, in the order given.
  func importReceipts(_ receipts: [[UIImage]], into context: ModelContext) async -> [Expense] {
    remainingCount = receipts.count
    defer { remainingCount = 0 }

    var imported: [Expense] = []
    var failures = 0
    for pages in receipts where !pages.isEmpty {
      let pages = pages.map { $0.normalizedForReceipt() }
      do {
        let reading = try await reader.read(pages)
        let expense = Expense(
          supplier: reading.supplier,
          date: reading.date ?? .now,
          total: reading.total,
          tax: reading.tax,
          currencyCode: reading.currencyCode,
          // Filed the way the person filed this supplier before, over the model's guess.
          category: SupplierCategoryRules.category(for: reading.supplier) ?? reading.category,
          receiptFileNames: pages.compactMap(ReceiptImageStore.save),
          recognizedText: reading.text
        )
        context.insert(expense)
        imported.append(expense)
      } catch {
        failures += 1
        if receipts.count == 1 {
          errorMessage = error.localizedDescription
        }
      }
      remainingCount -= 1
    }
    try? context.save()
    ExpenseStore.index(imported)

    if receipts.count > 1, failures > 0 {
      errorMessage = failures == 1
        ? "One receipt couldn't be read. Try a sharper, well-lit photo."
        : "\(failures) receipts couldn't be read. Try sharper, well-lit photos."
    }
    return imported
  }
}
