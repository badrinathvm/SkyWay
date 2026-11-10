import AppIntents

enum InvoiceError: Error, CustomLocalizedStringResourceConvertible {
  case missingClient
  case missingService
  case invalidAmount
  case notFound

  var localizedStringResource: LocalizedStringResource {
    switch self {
    case .missingClient: "An invoice needs a client name, like John."
    case .missingService: "An invoice needs a service to bill for, like gardening."
    case .invalidAmount: "The amount needs to be more than $0, like 450."
    case .notFound: "That invoice isn't in Skyway anymore."
    }
  }
}
