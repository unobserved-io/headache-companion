//
//  AddMedicationView.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/5/23.
//

import SwiftUI

struct AddEditMedicationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var medication: ClickedMedication
    @FetchRequest var dayData: FetchedResults<DayData>
    let dayTaken: Date
    @State var medName: String = ""
    @State var medType: MedTypes = .symptomRelieving
    @State var medDose: String = ""
    @State var medAmount: Int32 = 1
    @State var medTime: Date = .now
    @State var medEffective: Effectiveness = .none
    @State var showingNameAlert: Bool = false
    
    init(dayTaken: Date = .now) {
        self.dayTaken = dayTaken
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: dayTaken)
        _dayData = FetchRequest(
            sortDescriptors: [],
            predicate: NSPredicate(format: "date = %@", today)
        )
    }
    
    var body: some View {
        Form {
            // Type field
            LabeledContent {
                TextField("Name", text: $medName, prompt: Text("Ibuprofen, Aspirin, etc."))
                    .multilineTextAlignment(.trailing)
            } label: {
                Text("Name")
                    .padding(.trailing)
            }
            
            // Dose field
            LabeledContent {
                TextField("Dose", text: $medDose, prompt: Text("20 mg, 50 ml, etc."))
                    .multilineTextAlignment(.trailing)
            } label: {
                Text("Dose")
                    .padding(.trailing)
            }

            // Amount stepper
            HStack {
                Text("Amount")
                Spacer()
                Text("\(medAmount)")
                    .bold()
                    .padding(.trailing)
                Stepper("\(medAmount)", value: $medAmount, in: 1...25)
                    .labelsHidden()
            }
            
            // Type picker
            Picker("Type", selection: $medType) {
                Text("Symptom Relieving").tag(MedTypes.symptomRelieving)
                Text("Preventive").tag(MedTypes.preventive)
                Text("Other").tag(MedTypes.other)
            }
            
            // Time picker
            DatePicker(
                "Time",
                selection: $medTime,
                in: timeRange(),
                displayedComponents: [.hourAndMinute]
            )
            
            // Effective picker
            Picker("Effective", selection: $medEffective) {
                Text("Effective").tag(Effectiveness.effective)
                Text("Ineffective").tag(Effectiveness.ineffective)
                Image(systemName: "minus.circle").tag(Effectiveness.none)
            }
            .pickerStyle(.segmented)
            
            // Save & Cancel buttons
            Section {
                // Save
                Button {
                    if medName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        showingNameAlert.toggle()
                    } else {
                        medication.medication?.name = medName
                        medication.medication?.type = medType
                        medication.medication?.dose = medDose
                        medication.medication?.amount = medAmount
                        medication.medication?.time = medTime
                        medication.medication?.effective = medEffective
                        
                        if medication.medication?.id == nil {
                            // New medication, give it an id and add to Day
                            medication.medication?.id = UUID().uuidString
                            if medication.medication != nil {
                                if !dayData.isEmpty {
                                    dayData.first?.addToMedication(medication.medication!)
                                } else {
                                    let dateFormatter = DateFormatter()
                                    dateFormatter.dateFormat = "yyyy-MM-dd"
                                    let dateString = dateFormatter.string(from: dayTaken)
                                    
                                    let newDay = DayData(context: viewContext)
                                    newDay.date = dateString
                                    newDay.addToMedication(medication.medication!)
                                }
                            }
                        }
                        
                        saveData()
                        dismiss()
                    }
                } label: {
                    Text("Save")
                }
                
                // Delete any new Medication & cancel
                Button(role: .destructive) {
                    if medication.medication != nil && medication.medication?.id == nil {
                        // New medication - delete it
                        viewContext.delete(medication.medication!)
                        saveData()
                    }
                    dismiss()
                } label: {
                    Text("Cancel")
                }
            }
        }
        .onAppear() {
            if medication.medication != nil && medication.medication?.id != nil {
                // Medication not nil - get values
                medName = medication.medication?.name ?? ""
                medDose = medication.medication?.dose ?? ""
                medAmount = medication.medication?.amount ?? 0
                medTime = medication.medication?.time ?? Date.now
                medEffective = medication.medication?.effective ?? .none
            }
        }
        .alert("Name is empty", isPresented: $showingNameAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The \"Name\" field cannot be empty.")
        }
    }
    
    private func timeRange() -> ClosedRange<Date> {
        let startTime = DateComponents(hour: 0, minute: 0)
        return Calendar.current.date(from: startTime)! ... Date.now
    }
}

struct AddEditMedicationView_Previews: PreviewProvider {
    static var previews: some View {
        let viewContext = PersistenceController.shared.container.viewContext
        AddEditMedicationView().environment(\.managedObjectContext, viewContext)
    }
}