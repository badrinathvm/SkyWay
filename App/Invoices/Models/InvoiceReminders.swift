import Foundation
import UserNotifications

/// Local notifications that remind the person to chase payment: the morning a sent invoice is
/// due, and again three days later if it still hasn't been paid.
enum InvoiceReminders {
  /// When on the day reminders arrive, in the person's time zone.
  private static let reminderHour = 9
  private static let followUpDays = 3

  private static var center: UNUserNotificationCenter { .current() }

  /// Asks for permission to notify, the first time the person sends an invoice. Returns whether
  /// reminders can be delivered.
  @discardableResult
  static func requestAuthorizationIfNeeded() async -> Bool {
    let settings = await center.notificationSettings()
    switch settings.authorizationStatus {
    case .notDetermined:
      return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    case .authorized, .provisional, .ephemeral:
      return true
    default:
      return false
    }
  }

  /// Whether the person turned off Skyway's notifications in Settings.
  static func areDenied() async -> Bool {
    await center.notificationSettings().authorizationStatus == .denied
  }

  /// Schedules or removes the invoice's reminders to match its status: only a sent invoice gets them.
  static func update(for invoice: Invoice) {
    cancel(invoiceID: invoice.id)
    guard invoice.status == .sent else { return }
    let requests = [
      request(for: invoice, daysAfterDue: 0, title: "Payment Due Today"),
      request(for: invoice, daysAfterDue: followUpDays, title: "Payment Overdue"),
    ].compactMap { $0 }
    for request in requests {
      center.add(request)
    }
  }

  static func cancel(invoiceID: Invoice.ID) {
    center.removePendingNotificationRequests(withIdentifiers: identifiers(for: invoiceID))
  }

  /// Rebuilds every invoice's reminders, at launch and after invoices are replaced, so a change
  /// made while the app wasn't running (like from Siri) is caught up.
  static func rescheduleAll(_ invoices: [Invoice]) {
    center.getPendingNotificationRequests { pending in
      let stale = pending.map(\.identifier).filter { $0.hasPrefix(identifierPrefix) }
      center.removePendingNotificationRequests(withIdentifiers: stale)
      invoices.forEach(update(for:))
    }
  }

  // MARK: - Requests

  private static let identifierPrefix = "invoice-reminder-"

  private static func identifiers(for invoiceID: Invoice.ID) -> [String] {
    [0, followUpDays].map { "\(identifierPrefix)\(invoiceID)-\($0)" }
  }

  /// A reminder `daysAfterDue` days after the due date, or nil if that moment has passed.
  private static func request(for invoice: Invoice, daysAfterDue: Int, title: String) -> UNNotificationRequest? {
    let calendar = Calendar.current
    guard let day = calendar.date(byAdding: .day, value: daysAfterDue, to: invoice.dueDate),
      let fireDate = calendar.date(bySettingHour: reminderHour, minute: 0, second: 0, of: day),
      fireDate > .now
    else {
      return nil
    }

    let content = UNMutableNotificationContent()
    content.title = title
    content.body = daysAfterDue == 0
      ? "\(invoice.number) for \(invoice.clientName), \(invoice.amountText), is due today."
      : "\(invoice.number) for \(invoice.clientName), \(invoice.amountText), was due \(invoice.dueDate.formatted(date: .abbreviated, time: .omitted)). Tap to follow up or mark it paid."
    content.sound = .default
    content.threadIdentifier = "invoices"
    // Tapping the reminder opens the invoice.
    content.userInfo = ["url": invoice.url.absoluteString]

    let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
    return UNNotificationRequest(
      identifier: "\(identifierPrefix)\(invoice.id)-\(daysAfterDue)",
      content: content,
      trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    )
  }
}
