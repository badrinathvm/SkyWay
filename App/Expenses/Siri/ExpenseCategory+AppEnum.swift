import AppIntents

/// Lets Siri and Shortcuts file an expense under one of the app's categories.
extension ExpenseCategory: AppEnum {
  static let typeDisplayRepresentation: TypeDisplayRepresentation = "Expense Category"

  static let caseDisplayRepresentations: [ExpenseCategory: DisplayRepresentation] = [
    .meals: DisplayRepresentation(title: "Meals", subtitle: "Restaurants, coffee, and food", image: .init(systemName: "fork.knife")),
    .travel: DisplayRepresentation(title: "Travel", subtitle: "Flights, taxis, rideshares, parking, and tolls", image: .init(systemName: "airplane")),
    .lodging: DisplayRepresentation(title: "Lodging", subtitle: "Hotels and short-term rentals", image: .init(systemName: "bed.double.fill")),
    .fuel: DisplayRepresentation(title: "Fuel", subtitle: "Gas and EV charging", image: .init(systemName: "fuelpump.fill")),
    .office: DisplayRepresentation(title: "Office Supplies", subtitle: "Paper, ink, and stationery", image: .init(systemName: "paperclip")),
    .software: DisplayRepresentation(title: "Software", subtitle: "Apps, subscriptions, and cloud services", image: .init(systemName: "app.badge")),
    .equipment: DisplayRepresentation(title: "Equipment", subtitle: "Computers, phones, cameras, and tools", image: .init(systemName: "desktopcomputer")),
    .other: DisplayRepresentation(title: "Other", subtitle: "Anything that doesn't fit another category", image: .init(systemName: "tag.fill")),
  ]
}
