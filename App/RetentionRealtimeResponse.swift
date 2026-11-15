import Foundation

/// What your endpoint returns with a 200 status (`RealtimeResponseBody`). Exactly one of the
/// three shapes is present. Every message it names must already be `APPROVED`.
enum RetentionRealtimeResponse: Hashable {
  /// Show a message, with or without an image.
  case message(messageIdentifier: String)
  /// Suggest another plan in the same subscription group. Only available in real time.
  case alternateProduct(messageIdentifier: String, productId: String)
  /// Show a message with a promotional offer your server signs.
  case promotionalOffer(messageIdentifier: String, offerId: String)

  var messageIdentifier: String {
    switch self {
    case .message(let id), .alternateProduct(let id, _), .promotionalOffer(let id, _): id
    }
  }
}

extension RetentionRealtimeResponse: Codable {
  private enum CodingKeys: String, CodingKey {
    case message, alternateProduct, promotionalOffer
  }

  private struct Message: Codable { var messageIdentifier: String }
  private struct AlternateProduct: Codable { var messageIdentifier: String; var productId: String }
  /// A real response also carries `promotionalOfferSignatureV2`, a JWS your server signs
  /// with its In-App Purchase key. The demo leaves it out because it has no key to sign with.
  private struct PromotionalOffer: Codable { var messageIdentifier: String; var offerId: String }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    if let value = try container.decodeIfPresent(AlternateProduct.self, forKey: .alternateProduct) {
      self = .alternateProduct(messageIdentifier: value.messageIdentifier, productId: value.productId)
    } else if let value = try container.decodeIfPresent(PromotionalOffer.self, forKey: .promotionalOffer) {
      self = .promotionalOffer(messageIdentifier: value.messageIdentifier, offerId: value.offerId)
    } else {
      let value = try container.decode(Message.self, forKey: .message)
      self = .message(messageIdentifier: value.messageIdentifier)
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .message(let id):
      try container.encode(Message(messageIdentifier: id), forKey: .message)
    case .alternateProduct(let id, let productId):
      try container.encode(AlternateProduct(messageIdentifier: id, productId: productId), forKey: .alternateProduct)
    case .promotionalOffer(let id, let offerId):
      try container.encode(PromotionalOffer(messageIdentifier: id, offerId: offerId), forKey: .promotionalOffer)
    }
  }
}
