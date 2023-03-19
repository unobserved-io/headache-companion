//
//  SettingsView.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/10/23.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: MAppData.entity(),
        sortDescriptors: []
    )
    var mAppData: FetchedResults<MAppData>
    
    var body: some View {
        NavigationView {
            Form {
                Section("Custom Inputs") {
                    NavigationLink(destination: CommonMedicationsView()) {
                        Label("Common Medications", systemImage: "pill.fill")
                    }
                    NavigationLink(destination: CustomSymptomsView()) {
                        Label("Add Symptoms", systemImage: "medical.thermometer.fill")
                    }
                }
            }
            .onAppear() {
                if mAppData.first == nil {
                    let newMAppData = MAppData(context: viewContext)
                    newMAppData.doctorNotes = ""
                    newMAppData.customSymptoms = []
                    saveData()
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
