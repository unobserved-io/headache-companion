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
    
    private func loadJson(fileName: String) -> DayData? {
       let decoder = JSONDecoder()
       guard
            let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let thisDayData = try? decoder.decode(DayData.self, from: data)
       else {
            return nil
       }

       return thisDayData
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
