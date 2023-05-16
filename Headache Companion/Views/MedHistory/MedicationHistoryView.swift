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
    @SectionedFetchRequest(
        entity: MedHistory.entity(),
        sectionIdentifier: \.type,
        sortDescriptors: [NSSortDescriptor(keyPath: \MedHistory.type, ascending: true),NSSortDescriptor(keyPath: \MedHistory.stopDate, ascending: true)],
        animation: .default
    )
    var medHistory: SectionedFetchResults<String, MedHistory>
    @State var showingInfo: Bool = false
    let medDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, 'yy"
        return formatter
    }()

    var body: some View {
        List {
            NavigationLink("Add medication") {
                NewMedHistoryView()
                    .navigationTitle("New Medication")
            }
            .listRowBackground(colorScheme == .light ? Color.gray.opacity(0.10) : Color.white.opacity(0.10))
            .foregroundColor(.accentColor)

            ForEach(medHistory) { section in
                Section(LocalizedStringKey(section.id)) {
                    ForEach(section) { med in
                        DisclosureGroup {
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
                            if med.effective == .effective {
                                Text("Effective")
                                    .foregroundColor(.gray)
                            } else if med.effective == .ineffective {
                                Text("Ineffective")
                                    .foregroundColor(.gray)
                            }

                            // Notes
                            if !med.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(med.notes)
                                    .foregroundColor(.gray)
                            }
                        } label: {
                            if med.dose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(med.name)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            } else {
                                HStack {
                                    Text(med.name)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                    if med.amount > 1 {
                                        Text("(\(med.amount) x \(med.dose))")
                                            .foregroundColor(.gray)
                                    } else {
                                        Text("(\(med.dose))")
                                            .foregroundColor(.gray)
                                    }
                                }
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
                .listRowBackground(colorScheme == .light ? Color.gray.opacity(0.10) : Color.white.opacity(0.10))
            }
        }
//        .toolbar {
//            Button {
//                showingInfo.toggle()
//            } label: {
//                Image(systemName: "info.circle")
//            }
//        }
//        .alert("Medication History", isPresented: $showingInfo) {
//            Button("OK") {}
//        } message: {
//            Text("This page is for you to keep track of the medications you are taking now or have taken in the past. It is not automatically generated.\n\nSwipe items right to edit them, or left to delete them.")
//        }
    }
}

struct MedicationHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        MedicationHistoryView()
    }
}
