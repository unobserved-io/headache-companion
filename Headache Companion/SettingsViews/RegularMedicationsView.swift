//
//  CommonMedicationsView.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/10/23.
//

import SwiftUI

struct RegularMedicationsView: View {
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
            if !(mAppData.first?.regularMeds.isEmpty ?? true) {
                ForEach(getMedsSorted(), id: \.key) { medType, medications in
                    Section(medType) {
                        ForEach(medications) { medication in
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
                                            Text("\(medication.name ?? "Unknown")")
                                                .bold()
                                            if !(medication.dose?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) {
                                                Text("(\(medication.dose ?? ""))")
                                            }
                                        }
                                    }
                                }
                                .tint(.primary)
                        }
                        .onDelete(perform: deleteMedication)
                    }
                }
            }
            
            Button("Add Common Medication") {
                clickedMedication.medication = Medication(context: viewContext)
                showingSheet.toggle()
            }
        }
        .sheet(isPresented: $showingSheet, onDismiss: refreshView) {
            if clickedMedication.medication != nil {
                AddEditRegularMedsView()
                    .environmentObject(clickedMedication)
                    .navigationTitle("Add Common Medication")
                    .presentationDetents([.medium])
            }
        }
    }
    
    private func refreshView() {
        refreshIt.toggle()
    }
    
    private func getMedsSorted() -> [(key: String, value: [Medication])] {
        var uniqueMedsSorted: [(key: String, value: [Medication])] = []
        mAppData.first?.regularMeds.forEach { uniqueMed in
            if let index = uniqueMedsSorted.firstIndex(where: {$0.key == uniqueMed.type}) {
                uniqueMedsSorted[index].value.append(uniqueMed)
            } else {
                uniqueMedsSorted.append((uniqueMed.type, [uniqueMed]))
            }
        }
        uniqueMedsSorted.sort(by: { $0.key > $1.key })
        return uniqueMedsSorted
    }
    
    private func deleteMedication(at offsets: IndexSet) {
        let index = offsets.first
        if index != nil {
            let medToDelete: Medication? = mAppData.first?.regularMeds[index!]
            if medToDelete != nil {
                viewContext.delete(medToDelete!)
                saveData()
            }
        }
    }
}

struct CommonMedicationsView_Previews: PreviewProvider {
    static var previews: some View {
        RegularMedicationsView()
    }
}
