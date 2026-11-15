import Foundation

/// Why an expense couldn't be logged, worded so Siri can ask for what's missing.
enum ExpenseIntentError: Error, CustomLocalizedStringResourceConvertible {
  case missingSupplier
  case invalidAmount
  case unknownCurrency(String)
  case futureDate

  var localizedStringResource: LocalizedStringResource {
    switch self {
    case .missingSupplier: "Say which business the expense was at."
    case .invalidAmount: "The amount needs to be more than zero."
    case .unknownCurrency(let code): "\(code) isn't a currency code Skyway knows. Use a code like USD, EUR or GBP."
    case .futureDate: "An expense can't be dated in the future. Say the day you paid."
    }
  }
}
