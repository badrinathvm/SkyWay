import CoreTransferable
import Foundation

/// An invoice as a PDF file, for the share sheet. It's drawn only when shared, so it always
/// has the latest status and business details.
struct InvoicePDFFile: Transferable {
  var invoice: Invoice

  /// "Invoice INV-0002 Acme Studio".
  var fileName: String { "Invoice \(invoice.number) \(invoice.clientName)" }

  static var transferRepresentation: some TransferRepresentation {
    FileRepresentation(exportedContentType: .pdf) { file in
      let data = InvoicePDFRenderer(invoice: file.invoice, business: .current).render()
      return SentTransferredFile(try ReportFileWriter.write(data, name: file.fileName, extension: "pdf"))
    }
  }
}
