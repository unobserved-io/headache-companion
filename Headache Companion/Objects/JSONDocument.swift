//
//  JsonDocument.swift
//  Headache Companion
//
//  Created by Ricky Kresslein on 3/30/23.
//

import SwiftUI
import UniformTypeIdentifiers

struct JSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    var data: Data
    
    init(data: Data = Data()) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            self.data = data
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let todayString: String = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: .now)
        }()
        
        let fileWrapper = FileWrapper(regularFileWithContents: data)
        fileWrapper.preferredFilename = "HeadacheCompanion-\(todayString).json"
        return fileWrapper
    }
}
