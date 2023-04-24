//
//  CalendarView.swift
//  Migraine
//
//  Created by Ricky Kresslein on 2/28/23.
//

import SwiftUI

struct CalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: DayData.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \DayData.date, ascending: false)],
        predicate: NSPredicate(format: "date = %@", dateFormatter.string(from: .now)),
        animation: .default
    )
    var dayData: FetchedResults<DayData>
    @FetchRequest(
        entity: MAppData.entity(),
        sortDescriptors: []
    )
    var mAppData: FetchedResults<MAppData>
    @StateObject var clickedMedication = ClickedMedication(nil)
    @State private var selectedDay: Date = .now
    @State private var refreshIt: Bool = false
    @State private var attackSheet: Bool = false
    @State private var showingMedSheet: Bool = false
    @State private var activitiesSheet: Bool = false
    @State private var selectedActivity: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Attacks",
                        selection: $selectedDay,
                        in: Date(timeIntervalSince1970: 0) ... Date.now,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .onChange(of: selectedDay) { newDay in
                        dayData.nsPredicate = NSPredicate(format: "date = %@", dateFormatter.string(from: newDay))
                    }
                }
                .onAppear {
                    refreshView()
                }
                
                Section(refreshIt ? "Attacks" : "Attacks") {
                    ForEach((dayData.first?.attack?.allObjects as? [Attack] ?? []).sorted { $0.wrappedStartTime < $1.wrappedStartTime }) { attack in
                        NavigationLink(destination: AttackView(attack: attack, for: selectedDay).onDisappear { refreshView() }) {
                            HStack {
                                if attack.stopTime != nil {
                                    Text("\(attack.wrappedStartTime.formatted(date: .omitted, time: .shortened)) - \(attack.wrappedStopTime.formatted(date: .omitted, time: .shortened))")
                                } else {
                                    Text(attack.wrappedStartTime.formatted(date: .omitted, time: .shortened))
                                }
                                Text("(").foregroundColor(.gray) +
                                    Text(LocalizedStringKey(attack.headacheType.localizedCapitalized)).foregroundColor(.gray) +
                                    Text(")").foregroundColor(.gray)
                            }
                            .lineLimit(1)
                        }
                    }
                    .onDelete(perform: deleteAttack)
                    
                    if dayData.first?.attacks.isEmpty ?? true && selectedDayIsToday() {
                        Text("No attacks")
                    }
                    
                    if !selectedDayIsToday() {
                        NavigationLink(
                            "Add attack",
                            destination: NewAttackView(for: selectedDay)
                                .navigationTitle("Add Attack")
                        )
                        .foregroundColor(.accentColor)
                    }
                }
                
                Section("Medication") {
                    ForEach((dayData.first?.medication?.allObjects as? [Medication] ?? []).sorted { $0.wrappedTime < $1.wrappedTime }) { medication in
                        Button {
                            clickedMedication.medication = medication
                            showingMedSheet.toggle()
                        } label: {
                            MedicationLabelView(medication: medication, refresh: refreshIt)
                        }
                        .tint(.primary)
                    }
                    .onDelete(perform: deleteMedication)
                    
                    if dayData.first?.medications.isEmpty ?? true && selectedDayIsToday() {
                        Text("No medication taken")
                    }
                    
                    if !selectedDayIsToday() {
                        Button("Add medication") {
                            clickedMedication.medication = Medication(context: viewContext)
                            showingMedSheet.toggle()
                        }
                        .foregroundColor(.accentColor)
                    }
                }
                
                // Activities
                if !selectedDayIsToday() {
                    Section(refreshIt ? "Activities" : "Activities") {
                        Button {
                            selectedActivity = "water"
                            activitiesSheet.toggle()
                        } label: {
                            HStack {
                                Text("Water")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "drop.fill")
                                    .foregroundColor(correspondingColor(of: dayData.first?.water ?? .none))
                            }
                        }
                        Button {
                            selectedActivity = "diet"
                            activitiesSheet.toggle()
                        } label: {
                            HStack {
                                Text("Diet")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "carrot.fill")
                                    .foregroundColor(correspondingColor(of: dayData.first?.diet ?? .none))
                            }
                        }
                        Button {
                            selectedActivity = "sleep"
                            activitiesSheet.toggle()
                        } label: {
                            HStack {
                                Text("Sleep")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "bed.double.fill")
                                    .foregroundColor(correspondingColor(of: dayData.first?.sleep ?? .none))
                            }
                        }
                        Button {
                            selectedActivity = "exercise"
                            activitiesSheet.toggle()
                        } label: {
                            HStack {
                                Text("Exercise")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "figure.strengthtraining.functional")
                                    .foregroundColor(correspondingColor(of: dayData.first?.exercise ?? .none))
                            }
                        }
                        Button {
                            selectedActivity = "relax"
                            activitiesSheet.toggle()
                        } label: {
                            HStack {
                                Text("Relax")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "figure.mind.and.body")
                                    .foregroundColor(correspondingColor(of: dayData.first?.relax ?? .none))
                            }
                        }
                    }
                }
                
                // Notes
                if !(dayData.first?.notes.isEmpty ?? true) || !selectedDayIsToday() {
                    Section("Notes") {
                        if dayData.first?.notes.isEmpty ?? true && dayData.first == nil {
                            NavigationLink(
                                "Add notes",
                                destination: NewNoteView(inputDate: selectedDay)
                                    .navigationTitle("Daily Notes")
                            )
                        } else {
                            NavigationLink(
                                dayData.first?.notes.isEmpty ?? true ? String(localized: "Add notes") : dayData.first?.notes ?? String(localized: "Notes"),
                                destination: NotesView(dayData: dayData.first!)
                                    .navigationTitle("Daily Notes")
                            )
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $activitiesSheet) {
            ActivitiesView(of: $selectedActivity, for: selectedDay)
                .presentationDetents([.bar])
        }
        .sheet(isPresented: $showingMedSheet, onDismiss: refreshView) {
            if clickedMedication.medication != nil {
                AddEditMedicationView(dayTaken: selectedDay)
                    .environmentObject(clickedMedication)
                    .navigationTitle("Edit Medication")
                    .presentationDetents([.medium])
            }
        }
    }
    
    private func refreshView() {
        refreshIt.toggle()
    }
    
    private func selectedDayIsToday() -> Bool {
        return Calendar.current.isDateInToday(selectedDay)
    }
    
    private func deleteMedication(at offsets: IndexSet) {
        let index = offsets.first
        if index != nil {
            let medToDelete: Medication? = dayData.first?.medications[index!]
            if medToDelete != nil {
                viewContext.delete(medToDelete!)
                saveData()
            }
        }
    }
    
    private func deleteAttack(at offsets: IndexSet) {
        let index = offsets.first
        if index != nil {
            let attackToDelete: Attack? = dayData.first?.attacks[index!]
            if attackToDelete != nil {
                viewContext.delete(attackToDelete!)
                saveData()
            }
        }
    }
    
    private func correspondingColor(of activityRank: ActivityRanks) -> Color {
        switch activityRank {
        case .none:
            return Color(hex: mAppData.first?.activityColors?[0]) ?? Color.gray
        case .bad:
            return Color(hex: mAppData.first?.activityColors?[1]) ?? Color.red
        case .ok:
            return Color(hex: mAppData.first?.activityColors?[2]) ?? Color.yellow
        case .good:
            return Color(hex: mAppData.first?.activityColors?[3]) ?? Color.green
        default:
            return Color(hex: mAppData.first?.activityColors?[0]) ?? Color.gray
        }
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
