//
//  AddEditMedHistoryView.swift
//  Headache Companion
//
//  Created by Ricky Kresslein on 4/5/23.
//

import SwiftUI

struct AddEditMedHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @FetchRequest(
        entity: MAppData.entity(),
        sortDescriptors: []
    )
    var mAppData: FetchedResults<MAppData>
    @ObservedObject var medHistory: MedHistory
    @State var stopDateOngoing: Bool = false
    @State var cancelClicked: Bool = false
    @State var showingNameAlert: Bool = false
    @State var newStopDate: Date = .now
    var cancelBtn: some View {
        Button("Cancel") {
            UISegmentedControl.appearance().apportionsSegmentWidthsByContent = false
            cancelClicked = true
            dismiss()
        }
    }
    
    var body: some View {
        Form {
            // Name field
            LabeledContent {
                TextField("Name", text: $medHistory.name, prompt: Text(String(localized: "Aspirin, Paracetamol, etc.")))
                    .multilineTextAlignment(.trailing)
            } label: {
                Text("Name")
                    .padding(.trailing)
            }
            .listRowBackground(colorScheme == .light ? Color.gray.opacity(0.10) : Color.white.opacity(0.10))
            
            Group {
                // Dose field
                LabeledContent {
                    TextField("Dose", text: $medHistory.dose, prompt: Text(String(localized: "20 mg, 50 ml, etc.")))
                        .multilineTextAlignment(.trailing)
                } label: {
                    Text("Dose")
                        .padding(.trailing)
                }
                .listRowBackground(colorScheme == .light ? Color.gray.opacity(0.10) : Color.white.opacity(0.10))
                
                // Amount stepper
                HStack {
                    Text("Amount")
                    Spacer()
                    Text("\(medHistory.amount)")
                        .bold()
                        .padding(.trailing)
                    Stepper("\(medHistory.amount)", value: $medHistory.amount, in: 1 ... 25)
                        .labelsHidden()
                }
                .listRowBackground(colorScheme == .light ? Color.gray.opacity(0.10) : Color.white.opacity(0.10))
            }
            
            // Type picker
            Picker("Type", selection: $medHistory.type) {
                ForEach(defaultMedicationTypes + (mAppData.first?.customMedTypes ?? []), id: \.self) { type in
                    Text(LocalizedStringKey(type.localizedCapitalized))
                }
            }
            .listRowBackground(colorScheme == .light ? Color.gray.opacity(0.10) : Color.white.opacity(0.10))
            
            // Effective picker
            Picker("Effective", selection: $medHistory.effective) {
                Text("Effective").tag(Effectiveness.effective)
                Text("Ineffective").tag(Effectiveness.ineffective)
                Image(systemName: "minus.circle").tag(Effectiveness.none)
            }
            .pickerStyle(.segmented)
            .listRowBackground(colorScheme == .light ? Color.gray.opacity(0.10) : Color.white.opacity(0.10))
            .onAppear {
                // Change segmented pickers to fit contents (Necessary for long languages)
                UISegmentedControl.appearance().apportionsSegmentWidthsByContent = true
            }
            .onDisappear {
                // Reset segmented pickers to be even
                UISegmentedControl.appearance().apportionsSegmentWidthsByContent = false
            }
            
            // Frequency field
            LabeledContent {
                TextField("Frequency", text: $medHistory.frequency, prompt: Text("Daily, 2x/day, etc."))
                    .multilineTextAlignment(.trailing)
            } label: {
                Text("Frequency")
                    .padding(.trailing)
            }
            .listRowBackground(colorScheme == .light ? Color.gray.opacity(0.10) : Color.white.opacity(0.10))
            
            // Side Effects selector
            NavigationLink(destination: MedicationSideEffectsView(sideEffects: $medHistory.sideEffects.toUnwrapped(defaultValue: [])).navigationTitle("Add Side Effects")) {
                HStack {
                    Text("Side Effects")
                        .foregroundColor(.primary)
                    Spacer()
                    if medHistory.sideEffects?.isEmpty ?? true {
                        Text("None")
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.trailing)
                    } else {
                        Text(ListFormatter.localizedString(byJoining: medHistory.sideEffects?.sorted { $0 < $1 }.map { $0 as String } ?? []))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .listRowBackground(colorScheme == .light ? Color.gray.opacity(0.10) : Color.white.opacity(0.10))
            
            // Start date picker
            DatePicker(
                "Start",
                selection: $medHistory.startDate.toUnwrapped(defaultValue: Date.now),
                in: Date(timeIntervalSince1970: 0) ... (medHistory.stopDate ?? Date.now),
                displayedComponents: [.date]
            )
            .listRowBackground(colorScheme == .light ? Color.gray.opacity(0.10) : Color.white.opacity(0.10))
            
            // Stop date picker
            Picker("End", selection: $stopDateOngoing) {
                Text("Ongoing").tag(true)
                Text("Finished").tag(false)
            }
            .pickerStyle(.segmented)
            .listRowBackground(colorScheme == .light ? Color.gray.opacity(0.10) : Color.white.opacity(0.10))
            .onChange(of: stopDateOngoing) { newVal in
                if newVal {
                    medHistory.stopDate = nil
                } else {
                    medHistory.stopDate = newStopDate
                }
            }
            
            if !stopDateOngoing {
                DatePicker(
                    "Stop",
                    selection: $newStopDate,
                    in: (medHistory.startDate ?? Date.distantPast) ... Date.now,
                    displayedComponents: [.date]
                )
                .listRowBackground(colorScheme == .light ? Color.gray.opacity(0.10) : Color.white.opacity(0.10))
                .onChange(of: newStopDate) { newVal in
                    medHistory.stopDate = newVal
                }
            }
            
            // Notes
            NavigationLink {
                MedHistoryNotesView(note: $medHistory.notes)
                    .navigationTitle("Medication Notes")
            } label: {
                if medHistory.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Notes")
                } else {
                    VStack(alignment: .leading) {
                        Text("Notes: ")
                        Text(medHistory.notes)
                            .foregroundColor(.gray)
                    }
                }
            }
            .listRowBackground(colorScheme == .light ? Color.gray.opacity(0.10) : Color.white.opacity(0.10))
        }
        .toolbar {
            Button("Save") {
                UISegmentedControl.appearance().apportionsSegmentWidthsByContent = false
                if medHistory.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    showingNameAlert.toggle()
                } else {
                    if medHistory.id == nil {
                        medHistory.id = UUID().uuidString
                    }
                    saveData()
                    dismiss()
                }
            }
        }
        .onAppear {
            stopDateOngoing = medHistory.stopDate == nil
        }
        .alert("Name is empty", isPresented: $showingNameAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The \"Name\" field cannot be empty.")
        }
        .onDisappear {
            UISegmentedControl.appearance().apportionsSegmentWidthsByContent = false
            if cancelClicked && medHistory.id == nil {
                viewContext.delete(medHistory)
                saveData()
            }
        }
        .navigationBarBackButtonHidden(true)
        #if os(iOS)
            .navigationBarItems(leading: cancelBtn)
        #endif
    }
}

struct AddEditMedHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        let viewContext = PersistenceController.shared.container.viewContext
        AddEditMedHistoryView(medHistory: MedHistory(context: viewContext)).environment(\.managedObjectContext, viewContext)
    }
}
