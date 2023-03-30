//
//  SettingsView.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/10/23.
//

import CoreData
import SwiftUI

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
                    ShareLink(item: getDayDataAsJSON()) {
                        Text("Export")
                    }
                    Button {
                        let jsonString = """
[
  {
    "exercise" : 0,
    "diet" : 1,
    "notes" : "",
    "date" : "2023-03-30",
    "relax" : 0,
    "attacks" : [
      {
        "pressing" : true,
        "id" : "89F76F11-64BE-4ECB-824A-0789E7DDFC78",
        "symptoms" : [
          "Neck pain",
          "Sensitivity to sound"
        ],
        "pulsating" : false,
        "otherPainGroup" : 0,
        "otherPainText" : null,
        "painLevel" : 2,
        "stopTime" : 1680166306.6742392,
        "pressingSide" : 2,
        "headacheType" : 0,
        "auras" : [
          "Tingling",
          "Visual"
        ],
        "onPeriod" : false,
        "pulsatingSide" : 0,
        "startTime" : 1680166283.014658
      }
    ],
    "sleep" : 2,
    "medications" : [

    ],
    "water" : 3
  }
]
"""
                        if let allDayData = try? JSONSerialization.jsonObject(with: Data(jsonString.utf8), options: .allowFragments) as? [[String: Any]]
                        {
                            for hcDayData in allDayData {
                                let newDay = DayData(context: viewContext)
                                newDay.date = hcDayData["date"] as? String
                                newDay.diet = ActivityRanks(rawValue: hcDayData["diet"] as? Int16 ?? 0)!
                                newDay.exercise = ActivityRanks(rawValue: hcDayData["exercise"] as? Int16 ?? 0)!
                                newDay.relax = ActivityRanks(rawValue: hcDayData["relax"] as? Int16 ?? 0)!
                                newDay.sleep = ActivityRanks(rawValue: hcDayData["sleep"] as? Int16 ?? 0)!
                                newDay.water = ActivityRanks(rawValue: hcDayData["water"] as? Int16 ?? 0)!
                                newDay.notes = hcDayData["notes"] as! String
//                                saveData()
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
//                                        newAttack.startTime = attack["startTime"] as? Date
                                        let newStopTime = Date(timeIntervalSince1970: attack["stopTime"] as! TimeInterval)
//                                        newAttack.stopTime = attack["stopTime"] as? Date
                                        newAttack.stopTime = newStopTime
                                        if let auras = attack["auras"] as? [String] {
                                            newAttack.auras = Set(auras)
                                        }
                                        if let symptoms = attack["symptoms"] as? [String] {
                                            newAttack.symptoms = Set(symptoms)
                                        }
                                        newDay.addToAttack(newAttack)
//                                        saveData()
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
//                                        saveData()
                                    }
                                }
                            }
                            saveData()
                        }
                    } label: {
                        Text("Import Data")
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
    
    private func getDayDataAsJSON() -> URL {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = .prettyPrinted
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let todayString : String = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: .now)
        }()
        let fileURL = temporaryDirectory.appendingPathComponent("HeadacheCompanion-\(todayString).json")
        do {
            let jsonData = try encoder.encode(dayData.sorted(by: {$0.date ?? "" < $1.date ?? "" }))
            try jsonData.write(to: fileURL)
        } catch {
            print("Error exporting data: \(error.localizedDescription)")
        }
        
        return fileURL
//        return try? encoder.encode(dayData.sorted(by: {$0.date ?? "" < $1.date ?? "" }))
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
