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
    @State var medType: String = "preventive"
    @State var medAmount: Int32 = 1
    @State var showingNameAlert: Bool = false
    
    var body: some View {
        Form {
            // Name field
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
                Stepper("\(medAmount)", value: $medAmount, in: 1 ... 25)
                    .labelsHidden()
            }
            
            Picker("Type", selection: $medType) {
                ForEach(defaultMedicationTypes + (mAppData.first?.customMedTypes ?? []), id: \.self) { type in
                    Text(LocalizedStringKey(type.localizedCapitalized))
                }
            }
            
            // Save & Cancel buttons
            Section {
                // Save
                Button {
                    if medName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        showingNameAlert.toggle()
                    } else {
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
        .onAppear {
            if medication.medication != nil && medication.medication?.id != nil {
                // Medication not nil - get values
                medName = medication.medication?.name ?? ""
                medDose = medication.medication?.dose ?? ""
                medType = medication.medication?.type ?? "preventive"
                medAmount = medication.medication?.amount ?? 0
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

struct AddEditCommonMedsView_Previews: PreviewProvider {
    static var previews: some View {
        AddEditRegularMedsView()
    }
}
