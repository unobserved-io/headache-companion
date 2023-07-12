//
//  CustomHeadacheTypesView.swift
//  Headache Companion
//
//  Created by Ricky Kresslein on 4/11/23.
//

import SwiftUI

struct CustomHeadacheTypesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: MAppData.entity(),
        sortDescriptors: []
    )
    var mAppData: FetchedResults<MAppData>
    @State private var showingAlert: Bool = false
    @State private var headacheType: String = ""
    @State private var refreshIt: Bool = true
    
    var body: some View {
        Form {
            if !(mAppData.first?.customHeadacheTypes?.isEmpty ?? true) {
                Section {
                    ForEach(mAppData.first?.customHeadacheTypes ?? [], id: \.self) { type in
                        Text("\(refreshIt ? "" : "")\(type)")
                    }
                    .onDelete(perform: deleteSymptom)
                }
            }
            
            Button("Add Custom Headache Type") {
                showingAlert.toggle()
            }
        }
        .alert("Add Headache Type", isPresented: $showingAlert, actions: {
            TextField("Headache Type", text: $headacheType)
            
            Button("Add", action: {
                if !headacheType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    if mAppData.first?.customHeadacheTypes == nil {
                        mAppData.first?.customHeadacheTypes = []
                    }
                    if !(mAppData.first?.customHeadacheTypes?.contains(headacheType) ?? true) {
                        mAppData.first?.customHeadacheTypes?.append(headacheType)
                        saveData()
                        headacheType = ""
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
            mAppData.first?.customHeadacheTypes?.remove(at: i)
        }
        saveData()
    }
}

struct CustomHeadacheTypesView_Previews: PreviewProvider {
    static var previews: some View {
        CustomHeadacheTypesView()
    }
}
