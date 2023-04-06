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
            
            Section {
                ForEach(medHistory) { med in
                    DisclosureGroup(med.name) {
                        Text("\(DateFormatter.localizedString(from: med.startDate ?? .now, dateStyle: .short, timeStyle: .none)) to \(med.stopDate != nil ? DateFormatter.localizedString(from: med.stopDate!, dateStyle: .short, timeStyle: .none) : "Present")")
                        if !(med.sideEffects?.isEmpty ?? true) {
                            HStack {
                                Text("Side Effects")
                                Spacer()
                                Text(ListFormatter.localizedString(byJoining: med.sideEffects!.sorted { $0 < $1 }.map { $0 as String }))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                        Text(med.effective ? "Effective" : "Ineffective")
                        if !(med.notes?.isEmpty ?? true) {
                            Text(med.notes!)
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
            } footer: {
                medHistory.isEmpty ? nil : Text("Swipe items right to edit, left to delete.")
            }
            .listRowBackground(colorScheme == .light ? Color.gray.opacity(0.10) : Color.white.opacity(0.10))
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
