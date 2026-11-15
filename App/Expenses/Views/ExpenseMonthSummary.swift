import SwiftUI

/// This month's spending at the top of the expense list.
struct ExpenseMonthSummary: View {
  /// Formatted totals per currency, largest first.
  var totals: [String]

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Spent in \(Date.now.formatted(.dateTime.month(.wide)))")
        .font(.subheadline)
        .foregroundStyle(.secondary)
      Text(totals.first ?? 0.formatted(.currency(code: Expense.defaultCurrencyCode)))
        .font(.largeTitle.weight(.bold))
        .monospacedDigit()
        .contentTransition(.numericText())
      if totals.count > 1 {
        Text("Plus \(totals.dropFirst().formatted(.list(type: .and)))")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, 4)
    .accessibilityElement(children: .combine)
  }
}
