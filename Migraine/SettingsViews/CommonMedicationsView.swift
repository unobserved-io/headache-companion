//
//  CommonMedicationsView.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/10/23.
//

import SwiftUI

struct CommonMedicationsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: MAppData.entity(),
        sortDescriptors: []
    )
    var mAppData: FetchedResults<MAppData>
    @StateObject var clickedMedication = ClickedMedication(nil)
    @State private var showingSheet = false
    @State private var refreshIt: Bool = true
    
    var body: some View {
        Form {
            if !(mAppData.first?.commonMeds.isEmpty ?? true) {
                Section {
                    ForEach(mAppData.first?.commonMeds ?? []) { medication in
                        Button {
                            clickedMedication.medication = medication
                            showingSheet.toggle()
                        } label: {
                            HStack {
                                // Amount number
                                Text("\(refreshIt ? "" : "")\(medication.amount)")
                                    .font(Font.system(.title).monospacedDigit())
                                    .padding(.trailing)
                                    
                                // Med details
                                HStack {
                                    Text("\(medication.type ?? "Unknown")")
                                        .bold()
                                    Text("(\(medication.dose ?? ""))")
                                }
                            }
                        }
                        .tint(.primary)
                    }
                    .onDelete(perform: deleteMedication)
                }
            }
            
            Button("Add Common Medication") {
                clickedMedication.medication = Medication(context: viewContext)
                showingSheet.toggle()
            }
        }
        .sheet(isPresented: $showingSheet, onDismiss: refreshView) {
            if clickedMedication.medication != nil {
                AddEditCommonMedsView()
                    .environmentObject(clickedMedication)
                    .navigationTitle("Add Common Medication")
                    .presentationDetents([.medium])
            }
        }
    }
    
    private func refreshView() {
        refreshIt.toggle()
    }
    
    private func deleteMedication(at offsets: IndexSet) {
        let index = offsets.first
        if index != nil {
            let medToDelete: Medication? = mAppData.first?.commonMeds[index!]
            if medToDelete != nil {
                viewContext.delete(medToDelete!)
                saveData()
            }
        }
    }
}

struct CommonMedicationsView_Previews: PreviewProvider {
    static var previews: some View {
        CommonMedicationsView()
    }
}
