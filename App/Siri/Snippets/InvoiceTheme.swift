import SwiftUI

/// A color and symbol picked from the service being billed, so a gardening invoice looks green and leafy.
struct InvoiceTheme {
  var symbol: String
  var color: Color

  init(service: String) {
    let text = service.lowercased()
    let match = Self.themes.first { keywords, _ in keywords.contains { text.contains($0) } }
    (symbol, color) = match?.1 ?? ("briefcase.fill", .indigo)
  }

  private static let themes: [([String], (String, Color))] = [
    (["garden", "lawn", "landscap", "plant", "tree", "yard", "mow"], ("leaf.fill", .green)),
    (["clean", "wash", "maid", "tidy"], ("sparkles", .cyan)),
    (["plumb", "repair", "fix", "electric", "handyman", "install"], ("wrench.and.screwdriver.fill", .orange)),
    (["build", "carpent", "construct", "roof", "paint wall"], ("hammer.fill", .brown)),
    (["design", "paint", "art", "illustrat", "logo"], ("paintbrush.pointed.fill", .pink)),
    (["photo", "video", "film", "shoot"], ("camera.fill", .purple)),
    (["tutor", "lesson", "teach", "class", "coach"], ("book.fill", .blue)),
    (["dog", "pet", "walk", "groom"], ("pawprint.fill", .mint)),
    (["cater", "cook", "chef", "food", "bake"], ("fork.knife", .red)),
    (["consult", "develop", "code", "software", "web", "app"], ("laptopcomputer", .teal)),
    (["drive", "deliver", "move", "ride", "transport"], ("car.fill", .yellow)),
  ]
}
