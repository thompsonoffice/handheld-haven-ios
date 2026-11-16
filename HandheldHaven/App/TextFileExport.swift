import SwiftUI
import UniformTypeIdentifiers

/// A plain text file for ShareLink. The text is the entry itself, not a link.
struct TextFileExport: Transferable {
    let fileName: String
    let text: String

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .plainText) { item in
            let folder = FileManager.default.temporaryDirectory
                .appendingPathComponent("HandheldHavenShare", isDirectory: true)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let url = folder.appendingPathComponent(item.fileName)
            try Data(item.text.utf8).write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
        ProxyRepresentation(exporting: { (item: TextFileExport) in item.text })
    }
}
