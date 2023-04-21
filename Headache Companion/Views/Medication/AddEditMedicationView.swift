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
    @FetchRequest(
        entity: MAppData.entity(),
        sortDescriptors: []
    )
    var mAppData: FetchedResults<MAppData>
    let dayTaken: Date
    let dayTakenString: String
    @State var medName: String = ""
    @State var medType: String = "symptom relieving"
    @State var medDose: String = ""
    @State var medAmount: Int32 = 1
    @State var medTime: Date = .now
    @State var medEffective: Effectiveness = .none
    @State var showingNameAlert: Bool = false
    
    init(dayTaken: Date = .now) {
        self.dayTaken = dayTaken
        dayTakenString = dateFormatter.string(from: dayTaken)
        _dayData = FetchRequest(
            sortDescriptors: [],
            predicate: NSPredicate(format: "date = %@", dayTakenString)
        )
    }
    
    var body: some View {
        Form {
            // Type field
            LabeledContent {
                TextField("Name", text: $medName, prompt: Text(String(localized: "Aspirin, Paracetamol, etc.")))
                    .multilineTextAlignment(.trailing)
            } label: {
                Text("Name")
                    .padding(.trailing)
            }
            
            // Dose field
            LabeledContent {
                TextField("Dose", text: $medDose, prompt: Text(String(localized: "20 mg, 50 ml, etc.")))
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
                ForEach(defaultMedicationTypes + (mAppData.first?.customMedTypes ?? []), id: \.self) { type in
                    Text(LocalizedStringKey(type.localizedCapitalized))
                }
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
                                    let newDay = DayData(context: viewContext)
                                    newDay.date = dayTakenString
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
                medType = medication.medication?.type ?? "symptom relieving"
                medAmount = medication.medication?.amount ?? 0
                medTime = medication.medication?.time ?? Date.now
                medEffective = medication.medication?.effective ?? .none
            } else {
                if !Calendar.current.isDateInToday(dayTaken) {
                    DispatchQueue.main.async {
                        self.medTime = Calendar.current.date(bySettingHour: 11, minute: 00, second: 00, of: dayTaken) ?? .now
                    }
                }
            }
        }
        .alert("Name is empty", isPresented: $showingNameAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The \"Name\" field cannot be empty.")
        }
    }
    
    private func timeRange() -> ClosedRange<Date> {
        let startTime = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: dayTaken)
        let stopTime = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: dayTaken)
        // Time should only go up to now if setting a medication for today
        if Calendar.current.isDateInToday(dayTaken) {
            return (startTime ?? .now) ... Date.now
        } else {
            return (startTime ?? .now) ... (stopTime ?? .now)
        }
    }
}

struct AddEditMedicationView_Previews: PreviewProvider {
    static var previews: some View {
        let viewContext = PersistenceController.shared.container.viewContext
        AddEditMedicationView().environment(\.managedObjectContext, viewContext)
    }
}
