import AppIntentsTesting
import Evaluations
import Foundation
import SiriEvaluations
import Testing

/// Checks that Siri follows the seat-selection skill. Each scenario starts with the person in 14A.
@Suite("Seat selection")
struct SeatSelectionEvaluationTests {
  /// Siri has to wait for the "Yes" turn before Change Seat runs, because Change Seat asks the
  /// person to confirm.
  @Test(.evaluates(SkywaySiriEvaluation(
    name: "Exact seat number",
    dataset: SiriScenarioLoader {
      [
        "In Skyway, move me to seat 17B",
        "Change my Skyway seat to 17B",
        "Can you put me in 17B on my Skyway flight?",
      ].map { request in
        SiriScenario {
          UserTurn(request) {
            // The person named the seat, so there's no need to look up free seats.
            Calls(.disallowed) { SkywayDefinitions.getAvailableSeats }
          }
          UserTurn("Yes")
        } expectation: {
          Calls { SkywayDefinitions.changeSeat.expect(seat: .equals("17B")) }
        }
      }
    }
  )))
  func exactSeat() {
    let result = EvaluationContext.current.result
    #expect(result.aggregateValue(.mean(of: .intentsAllPass)) >= 0.8)
  }

  @Test(.evaluates(SkywaySiriEvaluation(
    name: "Window seat with more legroom",
    dataset: SiriScenarioLoader {
      [
        "Get me a window seat with more legroom in Skyway",
        "In Skyway, I'd like a window seat with extra legroom",
        "Find me an exit row window seat on my Skyway flight",
      ].map { request in
        SiriScenario {
          UserTurn(request) {
            Loads(.required) { SkywayDefinitions.seatSelection }
            Calls {
              SkywayDefinitions.getAvailableSeats.expect(
                position: .equals("window"),
                extraLegroomOnly: .matches(#Predicate<Bool> { $0 == true })
              )
            }
            // Extra-legroom seats cost $49, so Siri must name the price before changing anything.
            Calls(.disallowed) { SkywayDefinitions.changeSeat }
            SiriResponse(.contains("49"))
          }
        }
      }
    }
  )))
  func windowWithLegroom() {
    let result = EvaluationContext.current.result
    #expect(result.aggregateValue(.mean(of: .intentsAllPass)) >= 0.8)
    #expect(result.aggregateValue(.mean(of: .skillsLoadedAllPass)) >= 0.8)
    #expect(result.aggregateValue(.mean(of: .siriResponseAllPass)) >= 0.8)
  }

  @Test(.evaluates(SkywaySiriEvaluation(
    name: "Agree to pay for legroom",
    dataset: SiriScenarioLoader {
      SiriScenario {
        UserTurn("Get me a window seat with more legroom in Skyway")
        UserTurn("Yes, I'll pay for it")
      } expectation: {
        Calls {
          SkywayDefinitions.getAvailableSeats.expect(extraLegroomOnly: .matches(#Predicate<Bool> { $0 == true }))
          SkywayDefinitions.changeSeat
        }
      }
    }
  )))
  func agreeToPay() {
    let result = EvaluationContext.current.result
    #expect(result.aggregateValue(.mean(of: .intentsAllPass)) >= 0.8)
  }

  @Test(.evaluates(SkywaySiriEvaluation(
    name: "Only asking which seats are free",
    dataset: SiriScenarioLoader {
      [
        "Which aisle seats are free on my Skyway flight?",
        "In Skyway, are there any aisle seats left?",
      ].map { request in
        SiriScenario {
          UserTurn(request) {
            Calls {
              SkywayDefinitions.getAvailableSeats.expect(
                position: .equals("aisle")
              )
            }
            Calls(.disallowed) { SkywayDefinitions.changeSeat }
          }
        }
      }
    }
  )))
  func onlyAsking() {
    let result = EvaluationContext.current.result
    #expect(result.aggregateValue(.mean(of: .intentsAllPass)) >= 0.8)
  }

  @Test(.evaluates(SkywaySiriEvaluation(
    name: "Seat near the front",
    dataset: SiriScenarioLoader {
      [
        "Find me a seat closer to the front in Skyway",
        "In Skyway, move me nearer the front of the plane",
      ].map { request in
        SiriScenario {
          UserTurn(request) {
            Calls {
              SkywayDefinitions.getAvailableSeats.expect(maximumRow: .matches(#Predicate<Int> { $0 <= 10 }))
            }
          }
        }
      }
    }
  )))
  func nearTheFront() {
    let result = EvaluationContext.current.result
    #expect(result.aggregateValue(.mean(of: .intentsAllPass)) >= 0.8)
  }

  /// Trip questions go to Get Upcoming Trip, not the seat tools.
  @Test(.evaluates(SkywaySiriEvaluation(
    name: "Trip question isn't a seat request",
    dataset: SiriScenarioLoader {
      [
        "What gate is my Skyway flight leaving from?",
        "When does my Skyway flight board?",
      ].map { request in
        SiriScenario {
          UserTurn(request) {
            Calls { SkywayDefinitions.getCurrentTrip }
            Calls(.disallowed) {
              SkywayDefinitions.changeSeat
              SkywayDefinitions.getAvailableSeats
            }
          }
        }
      }
    }
  )))
  func tripQuestion() {
    let result = EvaluationContext.current.result
    #expect(result.aggregateValue(.mean(of: .intentsAllPass)) >= 0.8)
  }

  /// After Get Upcoming Trip, a seat request reuses that trip, and a question about it is
  /// answered from it.
  @Test(.evaluates(SkywaySiriEvaluation(
    name: "Follow-up on the upcoming trip",
    dataset: SiriScenarioLoader {
      SiriScenario {
        UserTurn("Where am I flying with Skyway?") {
          Calls { SkywayDefinitions.getCurrentTrip }
        }
        UserTurn("Can you move me to 17B?")
        UserTurn("Yes")
      } expectation: {
        Calls {
          SkywayDefinitions.getCurrentTrip
          SkywayDefinitions.changeSeat.expect(seat: .equals("17B"))
        }
      }
      SiriScenario {
        UserTurn("Where am I flying with Skyway?")
        UserTurn("What's my confirmation code?") {
          Calls(.disallowed) {
            SkywayDefinitions.changeSeat
            SkywayDefinitions.getAvailableSeats
          }
        }
      }
    }
  )))
  func followUpOnTrip() {
    let result = EvaluationContext.current.result
    #expect(result.aggregateValue(.mean(of: .intentsAllPass)) >= 0.8)
  }

  /// Undoing a seat change by voice moves the person back to the seat they left.
  @Test(.evaluates(SkywaySiriEvaluation(
    name: "Undo a seat change by voice",
    dataset: SiriScenarioLoader {
      ["Actually, undo that", "Put me back in my old seat"].map { undo in
        SiriScenario {
          UserTurn("In Skyway, move me to seat 17B")
          UserTurn("Yes")
          UserTurn(undo)
          UserTurn("Yes")
        } expectation: {
          Calls {
            SkywayDefinitions.changeSeat.expect(seat: .equals("17B"))
            SkywayDefinitions.changeSeat.expect(seat: .equals("14A"))
          }
        }
      }
    }
  )))
  func undoSeatChange() {
    let result = EvaluationContext.current.result
    #expect(result.aggregateValue(.mean(of: .intentsAllPass)) >= 0.8)
  }
}
