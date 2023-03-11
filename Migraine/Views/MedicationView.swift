//
//  MedicationView.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/5/23.
//

import SwiftUI

struct MedicationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest var dayData: FetchedResults<DayData>
    @FetchRequest(
        entity: MAppData.entity(),
        sortDescriptors: []
    )
    var mAppData: FetchedResults<MAppData>
    @StateObject var clickedMedication = ClickedMedication(nil)
    @State private var showingSheet: Bool = false
    @State private var settingsDetent = PresentationDetent.medium
    @State private var refreshIt: Bool = true
    
    // TODO: Fix layout constraint issue when clicking off of DatePicker. May have to do with shortening the sheet
    
    init() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: .now)
        _dayData = FetchRequest(
            sortDescriptors: [],
            predicate: NSPredicate(format: "date = %@", today)
        )
    }
    
    var body: some View {
        List {
            if !(mAppData.first?.commonMeds.isEmpty ?? true) {
                Section("Common Medications") {
                    ForEach(mAppData.first?.commonMeds ?? []) { medication in
                        Button {
                            let newMedication = Medication(context: viewContext)
                            newMedication.id = UUID().uuidString
                            newMedication.name = medication.name
                            newMedication.dose = medication.dose
                            newMedication.amount = medication.amount
                            newMedication.type = medication.type
                            newMedication.effective = true
                            newMedication.time = Date.now
                            dayData.first?.addToMedication(newMedication)
                            saveData()
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
                                    Text("(\(medication.dose ?? ""))")
                                }
                                
                                Spacer()
                                
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .tint(.primary)
                    }
                }
            }
            
            if !(dayData.first?.medications.isEmpty ?? true) {
                Section("Medication Taken") {
                    ForEach(dayData.first?.medications ?? []) { medication in
                        Button {
                            clickedMedication.medication = medication
                            showingSheet.toggle()
                        } label: {
                            MedicationLabelView(medication: medication, refresh: refreshIt)
                        }
                        .tint(.primary)
                    }
                    .onDelete(perform: deleteMedication)
                }
            }
                
            Section {
                Button("Add Medication") {
                    clickedMedication.medication = Medication(context: viewContext)
                    showingSheet.toggle()
                }
            }
        }
        .sheet(isPresented: $showingSheet, onDismiss: refreshView) {
            if clickedMedication.medication != nil {
                AddEditMedicationView()
                    .environmentObject(clickedMedication)
                    .navigationTitle("Add Medication")
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
            let medToDelete: Medication? = dayData.first?.medications[index!]
            if medToDelete != nil {
                viewContext.delete(medToDelete!)
                saveData()
            }
        }
    }
}

struct MedicationView_Previews: PreviewProvider {
    static var previews: some View {
        MedicationView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
