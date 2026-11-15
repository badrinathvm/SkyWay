import PhotosUI
import SwiftData
import SwiftUI

/// Every expense, newest first, with ways to add one by scanning, picking photos or typing.
struct ExpenseListView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
  @State private var importer = ReceiptImporter()
  @State private var path = NavigationPath()
  @State private var isScanning = false
  @State private var isPickingPhotos = false
  @State private var photoSelection: [PhotosPickerItem] = []

  var body: some View {
    NavigationStack(path: $path) {
      Group {
        if expenses.isEmpty {
          emptyState
        } else {
          list
        }
      }
      .navigationTitle("Expenses")
      .navigationDestination(for: Expense.self) { expense in
        ExpenseDetailView(expense: expense)
      }
      .navigationDestination(for: ExpenseListRoute.self) { route in
        switch route {
        case .monthlyReport: MonthlyReportView()
        case .mileage: MileageView()
        }
      }
      .toolbar {
        ToolbarItemGroup(placement: .topBarLeading) {
          NavigationLink(value: ExpenseListRoute.monthlyReport) {
            Label("Monthly Report", systemImage: "chart.bar.doc.horizontal")
          }
          NavigationLink(value: ExpenseListRoute.mileage) {
            Label("Mileage", systemImage: "car")
          }
        }
        ToolbarItem(placement: .primaryAction) {
          addMenu
        }
      }
      .disabled(importer.isReading)
      .overlay {
        if importer.isReading {
          readingOverlay
        }
      }
    }
    .fullScreenCover(isPresented: $isScanning) {
      DocumentScanner { pages in
        isScanning = false
        guard !pages.isEmpty else { return }
        importReceipts([pages])
      }
      .ignoresSafeArea()
    }
    .photosPicker(isPresented: $isPickingPhotos, selection: $photoSelection, maxSelectionCount: 10, matching: .images)
    .onChange(of: photoSelection) {
      let items = photoSelection
      guard !items.isEmpty else { return }
      photoSelection = []
      Task {
        // Each photo is its own receipt.
        var receipts: [[UIImage]] = []
        for item in items {
          if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
            receipts.append([image])
          }
        }
        importReceipts(receipts)
      }
    }
    .alert("Couldn't Read Receipt", isPresented: Binding(
      get: { importer.errorMessage != nil },
      set: { if !$0 { importer.errorMessage = nil } }
    )) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(importer.errorMessage ?? "")
    }
    .sensoryFeedback(.success, trigger: expenses.count) { old, new in new > old }
  }

  private var list: some View {
    List {
      Section {
        NavigationLink(value: ExpenseListRoute.monthlyReport) {
          ExpenseMonthSummary(totals: Expense.monthlyTotals(of: expenses))
        }
        .accessibilityHint("Shows the monthly report.")
        NavigationLink(value: ExpenseListRoute.mileage) {
          Label("Mileage", systemImage: "car")
        }
      }
      Section("All Expenses") {
        ForEach(expenses) { expense in
          NavigationLink(value: expense) {
            ExpenseRow(expense: expense)
          }
        }
        .onDelete { offsets in
          for index in offsets {
            ExpenseStore.delete(expenses[index], from: modelContext)
          }
        }
      }
    }
  }

  private var emptyState: some View {
    ContentUnavailableView {
      Label("No Expenses", systemImage: "receipt")
    } description: {
      Text("Scan a receipt and Skyway reads the supplier, date, total and tax for you.")
    } actions: {
      if DocumentScanner.isSupported {
        Button("Scan Receipt", systemImage: "doc.viewfinder") {
          isScanning = true
        }
        .buttonStyle(.borderedProminent)
      }
      Button("Choose Photos", systemImage: "photo.on.rectangle") {
        isPickingPhotos = true
      }
      .buttonStyle(.bordered)
    }
  }

  private var addMenu: some View {
    Menu("Add Expense", systemImage: "plus") {
      if DocumentScanner.isSupported {
        Button("Scan Receipt", systemImage: "doc.viewfinder") {
          isScanning = true
        }
      }
      Button("Choose Photos", systemImage: "photo.on.rectangle") {
        isPickingPhotos = true
      }
      Button("Enter Manually", systemImage: "square.and.pencil") {
        let expense = Expense()
        modelContext.insert(expense)
        path.append(expense)
      }
    }
  }

  private var readingOverlay: some View {
    VStack(spacing: 12) {
      ProgressView()
        .controlSize(.large)
      Text(importer.remainingCount > 1 ? "Reading \(importer.remainingCount) receipts…" : "Reading receipt…")
        .font(.headline)
    }
    .padding(24)
    .background(.regularMaterial, in: .rect(cornerRadius: 20))
    .accessibilityElement(children: .combine)
  }

  private func importReceipts(_ receipts: [[UIImage]]) {
    Task {
      let imported = await importer.importReceipts(receipts, into: modelContext)
      // Open a single receipt so its details can be checked right away.
      if imported.count == 1, let expense = imported.first {
        path.append(expense)
      }
    }
  }
}

/// Screens pushed from the expense list, other than an expense itself.
private enum ExpenseListRoute: Hashable {
  case monthlyReport
  case mileage
}
