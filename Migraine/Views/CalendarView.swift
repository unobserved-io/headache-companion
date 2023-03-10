//
//  CalendarView.swift
//  Migraine
//
//  Created by Ricky Kresslein on 2/28/23.
//

import SwiftUI

struct CalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: DayData.entity(),
        sortDescriptors: []
    )
    var dayData: FetchedResults<DayData>
    @StateObject var clickedMedication = ClickedMedication(nil)
    @State private var selectedDay: Date = .now
    @State private var refreshIt: Bool = false
    @State private var attackSheet: Bool = false
    @State private var showingMedSheet: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    DatePicker(
                        "Attacks",
                        selection: $selectedDay,
                        in: Date(timeIntervalSince1970: 0) ... Date.now,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                }
                
                Section("Attacks") {
                    ForEach(getDayData()?.attacks ?? []) { attack in
                        NavigationLink (destination: AttackView(attack: attack)) {
                            if attack.stopTime != nil {
                                Text("\(refreshIt ? "" : "")\(attack.wrappedStartTime.formatted(date: .omitted, time: .shortened)) - \(attack.wrappedStopTime.formatted(date: .omitted, time: .shortened))")
                            } else {
                                Text(attack.wrappedStartTime.formatted(date: .omitted, time: .shortened))
                            }
                        }
                    }
                    .onDelete(perform: deleteAttack)
                    
                    if getDayData()?.attacks.isEmpty ?? true {
                        Text("No attacks")
                    }
                }
                
                Section("Medication") {
                    ForEach(getDayData()?.medications ?? []) { medication in
                        Button {
                            clickedMedication.medication = medication
                            showingMedSheet.toggle()
                        } label: {
                            HStack {
                                // Amount number
                                Text("\(refreshIt ? "" : "")\(medication.amount)")
                                    .font(Font.system(.title).monospacedDigit())
                                    .padding(.trailing)
                                    
                                // Med details
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text("\(medication.type ?? "Unknown")")
                                            .bold()
                                        Text("(\(medication.dose ?? ""))")
                                    }
                                    if medication.effective {
                                        Text("Effective")
                                            .font(.footnote)
                                    } else {
                                        Text("Ineffective")
                                            .font(.footnote)
                                    }
                                }
                                    
                                Spacer()
                                    
                                // Time taken
                                Text("\(medication.wrappedTime.formatted(date: .omitted, time: .shortened))")
                            }
                        }
                        .tint(.primary)
                    }
                    .onDelete(perform: deleteMedication)
                    
                    if getDayData()?.medications.isEmpty ?? true {
                        Text("No medication taken")
                    }
                }
            }
        }
        .onAppear {
            refreshView()
        }
        .sheet(isPresented: $showingMedSheet, onDismiss: refreshView) {
            if clickedMedication.medication != nil {
                AddEditMedicationView()
                    .environmentObject(clickedMedication)
                    .navigationTitle("Edit Medication")
                    .presentationDetents([.medium])
            }
        }
    }
    
    private func refreshView() {
        refreshIt.toggle()
    }
    
    private func getDayData() -> DayData? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let selectedDayFormatted = dateFormatter.string(from: selectedDay)
        return dayData.filter { $0.date == selectedDayFormatted }.first
    }
    
    private func deleteMedication(at offsets: IndexSet) {
        let index = offsets.first
        if index != nil {
            let medToDelete: Medication? = getDayData()?.medications[index!]
            if medToDelete != nil {
                viewContext.delete(medToDelete!)
                saveData()
            }
        }
    }
    
    private func deleteAttack(at offsets: IndexSet) {
        let index = offsets.first
        if index != nil {
            let attackToDelete: Attack? = getDayData()?.attacks[index!]
            if attackToDelete != nil {
                viewContext.delete(attackToDelete!)
                saveData()
            }
        }
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
