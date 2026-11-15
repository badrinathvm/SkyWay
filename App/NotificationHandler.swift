import UserNotifications

/// Shows Skyway's notifications while the app is open, and opens what a notification is about
/// when it's tapped, like the invoice a payment reminder is for.
final class NotificationHandler: NSObject, UNUserNotificationCenterDelegate {
  static let shared = NotificationHandler()

  /// Set at launch, before any notification can arrive.
  func activate() {
    UNUserNotificationCenter.current().delegate = self
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification
  ) async -> UNNotificationPresentationOptions {
    [.banner, .list, .sound]
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse
  ) async {
    guard let link = response.notification.request.content.userInfo["url"] as? String,
      let url = URL(string: link)
    else {
      return
    }
    await AppNavigator.shared.open(url)
  }
}
