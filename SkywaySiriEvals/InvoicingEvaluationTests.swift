import AppIntentsTesting
import Evaluations
import Foundation
import SiriEvaluations
import Testing

/// Checks that Siri follows the invoicing skill. Each scenario starts with these invoices:
/// INV-0001 John Appleseed, Gardening, $450; INV-0002 Maria Garcia, Dog walking, $40;
/// INV-0003 John Rivera, Pool cleaning, $120.
@Suite("Invoicing")
struct InvoicingEvaluationTests {
  /// Create Invoice asks the person to confirm, so it runs only after the "Yes" turn.
  @Test(.evaluates(SkywaySiriEvaluation(
    name: "Complete request",
    dataset: SiriScenarioLoader {
      [
        "In Skyway, bill John Appleseed $450 for gardening",
        "Create a Skyway invoice for John Appleseed, gardening, 450 dollars",
      ].map { request in
        SiriScenario {
          UserTurn(request)
          UserTurn("Yes")
        } expectation: {
          Calls {
            SkywayDefinitions.createInvoice.expect(
              clientName: .equals("John Appleseed"),
              service: .contains(regex: "(?i)garden"),
              amount: .matches(#Predicate<Double> { $0 == 450 })
            )
          }
        }
      }
    }
  )))
  func completeRequest() {
    let result = EvaluationContext.current.result
    #expect(result.aggregateValue(.mean(of: .intentsAllPass)) >= 0.8)
  }

  @Test(.evaluates(SkywaySiriEvaluation(
    name: "The usual",
    dataset: SiriScenarioLoader {
      [
        "Bill John Appleseed the usual in Skyway",
        "In Skyway, invoice John Appleseed the same as last time",
      ].map { request in
        SiriScenario {
          UserTurn(request) {
            Loads(.required) { SkywayDefinitions.invoicing }
            // The skill says to name the invoice the amount came from.
            SiriResponse(.contains("INV-0001"))
          }
          UserTurn("Yes")
        } expectation: {
          Calls {
            SkywayDefinitions.getRecentInvoices
            SkywayDefinitions.createInvoice.expect(
              clientName: .equals("John Appleseed"),
              amount: .matches(#Predicate<Double> { $0 == 450 })
            )
          }
        }
      }
    }
  )))
  func theUsual() {
    let result = EvaluationContext.current.result
    #expect(result.aggregateValue(.mean(of: .intentsAllPass)) >= 0.8)
    #expect(result.aggregateValue(.mean(of: .skillsLoadedAllPass)) >= 0.8)
    #expect(result.aggregateValue(.mean(of: .siriResponseAllPass)) >= 0.8)
  }

  @Test(.evaluates(SkywaySiriEvaluation(
    name: "Rate times quantity",
    dataset: SiriScenarioLoader {
      SiriScenario {
        UserTurn("Bill Maria for 3 walks at $40 each in Skyway") {
          SiriResponse(.contains("120"))
        }
        UserTurn("Yes")
      } expectation: {
        Calls {
          SkywayDefinitions.createInvoice.expect(
            clientName: .equals("Maria Garcia"),
            amount: .matches(#Predicate<Double> { $0 == 120 })
          )
        }
      }
    }
  )))
  func rateTimesQuantity() {
    let result = EvaluationContext.current.result
    #expect(result.aggregateValue(.mean(of: .intentsAllPass)) >= 0.8)
    #expect(result.aggregateValue(.mean(of: .siriResponseAllPass)) >= 0.8)
  }

  /// Requests Siri shouldn't turn into an invoice right away.
  @Test(.evaluates(SkywaySiriEvaluation(
    name: "Don't create an invoice",
    dataset: SiriScenarioLoader {
      // Two recent clients are called John, so Siri has to ask which one.
      SiriScenario {
        UserTurn("Bill John for gardening in Skyway") {
          Calls(.disallowed) { SkywayDefinitions.createInvoice }
        }
      }
      // Only asking what was billed.
      SiriScenario {
        UserTurn("What did I bill recently in Skyway?") {
          Calls { SkywayDefinitions.getRecentInvoices }
          Calls(.disallowed) { SkywayDefinitions.createInvoice }
        }
      }
      // Create Invoice only bills in US dollars.
      SiriScenario {
        UserTurn("Bill John Appleseed 500 euros for gardening in Skyway") {
          Calls(.disallowed) { SkywayDefinitions.createInvoice }
        }
      }
    }
  )))
  func dontCreate() {
    let result = EvaluationContext.current.result
    #expect(result.aggregateValue(.mean(of: .intentsAllPass)) >= 0.8)
  }
}
