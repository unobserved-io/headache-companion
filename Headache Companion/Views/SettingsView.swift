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
    @ObservedObject var storeModel = StoreModel.sharedInstance
    @State private var showingDeleteAlert: Bool = false
    @State private var showingResetAlert: Bool = false
    @State private var showingDayImportAlert: Bool = false
    @State private var showingMedImportAlert: Bool = false
    @State private var showingDayFilePicker: Bool = false
    @State private var showingMedFilePicker: Bool = false
    @State private var overwriteMedHistory: Bool = false
    @State private var showingDayExporter: Bool = false
    @State private var showingMedExporter: Bool = false
    @State private var showingPurchaseAlert: Bool = false
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
                            Text(storeModel.purchasedIds.isEmpty ? "Regular Medications (Pro)" : "Regular Medications")
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
                            Text(storeModel.purchasedIds.isEmpty ? "Add Symptoms (Pro)" : "Add Symptoms")
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
                            Text(storeModel.purchasedIds.isEmpty ? "Add Headache Types (Pro)" : "Add Headache Types")
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "brain.head.profile")
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
                            Text(storeModel.purchasedIds.isEmpty ? "Activity Colors (Pro)" : "Activity Colors")
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "paintpalette.fill")
                        }
                    }
                }
                
                Section("Data") {
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
                        defaultFilename: "HC-DailyData"
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
                        defaultFilename: "HC-MedHistory"
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
            .navigationDestination(for: String.self) { view in
                if view == "RegularMedicationsView" {
                    RegularMedicationsView()
                } else if view == "CustomSymptomsView" {
                    CustomSymptomsView()
                } else if view == "ActivityColorsView" {
                    ActivityColorsView()
                } else if view == "CustomHeadacheTypesView" {
                    CustomHeadacheTypesView()
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
        .fileImporter(isPresented: $showingDayFilePicker, allowedContentTypes: [.json]) { result in
            do {
                let fileURL = try result.get()
                if let allDayData = try? JSONSerialization.jsonObject(with: Data(contentsOf: fileURL), options: .allowFragments) as? [[String: Any]]
                {
                    // First, delete all current data
                    deleteAllDayData()
                    
                    // Variables to check for today in imported data
                    let todayString : String = dateFormatter.string(from: .now)
                    var todayFound: Bool = false
                    
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
                                let newStopTime = Date(timeIntervalSince1970: attack["stopTime"] as! TimeInterval)
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
            } catch {
                print("Failed to import data: \(error.localizedDescription)")
            }
        }
        .fileImporter(isPresented: $showingMedFilePicker, allowedContentTypes: [.json]) { result in
            do {
                let fileURL = try result.get()
                if let allMedImportData = try? JSONSerialization.jsonObject(with: Data(contentsOf: fileURL), options: .allowFragments) as? [[String: Any]]
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
            } catch {
                print("Failed to import data: \(error.localizedDescription)")
            }
        }
        .onAppear() {
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
        mAppData.first?.activityColors = [
            getData(from: UIColor(Color.gray)) ?? Data(),
            getData(from: UIColor(Color.red)) ?? Data(),
            getData(from: UIColor(Color.yellow)) ?? Data(),
            getData(from: UIColor(Color.green)) ?? Data(),
        ]
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
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
