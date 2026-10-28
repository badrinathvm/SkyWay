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
  /// True while the lens demonstrates itself, before the person has touched it.
  private(set) var isPeeking = false
  /// Whether the current selection was picked by dragging the lens, rather than in selection mode.
  private(set) var wasPickedWithLens = false

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
    isPeeking = false
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
    isPeeking = false
    lensLocation = lensOrigin
    isLensActive = false
    hoveredID = nil
  }

  /// Selects just this item, ready to be used for a question.
  func select(only id: ContextItem.ID) {
    isPreviewing = false
    selectedIDs = [id]
    mode = .selecting
    wasPickedWithLens = true
  }

  /// The first item that's fully on screen above `y`, for the lens to demonstrate on.
  func peekTarget(above y: CGFloat) -> (id: ContextItem.ID, center: CGPoint)? {
    for item in items {
      guard let frame = frames[item.id], frame.minY > 0, frame.maxY < y else { continue }
      return (item.id, CGPoint(x: frame.midX, y: frame.midY))
    }
    return nil
  }

  /// Puts the hidden lens at `origin`, ready to peek out.
  func preparePeek(at origin: CGPoint) {
    isPeeking = true
    isLensActive = false
    lensOrigin = origin
    lensLocation = origin
  }

  /// Moves the peeking lens over an item, as if the person dragged it there.
  func movePeek(to target: (id: ContextItem.ID, center: CGPoint)) {
    guard isPeeking else { return }
    isLensActive = true
    lensLocation = target.center
    hoveredID = target.id
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
    wasPickedWithLens = false
  }

  /// Goes back to selecting while keeping the current selection.
  func resumeSelecting() {
    isPreviewing = false
    mode = .selecting
    wasPickedWithLens = false
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
    wasPickedWithLens = false
  }
}
