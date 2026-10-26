import Foundation

/// Something on screen that can be shared with the assistant as context.
struct ContextItem: Identifiable, Hashable {
  var id: String
  var title: String
  /// The text sent to the assistant when this item is selected.
  var detail: String
  var systemImage: String
  /// A question to suggest when this item is part of the context.
  var suggestion: String?
  /// Whether a long press selects this item automatically.
  var isSelectedByDefault = true
  /// Where the item appears on screen, so context reads top to bottom.
  var sortOrder = 0
}
