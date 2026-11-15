import Foundation
import SwiftData

/// Where expenses are saved: a SwiftData store of their own, apart from the trip data.
enum ExpenseStore {
  @MainActor static let container: ModelContainer = {
    let configuration = ModelConfiguration(
      "Expenses",
      url: URL.applicationSupportDirectory.appending(path: "Expenses.store")
    )
    do {
      return try ModelContainer(for: Expense.self, configurations: configuration)
    } catch {
      fatalError("Couldn't open the expenses store: \(error)")
    }
  }()

  /// Removes the expense and its receipt images.
  static func delete(_ expense: Expense, from context: ModelContext) {
    expense.receiptFileNames.forEach(ReceiptImageStore.deleteImage(named:))
    context.delete(expense)
  }
}
