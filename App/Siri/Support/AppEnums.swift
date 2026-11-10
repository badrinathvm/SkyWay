import AppIntents

extension DriveTrip.Purpose: AppEnum {
  static let typeDisplayRepresentation: TypeDisplayRepresentation = "Trip Purpose"
  static let caseDisplayRepresentations: [DriveTrip.Purpose: DisplayRepresentation] = [
    .business: "Business",
    .personal: "Personal",
  ]
}

extension Seat.Position: AppEnum {
  static let typeDisplayRepresentation: TypeDisplayRepresentation = "Seat Position"
  static let caseDisplayRepresentations: [Seat.Position: DisplayRepresentation] = [
    .window: DisplayRepresentation(title: "Window", subtitle: "Seats A and F"),
    .middle: DisplayRepresentation(title: "Middle", subtitle: "Seats B and E"),
    .aisle: DisplayRepresentation(title: "Aisle", subtitle: "Seats C and D"),
  ]
}
