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
    @ObservedObject var medHistory: MedHistory
    @State var stopDateOngoing: Bool = false
    @State var cancelClicked: Bool = false
    @State var showingNameAlert: Bool = false
    var cancelBtn : some View {
        Button("Cancel") {
            cancelClicked = true
            dismiss()
        }
    }
    
    var body: some View {
        Form {
            // Name field
            LabeledContent {
                TextField("Name", text: $medHistory.name, prompt: Text("Aspirin, Paracetamol, etc."))
                    .multilineTextAlignment(.trailing)
            } label: {
                Text("Name")
                    .padding(.trailing)
            }
            .listRowBackground(colorScheme == .light ? Color.gray.opacity(0.10) : Color.white.opacity(0.10))
            
            // Type picker
            Picker("Type", selection: $medHistory.type) {
                Text("Preventive").tag(MedTypes.preventive)
                Text("Symptom Relieving").tag(MedTypes.symptomRelieving)
                Text("Other").tag(MedTypes.other)
            }
            .listRowBackground(colorScheme == .light ? Color.gray.opacity(0.10) : Color.white.opacity(0.10))
            
            // Dose field
            LabeledContent {
                TextField("Dose", text: $medHistory.dose, prompt: Text("20 mg, 50 ml, etc."))
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
                Stepper("\(medHistory.amount)", value: $medHistory.amount, in: 1...25)
                    .labelsHidden()
            }
            .listRowBackground(colorScheme == .light ? Color.gray.opacity(0.10) : Color.white.opacity(0.10))
            
            // Effective picker
            Picker("Effective", selection: $medHistory.effective) {
                Text("Effective").tag(true)
                Text("Ineffective").tag(false)
            }
            .pickerStyle(.segmented)
            .listRowBackground(colorScheme == .light ? Color.gray.opacity(0.10) : Color.white.opacity(0.10))
            
            // Side Effects selector
            NavigationLink (destination: MedicationSideEffectsView(sideEffects: $medHistory.sideEffects.toUnwrapped(defaultValue: [])).navigationTitle("Add Symptoms")) {
                HStack{
                    Text("Side Effects")
                        .foregroundColor(.primary)
                    Spacer()
                    if (medHistory.sideEffects?.isEmpty ?? true) {
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
                in: Date.init(timeIntervalSince1970: 0) ... (medHistory.stopDate ?? Date.now),
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
                if newVal { medHistory.stopDate = nil }
            }
            
            if !stopDateOngoing {
                DatePicker(
                    "Stop",
                    selection: $medHistory.stopDate.toUnwrapped(defaultValue: Date.now),
                    in: (medHistory.startDate ?? Date.distantPast) ... Date.now,
                    displayedComponents: [.date]
                )
                .listRowBackground(colorScheme == .light ? Color.gray.opacity(0.10) : Color.white.opacity(0.10))
            }
            
            // Notes
            NavigationLink {
                MedHistoryNotesView(note: $medHistory.notes)
                    .navigationTitle("Daily Notes")
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
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: cancelBtn)
        .onAppear() {
            stopDateOngoing = medHistory.stopDate == nil
        }
        .alert("Name is empty", isPresented: $showingNameAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The \"Name\" field cannot be empty.")
        }
        .onDisappear() {
            if cancelClicked && medHistory.id == nil {
                viewContext.delete(medHistory)
                saveData()
            }
        }
    }
}

struct AddEditMedHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        let viewContext = PersistenceController.shared.container.viewContext
        AddEditMedHistoryView(medHistory: MedHistory(context: viewContext)).environment(\.managedObjectContext, viewContext)
    }
}
