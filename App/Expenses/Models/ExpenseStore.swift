import CoreSpotlight
import Foundation
import SwiftData

/// Where expenses are saved: a SwiftData store of their own, apart from the trip data.
/// The app's screens and Siri share one container, so an expense logged from Siri shows up
/// in the list right away.
@MainActor
enum ExpenseStore {
  static let container: ModelContainer = {
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

  private static var context: ModelContext { container.mainContext }

  /// The newest expenses by purchase date.
  static func recentExpenses(limit: Int) -> [Expense] {
    var newest = FetchDescriptor<Expense>(sortBy: [SortDescriptor(\.date, order: .reverse)])
    newest.fetchLimit = limit
    return (try? context.fetch(newest)) ?? []
  }

  static func expenses(with identifiers: [UUID]) -> [Expense] {
    let descriptor = FetchDescriptor<Expense>(predicate: #Predicate { identifiers.contains($0.id) })
    return (try? context.fetch(descriptor)) ?? []
  }

  /// Saves an expense entered without a receipt, like one logged from Siri. Without a
  /// category, it's filed the way the person filed this supplier before, or by its name.
  static func logExpense(
    supplier: String,
    total: Double,
    currencyCode: String,
    category: ExpenseCategory?,
    date: Date,
    notes: String
  ) throws -> Expense {
    let expense = Expense(
      supplier: supplier,
      date: date,
      total: total,
      currencyCode: currencyCode,
      category: category ?? SupplierCategoryRules.category(for: supplier) ?? .guess(from: supplier),
      notes: notes
    )
    context.insert(expense)
    try context.save()
    index([expense])
    return expense
  }

  /// Removes the expense, its receipt images, and its Spotlight entry.
  static func delete(_ expense: Expense, from context: ModelContext) {
    let identifier = expense.id.uuidString
    expense.receiptFileNames.forEach(ReceiptImageStore.deleteImage(named:))
    context.delete(expense)
    Task {
      try? await CSSearchableIndex.default().deleteAppEntities(identifiedBy: [identifier], ofType: ExpenseEntity.self)
    }
  }

  // MARK: - Spotlight

  /// Adds expenses to Spotlight, so Siri can find one by supplier without opening the app.
  static func index(_ expenses: [Expense]) {
    let entities = expenses.map(\.entity)
    Task {
      try? await CSSearchableIndex.default().indexAppEntities(entities)
    }
  }

  /// Indexes every expense, at launch, so the index catches up with changes made elsewhere.
  static func indexAllInSpotlight() {
    index((try? context.fetch(FetchDescriptor<Expense>())) ?? [])
  }
}
