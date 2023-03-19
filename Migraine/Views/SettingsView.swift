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
    @State private var showingAlert: Bool = false
    
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
                    Label("Reset Settings", systemImage: "gear.badge.xmark")
                    Button {
                        showingAlert.toggle()
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
        .alert("Delete everything?", isPresented: $showingAlert) {
            Button("Delete") {
                deleteAllData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to erase all of your data? This is irreversible.")
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
        
        // Re-initialize MAppData
        let newMAppData = MAppData(context: viewContext)
        newMAppData.doctorNotes = ""
        newMAppData.customSymptoms = []
        newMAppData.activityColors = [
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
