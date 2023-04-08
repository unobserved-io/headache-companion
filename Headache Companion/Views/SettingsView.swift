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
    @ObservedObject var storeModel = StoreModel.sharedInstance
    @State private var showingDeleteAlert: Bool = false
    @State private var showingResetAlert: Bool = false
    @State private var showingImportAlert: Bool = false
    @State private var showingExportAlert: Bool = false
    @State private var showingFilePicker: Bool = false
    @State private var showingFileExporter: Bool = false
    @State private var showingPurchaseAlert: Bool = false
    @State private var path: [String] = []
    @AppStorage("lastLaunch") private var lastLaunch = ""
    
    var body: some View {
        NavigationStack(path: $path) {
            Form {
                Section("Custom Inputs") {
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
                    Button {
                        showingExportAlert.toggle()
                    } label: {
                        Label {
                            Text("Export Data")
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "square.and.arrow.up.fill")
                        }
                    }
                    .fileExporter(
                        isPresented: $showingFileExporter,
                        document: JSONDocument(data: getDayDataAsJSON() ?? "[]".data(using: .utf8)!),
                        contentType: .json,
                        defaultFilename: "HeadacheCompanion.json"
                    ) { _ in }
                    
                    Button {
                        if dayData.count > 1 {
                            showingImportAlert.toggle()
                        } else {
                            showingFilePicker.toggle()
                        }
                    } label: {
                        Label {
                            Text("Import Data")
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
        .alert("Delete all data?", isPresented: $showingImportAlert) {
            Button("Import") {
                showingFilePicker.toggle()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Importing data will delete all current data. Do you still want to import?")
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
        .alert("Warning", isPresented: $showingExportAlert) {
            Button("OK") { showingFileExporter.toggle() }
        } message: {
            Text("This only exports the data you've saved for each day. Medication History and any settings you've changed are not exported.")
        }
        .fileImporter(isPresented: $showingFilePicker, allowedContentTypes: [.json]) { result in
            do {
                let fileURL = try result.get()
                if let allDayData = try? JSONSerialization.jsonObject(with: Data(contentsOf: fileURL), options: .allowFragments) as? [[String: Any]]
                {
                    // First, delete all current data
                    deleteAllDayData()
                    
                    // Variables to check for today in imported data
                    let todayString : String = {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        return formatter.string(from: .now)
                    }()
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
                                newAttack.headacheType = Headaches(rawValue: attack["headacheType"] as? Int16 ?? 0)!
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
                                newMedication.effective = medication["effective"] as! Bool
                                newMedication.time = medication["time"] as? Date
                                newMedication.name = medication["name"] as? String
                                newMedication.sideEffects = medication["sideEffects"] as? String
                                newMedication.type = MedTypes(rawValue: medication["type"] as? Int16 ?? 0)!
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
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
