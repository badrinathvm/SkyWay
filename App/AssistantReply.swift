import FoundationModels

/// The model's answer to a text question, with follow-ups to suggest next.
@Generable
struct AssistantReply {
  @Guide(description: "A short, friendly answer in plain text, without Markdown.")
  var answer: String

  @Guide(description: "Short follow-up questions the person might ask next, each under 8 words.", .count(3))
  var followUps: [String]
}

/// The model's answer to a question about an attached photo. If the photo is a boarding pass
/// or flight itinerary, it also reads the flight details out of it.
@Generable
struct PhotoReply {
  @Guide(description: "A short, friendly answer about the photo in plain text, without Markdown.")
  var answer: String

  @Guide(description: "The flight in the photo. Only fill this in when the photo shows a boarding pass, ticket, or flight itinerary.")
  var scannedTrip: ScannedTrip?

  @Guide(description: "Short follow-up questions the person might ask next, each under 8 words.", .count(3))
  var followUps: [String]
}
