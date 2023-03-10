//
//  AddEditCommonMedsView.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/10/23.
//

import SwiftUI

struct AddEditCommonMedsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var medication: ClickedMedication
    @FetchRequest(
        entity: MAppData.entity(),
        sortDescriptors: []
    )
    var mAppData: FetchedResults<MAppData>
    @State var medType: String = ""
    @State var medDose: String = ""
    @State var medAmount: Int32 = 1
    
    var body: some View {
        Form {
            // Type field
            TextField("Type", text: $medType, prompt: Text("Ibuprofen, Aspirin, etc."))
            
            // Dose field
            TextField("Dose", text: $medDose, prompt: Text("20 mg, 4 oz, etc."))

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
            
            // Save & Cancel buttons
            Section {
                // Save
                Button {
                    medication.medication?.type = medType
                    medication.medication?.dose = medDose
                    medication.medication?.amount = medAmount
                    
                    if medication.medication?.id == nil {
                        // New medication, give it an id and add to Common Meds
                        medication.medication?.id = UUID().uuidString
                        if medication.medication != nil {
                            mAppData.first?.addToCommonMedications(medication.medication!)
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
                medType = medication.medication?.type ?? ""
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
        AddEditCommonMedsView()
    }
}
