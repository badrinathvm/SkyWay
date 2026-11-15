import Foundation
import UIKit

/// Sends ended trips to the backend in the background, and keeps retrying until each one is saved.
///
/// The rules it follows, because it usually runs in a car:
/// - **Local first.** A trip is saved to DriveTrips.json before it gets here, so a failed upload
///   never loses one. The queue is simply every saved trip without a `syncedAt` date.
/// - **Never blocks the driver.** End Trip closes the sheet right away; uploading happens after.
/// - **Survives being backgrounded.** Once a trip ends, location tracking stops and nothing keeps
///   the app running, so if the driver switches to Maps, iOS can suspend Skyway within seconds.
///   Each pass asks iOS for extra time with a background task so the upload can finish.
/// - **Retries with backoff.** No signal in a parking garage is normal. After a failure it waits
///   30 s, then 1, 2, 4… minutes (up to 15), and also tries again whenever the app or car screen
///   comes back, so trips catch up once there's signal.
@MainActor
final class TripSyncer {
  private let backend: any TripBackend
  /// Returns the trips still to upload, read fresh each pass so trips ended mid-pass are included.
  private var pendingTrips: () -> [DriveTrip] = { [] }
  /// Records that the backend saved a trip, so it leaves the queue.
  private var markSynced: (UUID, Date) -> Void = { _, _ in }

  private var syncTask: Task<Void, Never>?
  /// Set when a sync is asked for while a pass is running, so one more pass runs after it.
  private var needsAnotherPass = false
  private var retryTask: Task<Void, Never>?
  /// Failed passes in a row, for the backoff. Reset by any successful upload.
  private var failureCount = 0
  private var backgroundTaskID = UIBackgroundTaskIdentifier.invalid
  private var activeObserver: NSObjectProtocol?

  init(backend: any TripBackend) {
    self.backend = backend
  }

  /// Connects the syncer to the trips it uploads. Call once, before the first `syncNow()`.
  func configure(
    pendingTrips: @escaping () -> [DriveTrip],
    markSynced: @escaping (UUID, Date) -> Void
  ) {
    self.pendingTrips = pendingTrips
    self.markSynced = markSynced
    // Opening Skyway on iPhone is a good moment to catch up: it often means there's signal again.
    activeObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
    ) { [weak self] _ in
      MainActor.assumeIsolated { self?.syncNow() }
    }
  }

  /// Uploads every pending trip. Safe to call any time and as often as needed: calls made while a
  /// pass is running are folded into one more pass, and a waiting retry is replaced.
  func syncNow() {
    guard syncTask == nil else {
      needsAnotherPass = true
      return
    }
    retryTask?.cancel()
    retryTask = nil
    guard !pendingTrips().isEmpty else { return }

    beginBackgroundTask()
    syncTask = Task { [weak self] in
      await self?.runPass()
      self?.passFinished()
    }
  }

  // MARK: - Passes

  /// Uploads pending trips oldest first, stopping at the first failure. Stopping matters: if the
  /// first upload fails for lack of signal, the rest would too, and the retry covers them all.
  private func runPass() async {
    for trip in pendingTrips() {
      // The background time ran out, or the pass was replaced. What's left waits for the next one.
      if Task.isCancelled { return }
      do {
        try await backend.upload(trip)
        markSynced(trip.id, .now)
        failureCount = 0
      } catch {
        failureCount += 1
        print("Couldn't sync trip \(trip.id), attempt \(failureCount): \(error)")
        scheduleRetry()
        return
      }
    }
  }

  private func passFinished() {
    syncTask = nil
    endBackgroundTask()
    if needsAnotherPass {
      needsAnotherPass = false
      syncNow()
    }
  }

  /// Waits 30 s after the first failure, doubling each time to at most 15 minutes, so a long
  /// stretch without signal doesn't keep the radio busy. A retry only happens while the app is
  /// running; if iOS suspends it first, the next launch, car connection, or iPhone visit catches up.
  private func scheduleRetry() {
    let seconds = min(30 * pow(2, Double(failureCount - 1)), 15 * 60)
    retryTask?.cancel()
    retryTask = Task { [weak self] in
      try? await Task.sleep(for: .seconds(seconds))
      guard !Task.isCancelled else { return }
      self?.syncNow()
    }
  }

  // MARK: - Background time

  /// Asks iOS for about 30 seconds to keep running if Skyway is backgrounded mid-upload,
  /// for example when the driver switches to Maps on the car screen right after ending a trip.
  private func beginBackgroundTask() {
    guard backgroundTaskID == .invalid else { return }
    backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "Sync trips") { [weak self] in
      // Time's up. iOS requires ending the task right here, or it terminates the app. Cancelling
      // the pass is safe: a trip whose upload didn't finish stays pending and is sent again.
      MainActor.assumeIsolated {
        self?.syncTask?.cancel()
        self?.endBackgroundTask()
      }
    }
  }

  private func endBackgroundTask() {
    guard backgroundTaskID != .invalid else { return }
    UIApplication.shared.endBackgroundTask(backgroundTaskID)
    backgroundTaskID = .invalid
  }
}
