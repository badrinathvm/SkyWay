import CoreTransferable
import Foundation
import UniformTypeIdentifiers

/// The monthly report as a CSV file, for the share sheet. It's written only when shared.
struct ReportCSVFile: Transferable {
  var report: MonthlyReport

  static var transferRepresentation: some TransferRepresentation {
    FileRepresentation(exportedContentType: .commaSeparatedText) { file in
      let url = try ReportFileWriter.write(Data(ReportCSV.make(file.report).utf8), name: file.report.fileName, extension: "csv")
      return SentTransferredFile(url)
    }
  }
}

/// The monthly report as a PDF, for the share sheet. It's drawn only when shared.
struct ReportPDFFile: Transferable {
  var report: MonthlyReport

  static var transferRepresentation: some TransferRepresentation {
    FileRepresentation(exportedContentType: .pdf) { file in
      let url = try ReportFileWriter.write(ReportPDFRenderer(report: file.report).render(), name: file.report.fileName, extension: "pdf")
      return SentTransferredFile(url)
    }
  }
}

/// Writes export files to a temporary folder of their own, so each name is free to use.
enum ReportFileWriter {
  static func write(_ data: Data, name: String, extension fileExtension: String) throws -> URL {
    let folder = URL.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    let url = folder.appending(path: "\(name).\(fileExtension)")
    try data.write(to: url, options: .atomic)
    return url
  }
}

extension MonthlyReport {
  /// "Skyway Report November 2026", the name the shared file gets.
  var fileName: String { "Skyway Report \(title)" }
}
