//
//  AddEditCommonMedsView.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/10/23.
//

import SwiftUI

struct AddEditRegularMedsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var medication: ClickedMedication
    @FetchRequest(
        entity: MAppData.entity(),
        sortDescriptors: []
    )
    var mAppData: FetchedResults<MAppData>
    @State var medName: String = ""
    @State var medDose: String = ""
    @State var medType: MedTypes = .preventive
    @State var medAmount: Int32 = 1
    
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
            
            Picker("Type", selection: $medType) {
                Text("Preventive").tag(MedTypes.preventive)
                Text("Symptom Relieving").tag(MedTypes.symptomRelieving)
                Text("Other").tag(MedTypes.other)
            }
            
            // Save & Cancel buttons
            Section {
                // Save
                Button {
                    medication.medication?.name = medName
                    medication.medication?.dose = medDose
                    medication.medication?.amount = medAmount
                    medication.medication?.type = medType
                    
                    if medication.medication?.id == nil {
                        // New medication, give it an id and add to Common Meds
                        medication.medication?.id = UUID().uuidString
                        if medication.medication != nil {
                            mAppData.first?.addToRegularMedications(medication.medication!)
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
            }
        }
    }
    
    private func timeRange() -> ClosedRange<Date> {
        let startTime = DateComponents(hour: 0, minute: 0)
        return Calendar.current.date(from: startTime)! ... Date.now
    }
}

struct AddEditCommonMedsView_Previews: PreviewProvider {
    static var previews: some View {
        AddEditRegularMedsView()
    }
}
