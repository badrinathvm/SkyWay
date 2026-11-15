import SwiftUI

extension Invoice {
  /// Where an invoice stands, including whether it's late, which the stored `Status` can't say.
  enum PaymentState: String, CaseIterable, Sendable {
    case draft
    case sent
    case overdue
    case paid

    var title: String {
      switch self {
      case .draft: "Draft"
      case .sent: "Sent"
      case .overdue: "Overdue"
      case .paid: "Paid"
      }
    }

    var systemImage: String {
      switch self {
      case .draft: "pencil"
      case .sent: "paperplane.fill"
      case .overdue: "exclamationmark.circle.fill"
      case .paid: "checkmark.circle.fill"
      }
    }

    var color: Color {
      switch self {
      case .draft: .orange
      case .sent: .blue
      case .overdue: .red
      case .paid: .green
      }
    }
  }
}
