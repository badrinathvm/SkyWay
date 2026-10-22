import AppIntents
import CoreTransferable

/// Exposes a travel action to Siri and Apple Intelligence so requests like
/// "What does this one do?" can resolve the row shown on screen.
struct TravelActionEntity: AppEntity {
  static let typeDisplayRepresentation: TypeDisplayRepresentation = "Travel Action"
  static let defaultQuery = TravelActionEntityQuery()

  var id: String

  @Property(title: "Name")
  var name: String

  @Property(title: "Details")
  var details: String

  var systemImage: String

  init(action: TravelAction) {
    id = action.id
    systemImage = action.systemImage
    name = action.title
    details = action.subtitle
  }

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(
      title: "\(name)",
      subtitle: details.isEmpty ? nil : "\(details)",
      image: .init(systemName: systemImage)
    )
  }
}

extension TravelActionEntity: Transferable {
  static var transferRepresentation: some TransferRepresentation {
    ProxyRepresentation(exporting: { $0.details.isEmpty ? $0.name : "\($0.name): \($0.details)" })
  }
}

extension TravelAction {
  var entity: TravelActionEntity { TravelActionEntity(action: self) }
}

struct TravelActionEntityQuery: EntityStringQuery {
  func entities(for identifiers: [TravelActionEntity.ID]) async throws -> [TravelActionEntity] {
    TravelAction.all.filter { identifiers.contains($0.id) }.map(\.entity)
  }

  func entities(matching string: String) async throws -> [TravelActionEntity] {
    TravelAction.all
      .filter { $0.title.localizedStandardContains(string) || $0.subtitle.localizedStandardContains(string) }
      .map(\.entity)
  }

  func suggestedEntities() async throws -> [TravelActionEntity] {
    TravelAction.all.map(\.entity)
  }
}
