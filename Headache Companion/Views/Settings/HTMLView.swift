//
//  HTMLView.swift
//  Headache Companion
//
//  Created by Ricky Kresslein on 7/13/23.
//

import SwiftUI
import WebKit

struct HTMLView: UIViewRepresentable {
    var dayData: FetchedResults<DayData>
    var html: String?
    
    init(dayData: FetchedResults<DayData>, exportAttacks: Bool, exportMedication: Bool, exportWellbeing: Bool) {
        self.dayData = dayData
        self.html = HTMLRenderer(dayData: dayData, exportAttacks: exportAttacks, exportMedication: exportMedication, exportWellbeing: exportWellbeing).renderHTML()
    }

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
            
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(html ?? "", baseURL: nil)
    }
    
    func getPrintFormatter() -> UIMarkupTextPrintFormatter {
        return UIMarkupTextPrintFormatter(markupText: html ?? "FAILED")
    }
}
