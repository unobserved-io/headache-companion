//
//  CustomMedicationTypesView.swift
//  Headache Companion
//
//  Created by Ricky Kresslein on 4/13/23.
//

import SwiftUI

struct CustomMedicationTypesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: MAppData.entity(),
        sortDescriptors: []
    )
    var mAppData: FetchedResults<MAppData>
    @State private var showingAlert: Bool = false
    @State private var medType: String = ""
    @State private var refreshIt: Bool = true
    
    var body: some View {
        Form {
            if !(mAppData.first?.customMedTypes?.isEmpty ?? true) {
                Section {
                    ForEach(mAppData.first?.customMedTypes ?? [], id: \.self) { type in
                        Text("\(refreshIt ? "" : "")\(type)")
                    }
                    .onDelete(perform: deleteSymptom)
                }
            }
            
            Button("Add Custom Medication Type") {
                showingAlert.toggle()
            }
        }
        .alert("Add Medication Type", isPresented: $showingAlert, actions: {
            TextField("Medication Type", text: $medType)
            
            Button("Add", action: {
                if !medType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    if mAppData.first?.customMedTypes == nil {
                        mAppData.first?.customMedTypes = []
                    }
                    if !(mAppData.first?.customMedTypes?.contains(medType) ?? true) {
                        mAppData.first?.customMedTypes?.append(medType)
                        saveData()
                        medType = ""
                        refreshView()
                    }
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
            mAppData.first?.customMedTypes?.remove(at: i)
        }
        saveData()
    }
}

struct CustomMedicationTypesView_Previews: PreviewProvider {
    static var previews: some View {
        CustomMedicationTypesView()
    }
}
