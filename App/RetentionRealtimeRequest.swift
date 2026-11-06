import Foundation

/// The decoded payload the App Store POSTs to your Get Retention Message endpoint
/// (`DecodedRealtimeRequestBody`). On a real server it arrives as `{"signedPayload": "<JWS>"}`
/// and you verify the JWS signature against Apple's certificate chain before trusting it.
struct RetentionRealtimeRequest: Codable, Hashable {
  enum Environment: String, Codable {
    case sandbox = "Sandbox"
    case production = "Production"
  }

  var originalTransactionId: String
  var appAppleId: Int
  var productId: String
  var userLocale: String
  var requestIdentifier: String
  var environment: Environment
  /// Milliseconds since 1970, as the App Store sends it.
  var signedDate: Int64
}
