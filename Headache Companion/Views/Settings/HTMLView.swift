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
    
    init(dayData: FetchedResults<DayData>) {
        self.dayData = dayData
        self.html = HTMLRenderer(dayData: dayData).renderHTML()
    }

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
            
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(HTMLRenderer(dayData: dayData).renderHTML() ?? "", baseURL: nil)
    }
    
    func getPrintFormatter() -> UIMarkupTextPrintFormatter {
        return UIMarkupTextPrintFormatter(markupText: html ?? "FAILED")
    }
}
