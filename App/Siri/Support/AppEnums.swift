import AppIntents

extension DriveTrip.Purpose: AppEnum {
  static let typeDisplayRepresentation: TypeDisplayRepresentation = "Trip Purpose"
  static let caseDisplayRepresentations: [DriveTrip.Purpose: DisplayRepresentation] = [
    .business: "Business",
    .personal: "Personal",
  ]
}
