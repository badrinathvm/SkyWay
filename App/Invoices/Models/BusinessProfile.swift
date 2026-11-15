import Foundation

/// The person's business details, printed in the From section of invoice PDFs.
struct BusinessProfile: Sendable {
  /// UserDefaults keys, shared with `BusinessProfileView`'s `@AppStorage`.
  enum Key {
    static let name = "business.name"
    static let email = "business.email"
    static let address = "business.address"
    static let paymentInstructions = "business.paymentInstructions"
  }

  var name: String
  var email: String
  var address: String
  /// How the client should pay, like "Zelle to pay@example.com" or bank details.
  var paymentInstructions: String

  static var current: BusinessProfile {
    let defaults = UserDefaults.standard
    return BusinessProfile(
      name: defaults.string(forKey: Key.name) ?? "",
      email: defaults.string(forKey: Key.email) ?? "",
      address: defaults.string(forKey: Key.address) ?? "",
      paymentInstructions: defaults.string(forKey: Key.paymentInstructions) ?? ""
    )
  }

  var isEmpty: Bool {
    [name, email, address].allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
  }
}
