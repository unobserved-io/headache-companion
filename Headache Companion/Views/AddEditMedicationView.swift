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
    @State var medName: String = ""
    @State var medDose: String = ""
    @State var medAmount: Int32 = 1
    @State var medTime: Date = .now
    @State var medEffective: Bool = true
    
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
        Form {
            // Type field
            TextField("Name", text: $medName, prompt: Text("Ibuprofen, Aspirin, etc."))
            
            // Dose field
            TextField("Dose", text: $medDose, prompt: Text("Pills, 20 mg, etc."))

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
            
            // Time picker
            DatePicker(
                "Time",
                selection: $medTime,
                in: timeRange(),
                displayedComponents: [.hourAndMinute]
            )
            
            // Effective picker
            HStack {
                Text("Effective")
                Spacer().padding(.trailing)
                Picker("Effective", selection: $medEffective) {
                    Text("Yes").tag(true)
                    Text("No").tag(false)
                }
                .pickerStyle(.segmented)
            }
            
            // Save & Cancel buttons
            Section {
                // Save
                Button {
                    medication.medication?.name = medName
                    medication.medication?.dose = medDose
                    medication.medication?.amount = medAmount
                    medication.medication?.time = medTime
                    medication.medication?.effective = medEffective
                    
                    if medication.medication?.id == nil {
                        // New medication, give it an id and add to Day
                        medication.medication?.id = UUID().uuidString
                        if medication.medication != nil {
                            dayData.first?.addToMedication(medication.medication!)
                        }
                    }
                    
                    saveData()
                    dismiss()
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
                medEffective = medication.medication?.effective ?? false
            }
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
