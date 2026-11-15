import Foundation
import FoundationModels

/// The details Apple Intelligence pulls out of a receipt's text.
@Generable(description: "The key details of a purchase receipt")
struct ReceiptExtraction {
  @Guide(description: "The business that issued the receipt, like \"Blue Bottle Coffee\". Use its brand name, not a legal entity or address.")
  var supplier: String

  @Guide(description: "The purchase date in YYYY-MM-DD format, or an empty string if no date is printed.")
  var date: String

  @Guide(description: "The final amount paid, including tax and tip. Not the subtotal.")
  var total: Double

  @Guide(description: "The sales tax, VAT or GST amount, or 0 if none is shown.")
  var tax: Double

  @Guide(description: "The ISO 4217 currency code, like USD, EUR or GBP, judged from symbols and the address.")
  var currencyCode: String

  @Guide(description: "What the purchase was for.")
  var category: ExpenseCategory
}
