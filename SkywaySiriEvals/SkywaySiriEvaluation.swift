import Evaluations
import SiriEvaluations
import Testing
import XCTest

/// Runs each scenario through Siri from the same starting point: three seeded invoices, and the
/// upcoming trip in its original seat, 14A.
struct SkywaySiriEvaluation: Evaluation {
  /// The title of the report in Xcode.
  var name: String
  var dataset: SiriScenarioLoader

  func subject(from sample: SiriScenario) async throws -> SiriScenarioSubject {
    // Launching the app makes the system register its latest intents, including the debug-only
    // reset intent, which a fresh install from Xcode doesn't do on its own.
    await MainActor.run {
      XCUIApplication(bundleIdentifier: "com.badarinathvm.skyway").launch()
    }

    // Reset before every scenario, so an invoice or seat change from one can't affect the next.
    // A failed reset is recorded rather than thrown, since throwing drops the scenario from the report.
    do {
      _ = try await SkywayDefinitions.resetDemoData.makeIntent().run()
    } catch {
      Issue.record(error, "Couldn't reset Skyway's demo data")
    }
    return try await SiriService.run(scenario: sample)
  }

  var evaluators: Evaluators {
    SiriExpectationEvaluator()
  }

  func aggregateMetrics(using aggregator: inout MetricsAggregator) {
    Self.computeSiriMetrics(into: &aggregator)
  }
}
