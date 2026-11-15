import AppIntents

/// Lets Siri read whether an invoice is a draft, waiting, overdue or paid, to answer
/// "Who still owes me?"
extension Invoice.PaymentState: AppEnum {
  static let typeDisplayRepresentation: TypeDisplayRepresentation = "Payment Status"

  static let caseDisplayRepresentations: [Invoice.PaymentState: DisplayRepresentation] = [
    .draft: DisplayRepresentation(title: "Draft", subtitle: "Not sent to the client yet"),
    .sent: DisplayRepresentation(title: "Sent", subtitle: "Waiting for payment, not yet due"),
    .overdue: DisplayRepresentation(title: "Overdue", subtitle: "Sent, unpaid, and past its due date"),
    .paid: DisplayRepresentation(title: "Paid", subtitle: "The client has paid"),
  ]
}
