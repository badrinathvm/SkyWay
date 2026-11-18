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
            // Siri's reply here is Create Invoice's confirmation, so it shows the amount it chose.
            SiriResponse(.contains("$450"))
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
          // Siri may pass just "Maria". Create Invoice fills in the full name from past invoices,
          // so check the invoice it creates.
          SkywayDefinitions.createInvoice
            .expect(amount: .matches(#Predicate<Double> { $0 == 120 }))
            .result(SkywayDefinitions.invoice.expect(clientName: .equals("Maria Garcia")))
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

  /// After listing invoices, Siri acts on one of them from the list it already has, without
  /// asking which invoice or listing them again.
  @Test(.evaluates(SkywaySiriEvaluation(
    name: "Follow-up on listed invoices",
    dataset: SiriScenarioLoader {
      SiriScenario {
        UserTurn("What did I bill recently in Skyway?") {
          Calls { SkywayDefinitions.getRecentInvoices }
        }
        UserTurn("Maria paid that one") {
          Calls(.disallowed) { SkywayDefinitions.getRecentInvoices }
        }
      } expectation: {
        Calls {
          SkywayDefinitions.getRecentInvoices
          SkywayDefinitions.markInvoicePaid.expect(
            invoice: SkywayDefinitions.invoice.expect(clientName: .equals("Maria Garcia"))
          )
        }
      }
      SiriScenario {
        UserTurn("Show my Skyway invoices") {
          Calls { SkywayDefinitions.getRecentInvoices }
        }
        UserTurn("I just emailed the pool cleaning one") {
          Calls(.disallowed) {
            SkywayDefinitions.getRecentInvoices
            SkywayDefinitions.markInvoicePaid
          }
        }
      } expectation: {
        Calls {
          SkywayDefinitions.getRecentInvoices
          SkywayDefinitions.markInvoiceSent.expect(
            invoice: SkywayDefinitions.invoice.expect(clientName: .equals("John Rivera"))
          )
        }
      }
      // A question about the listed invoices is answered from them, without changing anything.
      SiriScenario {
        UserTurn("What did I bill recently in Skyway?")
        UserTurn("How much was Maria's?") {
          Calls(.disallowed) {
            SkywayDefinitions.markInvoicePaid
            SkywayDefinitions.markInvoiceSent
            SkywayDefinitions.createInvoice
          }
          SiriResponse(.contains("40"))
        }
      }
    }
  )))
  func followUpOnListedInvoices() {
    let result = EvaluationContext.current.result
    #expect(result.aggregateValue(.mean(of: .intentsAllPass)) >= 0.8)
    #expect(result.aggregateValue(.mean(of: .siriResponseAllPass)) >= 0.8)
  }

  /// Undoing by voice, with no card to tap, like on AirPods: Siri deletes the invoice it just
  /// created, after the person confirms.
  @Test(.evaluates(SkywaySiriEvaluation(
    name: "Undo a new invoice by voice",
    dataset: SiriScenarioLoader {
      ["Actually, undo that", "Cancel that invoice", "Oops, I made a mistake, delete it"].map { undo in
        SiriScenario {
          UserTurn("In Skyway, bill Maria Garcia $40 for dog walking")
          UserTurn("Yes")
          UserTurn(undo) {
            Calls(.disallowed) { SkywayDefinitions.getRecentInvoices }
          }
          UserTurn("Yes")
        } expectation: {
          Calls {
            SkywayDefinitions.createInvoice
            SkywayDefinitions.deleteInvoice.expect(
              invoice: SkywayDefinitions.invoice.expect(number: .equals("INV-0004"))
            )
          }
        }
      }
    }
  )))
  func undoNewInvoice() {
    let result = EvaluationContext.current.result
    #expect(result.aggregateValue(.mean(of: .intentsAllPass)) >= 0.8)
  }
}
