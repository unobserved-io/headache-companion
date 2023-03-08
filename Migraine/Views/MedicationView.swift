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
            if !(dayData.first?.medications.isEmpty ?? true) {
                Section {
                    ForEach(dayData.first?.medications ?? []) { medication in
                        Button {
                            clickedMedication.medication = medication
                            showingSheet.toggle()
                        } label: {
                            HStack {
                                // Amount number
                                Text("\(refreshIt ? "" : "")\(medication.amount)")
                                    .bold()
                                    .font(Font.system(.title).monospacedDigit())
                                    .padding(.trailing)
                                    
                                // Med details
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text("\(medication.type ?? "Unknown")")
                                            .bold()
                                        Text("(\(medication.dose ?? ""))")
                                    }
                                    if medication.helpful {
                                        Text("Helpful")
                                            .font(.footnote)
                                    } else {
                                        Text("Not Helpful")
                                            .font(.footnote)
                                    }
                                }
                                    
                                Spacer()
                                    
                                // Time taken
                                Text("\(medication.wrappedTime.formatted(date: .omitted, time: .shortened))")
                                    .bold()
                            }
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
