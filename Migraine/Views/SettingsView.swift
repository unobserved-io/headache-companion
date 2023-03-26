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
    
    var body: some View {
        NavigationView {
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
                        do {
                            let encoder = JSONEncoder()
                            encoder.outputFormatting = .prettyPrinted
                            let jsonData = try encoder.encode(dayData.sorted(by: {$0.date ?? "" < $1.date ?? "" }))
                            print(String(data: jsonData, encoding: .utf8) ?? "")
                        } catch {}
                    } label: {
                        Text("Export Data")
                    }
                    Button {
                        let jsonString = """
[
  {
    "exercise" : 3,
    "diet" : 3,
    "notes" : "",
    "date" : "2023-03-23",
    "relax" : 2,
    "attacks" : [

    ],
    "sleep" : 1,
    "medications" : [

    ],
    "water" : 1
  },
  {
    "exercise" : 3,
    "diet" : 3,
    "notes" : "",
    "date" : "2023-03-24",
    "relax" : 2,
    "attacks" : [

    ],
    "sleep" : 3,
    "medications" : [

    ],
    "water" : 2
  },
  {
    "exercise" : 2,
    "diet" : 2,
    "notes" : "",
    "date" : "2023-03-25",
    "relax" : 3,
    "attacks" : [
      {
        "pressing" : false,
        "id" : "51FF7471-A1A7-47AE-B03D-EA8A7EEA102F",
        "symptoms" : [
            "Sensitivity to sound",
            "Sensitivity to light"
        ],
        "pulsating" : false,
        "otherPainGroup" : 0,
        "otherPainText" : null,
        "painLevel" : 2,
        "stopTime" : 701474555.50431597,
        "pressingSide" : 0,
        "headacheType" : 0,
        "auras" : [
            "Tingling",
            "Visual"
        ],
        "onPeriod" : false,
        "pulsatingSide" : 0,
        "startTime" : 701474487.02191103
      }
    ],
    "sleep" : 2,
    "medications" : [
      {
        "amount" : 2,
        "dose" : "Pills",
        "id" : "D5A26714-BEDF-46C7-B211-0BF277E26BE1",
        "time" : 701467216.79302704,
        "sideEffects" : null,
        "effective" : false,
        "type" : 0,
        "name" : "Tylenol"
      }
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
                                if let attacks = hcDayData["attacks"] as? [[String: Any]] {
                                    for attack in attacks {
                                        let newAttack = Attack(context: viewContext)
                                        newDay.addToAttack(newAttack)
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
                                        newAttack.startTime = attack["startTime"] as? Date
                                        newAttack.stopTime = attack["stopTime"] as? Date
                                        if let auras = attack["auras"] as? [String] {
                                            newAttack.auras = Set(auras)
                                        }
                                        if let symptoms = attack["symptoms"] as? [String] {
                                            newAttack.symptoms = Set(symptoms)
                                        }
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
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
