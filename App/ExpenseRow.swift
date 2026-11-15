import SwiftUI

/// One expense in the list: its category, supplier, date and total.
struct ExpenseRow: View {
  var expense: Expense

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: expense.category.systemImage)
        .font(.body.weight(.semibold))
        .foregroundStyle(.tint)
        .frame(width: 36, height: 36)
        .background(.tint.opacity(0.15), in: .circle)
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 2) {
        Text(expense.displayName)
          .font(.body.weight(.medium))
          .lineLimit(1)
        Text("\(expense.category.title) · \(expense.date.formatted(date: .abbreviated, time: .omitted))")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      Spacer(minLength: 8)

      Text(expense.totalText)
        .font(.body.weight(.semibold))
        .monospacedDigit()
    }
    .accessibilityElement(children: .combine)
  }
}
