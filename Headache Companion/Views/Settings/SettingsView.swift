//
//  SettingsView.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/10/23.
//

import CoreData
import StoreKit
import SwiftUI
import UniformTypeIdentifiers
import WebKit

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: MAppData.entity(),
        sortDescriptors: []
    )
    var mAppData: FetchedResults<MAppData>
    @FetchRequest(
        entity: DayData.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \DayData.date, ascending: true)]
    )
    var dayData: FetchedResults<DayData>
    @FetchRequest(
        entity: MedHistory.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \MedHistory.stopDate, ascending: true)]
    )
    var medHistory: FetchedResults<MedHistory>
    let todaysDate = dateFormatter.string(from: Date.now)
    @ObservedObject var storeModel = StoreModel.shared
    @State private var showingDeleteAlert: Bool = false
    @State private var showingResetAlert: Bool = false
    @State private var showingDayImportAlert: Bool = false
    @State private var showingMedImportAlert: Bool = false
    @State private var showingDayFilePicker: Bool = false
    @State private var showingMedFilePicker: Bool = false
    @State private var overwriteMedHistory: Bool = false
    @State private var showingDayExporter: Bool = false
    @State private var showingMedExporter: Bool = false
    @State private var showingPDFExporter: Bool = false
    @State private var showingPDFAspectsPicker: Bool = false
    @State private var showingPurchaseAlert: Bool = false
    @State private var exportAttacks: Bool = true
    @State private var exportMedication: Bool = false
    @State private var exportWellbeing: Bool = false
    @AppStorage("attacksEndWithDay") private var attacksEndWithDay: Bool = true
    @State private var path: [String] = []
    @AppStorage("lastLaunch") private var lastLaunch = ""
    private var effectiveBinding: Binding<Effectiveness> {
        Binding {
            mAppData.first?.defaultEffectiveness ?? Effectiveness.effective
        } set: {
            mAppData.first?.defaultEffectiveness = $0
            saveData()
        }
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            Form {
                Section("General") {
                    Toggle(isOn: $attacksEndWithDay) {
                        Text("Attacks end at end of day")
                    }
                    .onChange(of: attacksEndWithDay) { newVal in
                        mAppData.first?.attacksEndWithDay = newVal
                        saveData()
                    }
                    
                    // Default effectiveness
                    Picker(selection: effectiveBinding) {
                        Text("Effective").tag(Effectiveness.effective)
                        Text("Ineffective").tag(Effectiveness.ineffective)
                        Text("—").tag(Effectiveness.none)
                    } label: {
                        Text("Default Effectiveness")
                    }
                }
                
                Section("Custom Inputs") {
                    // Add regular medications
                    Button {
                        if storeModel.purchasedIds.isEmpty {
                            showingPurchaseAlert.toggle()
                        } else {
                            path.append("RegularMedicationsView")
                        }
                    } label: {
                        Label {
                            TextWithBadge("Regular Medications")
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "pill.fill")
                        }
                    }
                    
                    // Add custom symptoms
                    Button {
                        if storeModel.purchasedIds.isEmpty {
                            showingPurchaseAlert.toggle()
                        } else {
                            path.append("CustomSymptomsView")
                        }
                    } label: {
                        Label {
                            TextWithBadge("Add Symptoms")
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "medical.thermometer.fill")
                        }
                    }
                    
                    // Add custom headache types
                    Button {
                        if storeModel.purchasedIds.isEmpty {
                            showingPurchaseAlert.toggle()
                        } else {
                            path.append("CustomHeadacheTypesView")
                        }
                    } label: {
                        Label {
                            TextWithBadge("Add Headache Types")
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "brain.head.profile")
                        }
                    }
                    
                    // Add custom medication types
                    Button {
                        if storeModel.purchasedIds.isEmpty {
                            showingPurchaseAlert.toggle()
                        } else {
                            path.append("CustomMedicationTypesView")
                        }
                    } label: {
                        Label {
                            TextWithBadge("Add Medication Types")
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "pills.fill")
                        }
                    }
                }
                
                Section("Appearance") {
                    Button {
                        if storeModel.purchasedIds.isEmpty {
                            showingPurchaseAlert.toggle()
                        } else {
                            path.append("ActivityColorsView")
                        }
                    } label: {
                        Label {
                            TextWithBadge("Activity Colors")
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "paintpalette.fill")
                        }
                    }
                }
                
                Section("Data") {
                    // Export Data to PDF
                    Button {
                        if storeModel.purchasedIds.isEmpty {
                            showingPurchaseAlert.toggle()
                        } else {
                            showingPDFAspectsPicker.toggle()
                        }
                    } label: {
                        Label {
                            TextWithBadge("Export to PDF")
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "list.clipboard.fill")
                        }
                    }
                    // Export DayData
                    Button {
                        showingDayExporter.toggle()
                    } label: {
                        Label {
                            Text("Export Daily Data")
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "square.and.arrow.up.fill")
                        }
                    }
                    .fileExporter(
                        isPresented: $showingDayExporter,
                        document: JSONDocument(data: getDayDataAsJSON() ?? "[]".data(using: .utf8)!),
                        contentType: .json,
                        defaultFilename: "HC-DailyData-\(todaysDate)"
                    ) { _ in }
                    
                    // Export MedHistory data
                    Button {
                        showingMedExporter.toggle()
                    } label: {
                        Label {
                            Text("Export Medication History")
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "square.and.arrow.up.fill")
                        }
                    }
                    .fileExporter(
                        isPresented: $showingMedExporter,
                        document: JSONDocument(data: getMedHistoryAsJSON() ?? "[]".data(using: .utf8)!),
                        contentType: .json,
                        defaultFilename: "HC-MedHistory-\(todaysDate)"
                    ) { _ in }
                    
                    // Import DayData
                    Button {
                        if dayData.count > 1 {
                            showingDayImportAlert.toggle()
                        } else {
                            showingDayFilePicker.toggle()
                        }
                    } label: {
                        Label {
                            Text("Import Daily Data")
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "square.and.arrow.down.fill")
                        }
                    }
                    .fileImporter(isPresented: $showingDayFilePicker, allowedContentTypes: [.json]) { result in
                        do {
                            let fileURL = try result.get()
                            if fileURL.startAccessingSecurityScopedResource() {
                                let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
                                if let allDayData = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: Any]]
                                {
                                    // First, delete all current data
                                    deleteAllDayData()
                                    
                                    // Variables to check for today in imported data
                                    let todayString: String = dateFormatter.string(from: .now)
                                    var todayFound = false
                                    
                                    for hcDayData in allDayData {
                                        // Check if the day being imported already exists
                                        var newDay: DayData
                                        if let duplicateData = dayData.first(where: { $0.date == hcDayData["date"] as? String }) {
                                            viewContext.delete(duplicateData)
                                        }
                                        newDay = DayData(context: viewContext)
                                        newDay.date = hcDayData["date"] as? String
                                        // Check for today in imported data
                                        if newDay.date == todayString {
                                            todayFound = true
                                        }
                                        newDay.diet = ActivityRanks(rawValue: hcDayData["diet"] as? Int16 ?? 0)!
                                        newDay.exercise = ActivityRanks(rawValue: hcDayData["exercise"] as? Int16 ?? 0)!
                                        newDay.relax = ActivityRanks(rawValue: hcDayData["relax"] as? Int16 ?? 0)!
                                        newDay.sleep = ActivityRanks(rawValue: hcDayData["sleep"] as? Int16 ?? 0)!
                                        newDay.water = ActivityRanks(rawValue: hcDayData["water"] as? Int16 ?? 0)!
                                        newDay.notes = hcDayData["notes"] as! String
                                        if let attacks = hcDayData["attacks"] as? [[String: Any]] {
                                            for attack in attacks {
                                                let newAttack = Attack(context: viewContext)
                                                newAttack.id = attack["id"] as? String
                                                newAttack.headacheType = attack["headacheType"] as! String
                                                newAttack.otherPainGroup = attack["otherPainGroup"] as! Int16
                                                newAttack.otherPainText = attack["otherPainText"] as? String
                                                newAttack.painLevel = attack["painLevel"] as! Double
                                                newAttack.pressing = attack["pressing"] as! Bool
                                                newAttack.pressingSide = Sides(rawValue: attack["pressingSide"] as? Int16 ?? 0)!
                                                newAttack.pulsating = attack["pulsating"] as! Bool
                                                newAttack.pulsatingSide = Sides(rawValue: attack["pulsatingSide"] as? Int16 ?? 0)!
                                                newAttack.onPeriod = attack["onPeriod"] as! Bool
                                                let newStartTime = Date(timeIntervalSince1970: attack["startTime"] as! TimeInterval)
                                                newAttack.startTime = newStartTime
                                                var newStopTime: Date? = nil
                                                if attack["stopTime"] as? String != nil {
                                                    newStopTime = Date(timeIntervalSince1970: attack["stopTime"] as! TimeInterval)
                                                }
                                                newAttack.stopTime = newStopTime
                                                if let auras = attack["auras"] as? [String] {
                                                    newAttack.auras = Set(auras)
                                                }
                                                if let symptoms = attack["symptoms"] as? [String] {
                                                    newAttack.symptoms = Set(symptoms)
                                                }
                                                newDay.addToAttack(newAttack)
                                            }
                                        }
                                        if let medications = hcDayData["medications"] as? [[String: Any]] {
                                            for medication in medications {
                                                let newMedication = Medication(context: viewContext)
                                                newDay.addToMedication(newMedication)
                                                newMedication.id = medication["id"] as? String
                                                newMedication.amount = medication["amount"] as! Int32
                                                newMedication.dose = medication["dose"] as? String
                                                newMedication.effective = Effectiveness(rawValue: medication["effective"] as? Int16 ?? 2)!
                                                newMedication.time = medication["time"] as? Date
                                                newMedication.name = medication["name"] as? String
                                                newMedication.sideEffects = medication["sideEffects"] as? String
                                                newMedication.type = medication["type"] as! String
                                            }
                                        }
                                    }
                                    saveData()
                                    
                                    // Reload app if today is not found to build it
                                    if !todayFound {
                                        lastLaunch = ""
                                    }
                                }
                            }
                            fileURL.stopAccessingSecurityScopedResource()
                        } catch {
                            print("Failed to import data: \(error.localizedDescription)")
                        }
                    }
                    
                    // Import MedHistory
                    Button {
                        if !medHistory.isEmpty {
                            showingMedImportAlert.toggle()
                        } else {
                            showingMedFilePicker.toggle()
                        }
                    } label: {
                        Label {
                            Text("Import Medication History")
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "square.and.arrow.down.fill")
                        }
                    }
                    .fileImporter(isPresented: $showingMedFilePicker, allowedContentTypes: [.json]) { result in
                        do {
                            let fileURL = try result.get()
                            if fileURL.startAccessingSecurityScopedResource() {
                                let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
                                if let allMedImportData = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: Any]]
                                {
                                    // Delete all current data if user requested
                                    if overwriteMedHistory {
                                        deleteAllMedHistory()
                                    }
                                    
                                    for hcMedHistory in allMedImportData {
                                        var newStartDate: Date? = nil
                                        var newStopDate: Date? = nil
                                        if hcMedHistory["startDate"] as? TimeInterval != nil {
                                            newStartDate = Date(timeIntervalSince1970: hcMedHistory["startDate"] as! TimeInterval)
                                        }
                                        if hcMedHistory["stopDate"] as? TimeInterval != nil {
                                            newStopDate = Date(timeIntervalSince1970: hcMedHistory["stopDate"] as! TimeInterval)
                                        }
                                        
                                        // Check if the MedHistory being imported already exists
                                        if !overwriteMedHistory {
                                            if let duplicateData = medHistory.first(where: { $0.id == hcMedHistory["id"] as? String }) {
                                                viewContext.delete(duplicateData)
                                            }
                                        }
                                        
                                        let newMedHistory = MedHistory(context: viewContext)
                                        newMedHistory.startDate = newStartDate
                                        newMedHistory.startDate = newStopDate
                                        newMedHistory.id = hcMedHistory["id"] as? String
                                        newMedHistory.name = hcMedHistory["name"] as! String
                                        newMedHistory.amount = hcMedHistory["amount"] as! Int32
                                        newMedHistory.dose = hcMedHistory["dose"] as! String
                                        newMedHistory.frequency = hcMedHistory["frequency"] as! String
                                        newMedHistory.effective = Effectiveness(rawValue: hcMedHistory["effective"] as? Int16 ?? 2)!
                                        newMedHistory.notes = hcMedHistory["notes"] as! String
                                        newMedHistory.type = hcMedHistory["type"] as! String
                                        newMedHistory.sideEffects = hcMedHistory["sideEffects"] as? Set<String>
                                    }
                                    saveData()
                                }
                            }
                            fileURL.stopAccessingSecurityScopedResource()
                        } catch {
                            print("Failed to import data: \(error.localizedDescription)")
                        }
                    }
                    
                    Button {
                        showingResetAlert.toggle()
                    } label: {
                        Label {
                            Text("Reset Settings")
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "gear.badge.xmark")
                        }
                    }
                    Button {
                        showingDeleteAlert.toggle()
                    } label: {
                        Label {
                            Text("Delete Data")
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "folder.fill.badge.minus")
                        }
                    }
                }
            }
            .navigationBarTitle("Settings")
            .navigationDestination(for: String.self) { view in
                if view == "RegularMedicationsView" {
                    RegularMedicationsView()
                } else if view == "CustomSymptomsView" {
                    CustomSymptomsView()
                } else if view == "ActivityColorsView" {
                    ActivityColorsView()
                } else if view == "CustomHeadacheTypesView" {
                    CustomHeadacheTypesView()
                } else if view == "CustomMedicationTypesView" {
                    CustomMedicationTypesView()
                } else if view == "PDFExport" {
                    let htmlView = HTMLView(dayData: dayData, exportAttacks: exportAttacks, exportMedication: exportMedication, exportWellbeing: exportWellbeing)
                    htmlView
                        .toolbar {
                            ToolbarItem {
                                Button {
                                    showingPDFExporter.toggle()
                                } label: {
                                    Text("PDF")
                                }
                                .fileExporter(
                                    isPresented: $showingPDFExporter,
                                    document: createPDF(from: htmlView),
                                    contentType: .pdf,
                                    defaultFilename: "HC-Data-\(todaysDate)"
                                ) { _ in }
                            }
                        }
                }
            }
        }
        .alert("Delete everything?", isPresented: $showingDeleteAlert) {
            Button("Delete") {
                deleteAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to erase all of your data? This is irreversible.")
        }
        .alert("Reset settings?", isPresented: $showingResetAlert) {
            Button("Reset") {
                resetSettings()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to reset all settings? This is irreversible.")
        }
        .alert("Delete all data?", isPresented: $showingDayImportAlert) {
            Button("Import") {
                showingDayFilePicker.toggle()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Importing data will delete all current data. Do you still want to import?")
        }
        .sheet(isPresented: $showingPDFAspectsPicker) {
            VStack {
                Toggle(isOn: $exportAttacks) {
                    Text("Attacks")
                }
                Toggle(isOn: $exportMedication) {
                    Text("Medication")
                }
                Toggle(isOn: $exportWellbeing) {
                    Text("Well-Being")
                }
                HStack {
                    Button("Cancel", role: .cancel) {
                        showingPDFAspectsPicker = false
                    }
                    .buttonStyle(.bordered)
                    Button("Export") {
                        path.append("PDFExport")
                        showingPDFAspectsPicker = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                    .disabled(!exportAttacks && !exportMedication && !exportWellbeing)
                }
                .padding(.top, 10)
            }
            .padding(.horizontal, 20)
            .presentationDetents([.exporter])
        }
        .alert("Merge or Overwrite?", isPresented: $showingMedImportAlert) {
            Button("Overwrite") {
                overwriteMedHistory = true
                showingMedFilePicker.toggle()
            }
            Button("Merge") {
                overwriteMedHistory = false
                showingMedFilePicker.toggle()
            }
        } message: {
            Text("Do you want the imported data to merge with or overwrite your current medication history?")
        }
        .alert("Go Pro?", isPresented: $showingPurchaseAlert) {
            if let product = storeModel.products.first {
                Button("Upgrade (\(product.displayPrice))") {
                    Task {
                        try await storeModel.purchase()
                    }
                }
                Button("Restore purchase") {
                    Task {
                        try await AppStore.sync()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This feature is only availble in the Pro version. Upgrade now to access it.")
        }
        .onAppear {
            // Reset segmented pickers to be even (Necessary for long languages)
            UISegmentedControl.appearance().apportionsSegmentWidthsByContent = false
            Task {
                try await storeModel.fetchProducts()
            }
        }
    }
    
    private func deleteAllData() {
        let entityNames = PersistenceController.shared.container.managedObjectModel.entities.map { $0.name! }
        entityNames.forEach { entityName in
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            fetchRequest.returnsObjectsAsFaults = false
            do {
                let results = try viewContext.fetch(fetchRequest)
                for object in results {
                    guard let objectData = object as? NSManagedObject else { continue }
                    viewContext.delete(objectData)
                }
            } catch {
                print("Detele all data error :", error)
            }
        }
        lastLaunch = ""
        
        initializeMAppData()
    }
    
    private func deleteAllDayData() {
        dayData.forEach { day in
            viewContext.delete(day)
        }
        saveData()
    }
    
    private func deleteAllMedHistory() {
        medHistory.forEach { medication in
            viewContext.delete(medication)
        }
        saveData()
    }
    
    private func resetSettings() {
        mAppData.first?.getsPeriod = false
        mAppData.first?.customSymptoms = []
        mAppData.first?.customAuras = []
        mAppData.first?.customHeadacheTypes = []
        mAppData.first?.customMedTypes = []
        mAppData.first?.customSideEffects = []
        mAppData.first?.activityColors = [
            "8E8E93FF", // Gray
            "EB4E3DFF", // Red
            "F7CE46FF", // Yellow
            "65C466FF", // Green
        ]
        mAppData.first?.launchDay = Calendar.current.startOfDay(for: .now)
        saveData()
    }
    
    private func getDayDataAsJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = .prettyPrinted
        return try? encoder.encode(dayData.sorted(by: { $0.date ?? "" < $1.date ?? "" }))
    }
    
    private func getMedHistoryAsJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = .prettyPrinted
        return try? encoder.encode(medHistory.sorted(by: { $0.stopDate ?? Date.now > $1.stopDate ?? Date.now }))
    }
    
    private func createPDF(from htmlView: HTMLView) -> PDFDoc {
        let render = UIPrintPageRenderer()
        let printFormatter = htmlView.getPrintFormatter()
        render.addPrintFormatter(printFormatter, startingAtPageAt: 0)

        let page = CGRect(x: 0, y: 0, width: 612, height: 791) // US Letter, 72 dpi
        let printable = page.insetBy(dx: 0, dy: 40)

        render.setValue(NSValue(cgRect: page), forKey: "paperRect")
        render.setValue(NSValue(cgRect: printable), forKey: "printableRect")

        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, CGRect.zero, nil)

        for i in 1 ... render.numberOfPages {
            UIGraphicsBeginPDFPage()
            let bounds = UIGraphicsGetPDFContextBounds()
            render.drawPage(at: i - 1, in: bounds)
        }

        UIGraphicsEndPDFContext()
        
        return PDFDoc(pdfData: pdfData as Data)
    }
}
