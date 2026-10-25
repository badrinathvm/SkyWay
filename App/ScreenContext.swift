import Foundation
import Observation

/// Tracks which on-screen items can be shared with the assistant, and which ones the person selected.
@Observable
final class ScreenContext {
  enum Mode {
    /// Nothing is highlighted.
    case off
    /// The person is choosing items; tapping an item toggles it.
    case selecting
    /// The selection is being used for a question; selected items stay highlighted.
    case locked
  }

  private(set) var mode: Mode = .off
  /// True while a long press is in progress, to preview what will be selected.
  var isPreviewing = false
  private(set) var selectedIDs: Set<ContextItem.ID> = []
  private var registered: [ContextItem.ID: ContextItem] = [:]
  private var order: [ContextItem.ID] = []

  var items: [ContextItem] {
    order.compactMap { registered[$0] }.sorted { $0.sortOrder < $1.sortOrder }
  }

  var selectedItems: [ContextItem] {
    items.filter { selectedIDs.contains($0.id) }
  }

  var areAllSelected: Bool {
    !registered.isEmpty && selectedIDs.count == registered.count
  }

  func register(_ item: ContextItem) {
    if registered[item.id] == nil {
      order.append(item.id)
    }
    registered[item.id] = item
  }

  func unregister(_ id: ContextItem.ID) {
    registered[id] = nil
    order.removeAll { $0 == id }
    selectedIDs.remove(id)
  }

  /// Whether a long press in progress would select this item.
  func isPreviewed(_ item: ContextItem) -> Bool {
    isPreviewing && mode == .off && item.isSelectedByDefault
  }

  func isSelected(_ id: ContextItem.ID) -> Bool {
    mode != .off && selectedIDs.contains(id)
  }

  /// Starts selection with every item that's selected by default.
  func beginSelecting() {
    isPreviewing = false
    selectedIDs = Set(items.filter(\.isSelectedByDefault).map(\.id))
    mode = .selecting
  }

  func toggle(_ id: ContextItem.ID) {
    guard mode == .selecting else { return }
    if selectedIDs.contains(id) {
      selectedIDs.remove(id)
    } else {
      selectedIDs.insert(id)
    }
  }

  func selectAll() {
    selectedIDs = Set(registered.keys)
  }

  func selectNone() {
    selectedIDs = []
  }

  /// Keeps the current selection highlighted while it's being used for a question.
  func lock() {
    mode = selectedIDs.isEmpty ? .off : .locked
  }

  func clear() {
    mode = .off
    selectedIDs = []
  }
}
