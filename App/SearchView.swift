import SwiftUI

struct SearchView: View {
  var trip: Trip
  @State private var query = ""

  var body: some View {
    NavigationStack {
      List {
        if results.isEmpty {
          ContentUnavailableView.search(text: query)
        } else {
          Section(query.isEmpty ? "Suggestions" : "Results") {
            ForEach(results) { action in
              Label {
                VStack(alignment: .leading, spacing: 2) {
                  Text(action.title)
                  if !action.subtitle.isEmpty {
                    Text(action.subtitle)
                      .font(.subheadline)
                      .foregroundStyle(.secondary)
                  }
                }
              } icon: {
                Image(systemName: action.systemImage)
                  .foregroundStyle(.tint)
              }
            }
          }
        }
      }
      .navigationTitle("Search")
      .searchable(text: $query, prompt: "Flights, bags, check-in…")
    }
  }

  private var results: [TravelAction] {
    let all = TravelAction.featured + TravelAction.quick
    let trimmed = query.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty else { return all }
    return all.filter {
      $0.title.localizedStandardContains(trimmed) || $0.subtitle.localizedStandardContains(trimmed)
    }
  }
}
