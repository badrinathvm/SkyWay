import AppIntents
import CoreTransferable

/// An expense as Siri, Shortcuts and Spotlight see it, like "Blue Bottle Coffee, $10.65".
struct ExpenseEntity: IndexedEntity {
  static let typeDisplayRepresentation: TypeDisplayRepresentation = "Expense"
  static let defaultQuery = ExpenseEntityQuery()

  /// `Expense.id`, which is saved with the expense, so it stays the same across launches.
  ///
  /// Property titles carry their meaning, because `@Property(description:)` needs iOS 27.3 and
  /// this entity also ships on 27.0. Add descriptions once the deployment target reaches 27.3.
  var id: String

  @Property(title: "Supplier (Business Paid)")
  var supplier: String

  @Property(title: "Total Paid, Including Tax")
  var total: Double

  @Property(title: "Currency Code (ISO 4217)")
  var currencyCode: String

  @Property(title: "Tax Included in Total")
  var tax: Double

  @Property(title: "Expense Category")
  var category: ExpenseCategory

  @Property(title: "Purchase Date (Local Time)")
  var date: Date

  @Property(title: "Notes on Purpose")
  var notes: String

  init(expense: Expense) {
    id = expense.id.uuidString
    supplier = expense.displayName
    total = expense.total
    currencyCode = expense.currencyCode
    tax = expense.tax
    category = expense.category
    date = expense.date
    notes = expense.notes
  }

  var totalText: String {
    total.formatted(.currency(code: currencyCode))
  }

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(
      title: "\(supplier), \(totalText)",
      subtitle: "\(category.title) · \(date.formatted(date: .abbreviated, time: .omitted))",
      image: .init(systemName: category.systemImage)
    )
  }

  /// A plain-language description for sharing, and for Apple Intelligence to read.
  var summary: String {
    var text = "\(totalText) at \(supplier) on \(date.formatted(date: .long, time: .omitted)), filed as \(category.title)."
    if tax > 0 {
      text += " Includes \(tax.formatted(.currency(code: currencyCode))) tax."
    }
    if !notes.isEmpty {
      text += " Note: \(notes)"
    }
    return text
  }
}

extension ExpenseEntity: Transferable {
  static var transferRepresentation: some TransferRepresentation {
    ProxyRepresentation(exporting: \.summary)
  }
}

extension Expense {
  var entity: ExpenseEntity { ExpenseEntity(expense: self) }
}

struct ExpenseEntityQuery: EntityStringQuery {
  @MainActor
  func entities(for identifiers: [ExpenseEntity.ID]) async throws -> [ExpenseEntity] {
    ExpenseStore.expenses(with: identifiers.compactMap(UUID.init(uuidString:))).map(\.entity)
  }

  /// For Shortcuts' expense picker. Siri finds expenses through Spotlight instead.
  @MainActor
  func entities(matching string: String) async throws -> [ExpenseEntity] {
    let key = SupplierCategoryRules.normalized(string)
    return ExpenseStore.recentExpenses(limit: 200)
      .filter { SupplierCategoryRules.normalized($0.supplier).contains(key) }
      .map(\.entity)
  }

  @MainActor
  func suggestedEntities() async throws -> [ExpenseEntity] {
    ExpenseStore.recentExpenses(limit: 10).map(\.entity)
  }
}
