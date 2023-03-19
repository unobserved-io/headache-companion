//
//  CustomSymptomsView.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/19/23.
//

import SwiftUI

struct CustomSymptomsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: MAppData.entity(),
        sortDescriptors: []
    )
    var mAppData: FetchedResults<MAppData>
    @State private var showingAlert: Bool = false
    @State private var symptomName: String = ""
    @State private var refreshIt: Bool = true
    
    var body: some View {
        Form {
            if !(mAppData.first?.customSymptoms?.isEmpty ?? true) {
                Section {
                    ForEach(mAppData.first?.customSymptoms ?? [], id: \.self) { symptom in
                        Text("\(refreshIt ? "" : "")\(symptom)")
                    }
                    .onDelete(perform: deleteSymptom)
                }
            }
            
            Button("Add Custom Symptom") {
                showingAlert.toggle()
            }
        }
        .alert("Add Symptom", isPresented: $showingAlert, actions: {
            TextField("Symptom", text: $symptomName)
            
            Button("Add", action: {
                if mAppData.first?.customSymptoms == nil {
                    mAppData.first?.customSymptoms = []
                }
                if !(mAppData.first?.customSymptoms?.contains(symptomName) ?? true) {
                    mAppData.first?.customSymptoms?.append(symptomName)
                    saveData()
                    symptomName = ""
                    refreshView()
                }
            })
            Button("Cancel", role: .cancel, action: {})
        })
    }
    
    private func refreshView() {
        refreshIt.toggle()
    }
    
    private func deleteSymptom(at offsets: IndexSet) {
        for i in offsets {
            mAppData.first?.customSymptoms?.remove(at: i)
        }
        saveData()
    }
}

struct CustomSymptomsView_Previews: PreviewProvider {
    static var previews: some View {
        CustomSymptomsView()
    }
}
