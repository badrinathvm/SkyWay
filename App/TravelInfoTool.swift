import FoundationModels

/// Lets the model look up the details behind the Travel cards, like the menu, upgrades, or bags,
/// so it answers from Skyway's data instead of guessing.
struct TravelInfoTool: Tool {
  let name = "getTravelInfo"
  let description = """
    Looks up details about the person's flight: the inflight menu, seat upgrades, directions to the gate, \
    checked bags, Wi-Fi and entertainment, changing or cancelling the flight, check-in, arrival weather, \
    and flight status.
    """

  var trip: Trip

  @Generable
  struct Arguments {
    @Guide(description: "The topic the person is asking about.")
    var topic: TravelKnowledge.Topic
  }

  func call(arguments: Arguments) async throws -> String {
    TravelKnowledge.details(about: arguments.topic, for: trip)
  }
}
