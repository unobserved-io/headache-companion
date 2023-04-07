//
//  MedicationHistoryView.swift
//  Headache Companion
//
//  Created by Ricky Kresslein on 4/5/23.
//

import SwiftUI

struct MedicationHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme
    @FetchRequest(
        entity: MedHistory.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \MedHistory.stopDate, ascending: true)]
    )
    var medHistory: FetchedResults<MedHistory>
    let medDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, 'yy"
        return formatter
    }()
        
    var body: some View {
        List {
            NavigationLink(
                "Add medication",
                destination: NewMedHistoryView()
                    .navigationTitle("New Medication")
            )
            .listRowBackground(colorScheme == .light ? Color.gray.opacity(0.10) : Color.white.opacity(0.10))
            
            // Preventive
            if medHistory.contains(where: {$0.type == MedTypes.preventive}) {
                Section("Preventive") {
                    sectionCreator(medType: MedTypes.preventive)
                }
                .listRowBackground(colorScheme == .light ? Color.gray.opacity(0.10) : Color.white.opacity(0.10))
            }
            
            // Symptom Relieving
            if medHistory.contains(where: {$0.type == MedTypes.symptomRelieving}) {
                Section("Symptom Relieving") {
                    sectionCreator(medType: MedTypes.symptomRelieving)
                }
                .listRowBackground(colorScheme == .light ? Color.gray.opacity(0.10) : Color.white.opacity(0.10))
            }
            
            // Preventive
            if medHistory.contains(where: {$0.type == MedTypes.other}) {
                Section("Other") {
                    sectionCreator(medType: MedTypes.other)
                }
                .listRowBackground(colorScheme == .light ? Color.gray.opacity(0.10) : Color.white.opacity(0.10))
            }
        }
        .toolbar {
            if !medHistory.isEmpty {
                ToolbarItemGroup(placement: .bottomBar) {
                    Text("Swipe items right to edit, left to delete.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    private func sectionCreator(medType: MedTypes) -> some View {
        return ForEach(medHistory) { med in
            if med.type == medType {
                DisclosureGroup(med.name) {
                    // Start/stop times
                    if Calendar.current.isDateInToday(med.startDate ?? Date.distantPast) {
                        Text("Started today")
                            .foregroundColor(.gray)
                    } else {
                        Text("\(DateFormatter.localizedString(from: med.startDate ?? .now, dateStyle: .short, timeStyle: .none)) to \(med.stopDate != nil ? DateFormatter.localizedString(from: med.stopDate!, dateStyle: .short, timeStyle: .none) : "Present")")
                            .foregroundColor(.gray)
                    }
                    
                    // Dose & amount
                    if med.dose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && med.frequency.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("\(med.amount)")
                            .foregroundColor(.gray)
                    } else if med.dose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("\(med.amount), \(med.frequency)")
                            .foregroundColor(.gray)
                    } else if med.frequency.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("\(med.amount) x \(med.dose)")
                            .foregroundColor(.gray)
                    } else {
                        Text("\(med.amount) x \(med.dose), \(med.frequency)")
                            .foregroundColor(.gray)
                    }
                    
                    // Side effects
                    if !(med.sideEffects?.isEmpty ?? true) {
                        HStack {
                            Text("Side Effects:")
                            Spacer()
                            Text(ListFormatter.localizedString(byJoining: med.sideEffects!.sorted { $0 < $1 }.map { $0 as String }))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.trailing)
                        }
                        .foregroundColor(.gray)
                    }
                    
                    // Effective/ineffective
                    Text(med.effective ? "Effective" : "Ineffective")
                        .foregroundColor(.gray)
                    
                    // Notes
                    if !med.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(med.notes)
                            .foregroundColor(.gray)
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button("Delete", role: .destructive) {
                        viewContext.delete(med)
                        saveData()
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    NavigationLink(
                        "Edit",
                        destination: AddEditMedHistoryView(medHistory: med)
                    )
                }
            }
        }
    }
    
    private func deleteMedication(at offsets: IndexSet) {
        let index = offsets.first
        if index != nil {
            let medicationToDelete: MedHistory? = medHistory[index!]
            if medicationToDelete != nil {
                viewContext.delete(medicationToDelete!)
                saveData()
            }
        }
    }
}

struct MedicationHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        MedicationHistoryView()
    }
}
