//
//  SettingsView.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/10/23.
//

import CoreData
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
    @State private var showingDeleteAlert: Bool = false
    @State private var showingResetAlert: Bool = false
    @State private var showingFilePicker: Bool = false
    @State private var showingFileExporter: Bool = false
    @AppStorage("lastLaunch") private var lastLaunch = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Custom Inputs") {
                    NavigationLink(destination: RegularMedicationsView()) {
                        Label("Regular Medications", systemImage: "pill.fill")
                    }
                    NavigationLink(destination: CustomSymptomsView()) {
                        Label("Add Symptoms", systemImage: "medical.thermometer.fill")
                    }
                }
                
                Section("Appearance") {
                    NavigationLink(destination: ActivityColorsView()) {
                        Label("Activity Colors", systemImage: "paintpalette.fill")
                    }
                }
                
                Section("Data") {
                    Button {
                        showingFileExporter.toggle()
                    } label: {
                        Text("Export Data")
                            .foregroundColor(.primary)
                    }
                    .fileExporter(isPresented: $showingFileExporter, document: JSONDocument(data: getDayDataAsJSON() ?? "".data(using: .utf8)!), contentType: .json, defaultFilename: "HeadacheCompanion.json") { _ in }
                    
                    Button {
                        showingFilePicker.toggle()
                    } label: {
                        Text("Import Data")
                            .foregroundColor(.primary)
                    }
                    .fileImporter(isPresented: $showingFilePicker, allowedContentTypes: [.json]) { result in
                        do {
                            // TODO: Ask if the user wants to delete all current data, or merge current data with imported data
                            let fileURL = try result.get()
                            if let allDayData = try? JSONSerialization.jsonObject(with: Data(contentsOf: fileURL), options: .allowFragments) as? [[String: Any]]
                            {
                                for hcDayData in allDayData {
                                    // Check if the day being imported already exists
                                    var newDay: DayData
                                    if let duplicateData = dayData.first(where: { $0.date == hcDayData["date"] as? String }) {
                                        newDay = duplicateData
                                    } else {
                                        newDay = DayData(context: viewContext)
                                    }
                                    newDay.date = hcDayData["date"] as? String
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
                            }
                        } catch {}
                    }
                    
                    Button {
                        showingResetAlert.toggle()
                    } label: {
                        Label{
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
        }
        .alert("Delete everything?", isPresented: $showingDeleteAlert) {
            Button("Delete") {
                deleteAllData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to erase all of your data? This is irreversible.")
        }
        .alert("Reset settings?", isPresented: $showingResetAlert) {
            Button("Reset") {
                resetSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to reset all settings? This is irreversible.")
        }
    }
    
    private func deleteAllData() {
        let entityNames = PersistenceController.shared.container.managedObjectModel.entities.map({ $0.name!})
        entityNames.forEach { entityName in
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            fetchRequest.returnsObjectsAsFaults = false
            do {
                let results = try viewContext.fetch(fetchRequest)
                for object in results {
                    guard let objectData = object as? NSManagedObject else {continue}
                    viewContext.delete(objectData)
                }
            } catch let error {
                print("Detele all data error :", error)
            }
        }
        lastLaunch = ""
        
        initializeMAppData()
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
//        let temporaryDirectory = FileManager.default.temporaryDirectory
//        let todayString : String = {
//            let formatter = DateFormatter()
//            formatter.dateFormat = "yyyy-MM-dd"
//            return formatter.string(from: .now)
//        }()
//        let fileURL = temporaryDirectory.appendingPathComponent("HeadacheCompanion-\(todayString).json")
//        do {
//            let jsonData = try encoder.encode(dayData.sorted(by: {$0.date ?? "" < $1.date ?? "" }))
//            try jsonData.write(to: fileURL)
//        } catch {
//            print("Error exporting data: \(error.localizedDescription)")
//        }
//
//        return fileURL
        return try? encoder.encode(dayData.sorted(by: {$0.date ?? "" < $1.date ?? "" }))
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
