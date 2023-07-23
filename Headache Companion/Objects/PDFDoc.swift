//
//  PDFDoc.swift
//  Headache Companion
//
//  Created by Ricky Kresslein on 7/23/23.
//

import SwiftUI
import UniformTypeIdentifiers

struct PDFDoc: FileDocument {
    static var readableContentTypes: [UTType] { [.pdf] }

    var pdfData: Data

    init(pdfData: Data = Data()) {
        self.pdfData = pdfData
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            pdfData = data
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let fileWrapper = FileWrapper(regularFileWithContents: pdfData)
        return fileWrapper
    }
}
