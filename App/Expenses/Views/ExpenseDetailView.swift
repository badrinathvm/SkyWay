import SwiftData
import SwiftUI

/// An expense's details, all editable, with the receipt it was read from.
struct ExpenseDetailView: View {
  @Bindable var expense: Expense
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  @State private var isConfirmingDelete = false
  @State private var presentedPage: ReceiptPage?

  private static let currencyCodes = ["USD", "EUR", "GBP", "CAD", "AUD", "INR", "JPY", "CHF", "MXN"]

  var body: some View {
    Form {
      if !expense.receiptFileNames.isEmpty {
        Section {
          receiptPages
        } footer: {
          Text("Details were read from the receipt. Check them before filing.")
        }
      }

      Section("Details") {
        TextField("Supplier", text: $expense.supplier)
          .textContentType(.organizationName)
        DatePicker("Date", selection: $expense.date, in: ...Date.now, displayedComponents: .date)
        Picker("Category", selection: $expense.category) {
          ForEach(ExpenseCategory.allCases) { category in
            Label(category.title, systemImage: category.systemImage)
              .tag(category)
          }
        }
        .pickerStyle(.menu)
      }

      Section("Amount") {
        LabeledContent("Total") {
          TextField("Total", value: $expense.total, format: .number.precision(.fractionLength(2)))
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
        }
        LabeledContent("Tax") {
          TextField("Tax", value: $expense.tax, format: .number.precision(.fractionLength(2)))
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
        }
        Picker("Currency", selection: $expense.currencyCode) {
          ForEach(currencyOptions, id: \.self) { code in
            Text(code).tag(code)
          }
        }
        .pickerStyle(.menu)
      }

      Section("Notes") {
        TextField("What was this for?", text: $expense.notes, axis: .vertical)
          .lineLimit(2...6)
      }

      if !expense.recognizedText.isEmpty {
        Section {
          DisclosureGroup("Text on Receipt") {
            Text(expense.recognizedText)
              .font(.footnote.monospaced())
              .foregroundStyle(.secondary)
              .textSelection(.enabled)
          }
        }
      }

      Section {
        Button("Delete Expense", systemImage: "trash", role: .destructive) {
          isConfirmingDelete = true
        }
        .foregroundStyle(.red)
        .confirmationDialog("Delete this expense?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
          Button("Delete Expense", role: .destructive) {
            ExpenseStore.delete(expense, from: modelContext)
            dismiss()
          }
        } message: {
          Text("The \(expense.totalText) expense and its receipt will be removed.")
        }
      }
    }
    .navigationTitle(expense.displayName)
    .navigationBarTitleDisplayMode(.inline)
    .sheet(item: $presentedPage) { page in
      ReceiptPageView(fileName: page.fileName)
    }
    .onDisappear {
      // A manual entry that was opened and left empty shouldn't stay in the list.
      if !expense.isDeleted, expense.isBlank {
        ExpenseStore.delete(expense, from: modelContext)
      }
    }
  }

  private var currencyOptions: [String] {
    var codes = Self.currencyCodes
    for code in [expense.currencyCode, Expense.defaultCurrencyCode] where !codes.contains(code) {
      codes.insert(code, at: 0)
    }
    return codes
  }

  private var receiptPages: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 12) {
        ForEach(Array(expense.receiptFileNames.enumerated()), id: \.element) { index, fileName in
          Button {
            presentedPage = ReceiptPage(fileName: fileName)
          } label: {
            ReceiptThumbnail(fileName: fileName)
          }
          .buttonStyle(.plain)
          .accessibilityLabel("Receipt page \(index + 1)")
          .accessibilityHint("Shows the page full size.")
        }
      }
      .padding(.vertical, 4)
    }
    .scrollIndicators(.hidden)
  }
}

/// A receipt page chosen to show full size.
private struct ReceiptPage: Identifiable {
  var fileName: String
  var id: String { fileName }
}
