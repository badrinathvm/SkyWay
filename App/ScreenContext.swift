import Foundation
import Observation

/// Tracks which on-screen items can be shared with the assistant, and which ones the person selected.
@MainActor
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
  /// Each item's frame in global coordinates, for hit-testing the lens.
  /// Not observed, so scrolling doesn't redraw every item.
  @ObservationIgnored private var frames: [ContextItem.ID: CGRect] = [:]

  /// Where the lens is, in global coordinates, while the person drags it from the assistant bar.
  private(set) var lensLocation: CGPoint?
  /// Where the drag started, so a cancelled lens can return there.
  private(set) var lensOrigin: CGPoint?
  /// True while the person is dragging the lens.
  private(set) var isLensActive = false
  /// The item under the lens.
  private(set) var hoveredID: ContextItem.ID?

  /// How far above the finger the lens floats, so the finger doesn't cover it.
  static let lensLift: CGFloat = 72

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
    frames[id] = nil
    selectedIDs.remove(id)
    if hoveredID == id {
      hoveredID = nil
    }
  }

  func updateFrame(_ frame: CGRect, for id: ContextItem.ID) {
    frames[id] = frame
  }

  func isHovered(_ id: ContextItem.ID) -> Bool {
    hoveredID == id
  }

  /// Moves the lens to float above the finger, and finds the item under it.
  func moveLens(fingerAt location: CGPoint, from origin: CGPoint) {
    let lens = CGPoint(x: location.x, y: location.y - Self.lensLift)
    lensOrigin = origin
    lensLocation = lens
    isLensActive = true
    // The smallest frame wins, so a small item inside a bigger one can still be picked.
    hoveredID = frames
      .filter { registered[$0.key] != nil && $0.value.contains(lens) }
      .min { $0.value.width * $0.value.height < $1.value.width * $1.value.height }?
      .key
  }

  /// Ends the drag and returns the item under the lens, if any.
  /// With nothing under it, the lens returns to where the drag started.
  func endLens() -> ContextItem? {
    guard let item = hoveredID.flatMap({ registered[$0] }) else {
      cancelLens()
      return nil
    }
    isLensActive = false
    hoveredID = nil
    return item
  }

  /// Returns the lens to where the drag started without picking anything.
  func cancelLens() {
    lensLocation = lensOrigin
    isLensActive = false
    hoveredID = nil
  }

  /// Selects just this item, ready to be used for a question.
  func select(only id: ContextItem.ID) {
    isPreviewing = false
    selectedIDs = [id]
    mode = .selecting
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

  /// Goes back to selecting while keeping the current selection.
  func resumeSelecting() {
    isPreviewing = false
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
