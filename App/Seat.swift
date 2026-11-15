import Foundation

/// A seat on a Skyway flight, like 17B: a row number and a letter from A to F.
struct Seat: Hashable, Sendable, CustomStringConvertible {
  var row: Int
  var letter: Character

  /// Reads a seat the way people say or type it: "17B", "17 b", or "row 17 seat B".
  init?(_ text: String) {
    let characters = text.uppercased().filter { $0.isLetter || $0.isNumber }
    let digits = characters.filter(\.isNumber)
    let letters = characters.filter(\.isLetter)
      .replacingOccurrences(of: "ROW", with: "")
      .replacingOccurrences(of: "SEAT", with: "")
    guard let row = Int(String(digits)), letters.count == 1, let letter = letters.first else {
      return nil
    }
    self.init(row: row, letter: letter)
  }

  init(row: Int, letter: Character) {
    self.row = row
    self.letter = letter
  }

  var description: String { "\(row)\(letter)" }

  var position: Position {
    switch letter {
    case "A", "F": .window
    case "C", "D": .aisle
    default: .middle
    }
  }

  enum Position: String, Sendable, CaseIterable {
    case window, middle, aisle

    var title: String { rawValue.capitalized }
  }
}
