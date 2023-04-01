//
//  AttackView.swift
//  Migraine
//
//  Created by Ricky Kresslein on 2/28/23.
//

import CoreData
import SwiftUI

struct AttackView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss // TODO: From iOS 15+. Test on iOS 14
    @FetchRequest var dayData: FetchedResults<DayData>
    @ObservedObject var attack: Attack
    @FetchRequest(
        entity: MAppData.entity(),
        sortDescriptors: []
    )
    var mAppData: FetchedResults<MAppData>
    @State var nextFrom: Set<String> = []
    let startDateComps = DateComponents(hour: 0, minute: 0)
    let stopDateComps = DateComponents(hour: 23, minute: 59)
    let newAttack: Bool
    let inputDate: Date?
    let basicSymptoms = [
        "Nausea",
        "Vomiting",
        "Dizziness",
        "Sensitivity to light",
        "Sensitivity to sound",
        "Sensitivity to smell",
        "Neck pain",
        "Jaw pain",
        "Ringing in ears",
        "Issues speaking",
        "Concentration problems",
        "Brain fog",
        "Memory issues"
    ]
    let auraTypes = [
        "Numbness",
        "Smell",
        "Tingling",
        "Visual"
    ]
    
    init(attack: Attack, for inputDate: Date? = nil) {
        self.attack = attack
        self.inputDate = inputDate
        if inputDate == nil {
            self.newAttack = false
        } else {
            self.newAttack = true
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: inputDate ?? Date.now)
        _dayData = FetchRequest(
            sortDescriptors: [],
            predicate: NSPredicate(format: "date = %@", dateString)
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Start time picker
                DatePicker(
                    "When did the attack start?",
                    selection: $attack.startTime.toUnwrapped(defaultValue: Date.now),
                    in: startTimeRange(),
                    displayedComponents: [.hourAndMinute]
                )
                .onChange(of: attack.startTime) { _ in saveData() }
                
                // Stop time picker
                if !newAttack || !selectedDayIsToday() {
                    DatePicker(
                        "When did the attack end?",
                        selection: $attack.stopTime.toUnwrapped(defaultValue: selectedDayIsToday() ? Date.now : (Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: inputDate ?? .now) ?? .now)),
                        in: selectedDayIsToday() ? stopTimeRange() : unlimitedRange(),
                        displayedComponents: [.hourAndMinute]
                    )
                    .onChange(of: attack.stopTime) { _ in saveData() }
                }

                // Pain level slider
                VStack {
                    HStack {
                        Text("What is your pain level?")
                            .padding(.trailing)
                        Text("\(Int(attack.painLevel))").bold()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Slider(
                        value: $attack.painLevel,
                        in: 0 ... 10,
                        step: 1.0
                    ) {
                        Text("")
                    } minimumValueLabel: {
                        Text("0")
                    } maximumValueLabel: {
                        Text("10")
                    } onEditingChanged: { _ in
                        saveData()
                    }
                }

                if newAttack && attack.symptoms.isEmpty && attack.painLevel == 0 && !nextFrom.contains("painLevel") {
                    nextButton(addToNext: "painLevel")
                }

                // Type of pain
                if attack.painLevel > 0 || !newAttack {
                    VStack {
                        Text("What type of pain are you experiencing?")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        VStack {
                            Toggle(isOn: $attack.pressing) {
                                Text("Pressure / pressing")
                            }
                            .onChange(of: attack.pressing) { _ in saveData() }
                            if attack.pressing {
                                Picker("Where?", selection: $attack.pressingSide) {
                                    Text("One side").tag(Sides.one)
                                    Text("Both sides").tag(Sides.both)
                                }
                                .onChange(of: attack.pressingSide) { _ in saveData() }
                            }
                        }
                        .padding(.leading)
                        VStack {
                            Toggle(isOn: $attack.pulsating) {
                                Text("Pulsating / throbbing")
                            }
                            .onChange(of: attack.pulsating) { _ in saveData() }
                            if attack.pulsating {
                                Picker("Where?", selection: $attack.pulsatingSide) {
                                    Text("One side").tag(Sides.one)
                                    Text("Both sides").tag(Sides.both)
                                }
                                .onChange(of: attack.pulsatingSide) { _ in saveData() }
                            }
                        }
                        .padding(.leading)

                        // TODO: Add an 'Other' section
                    }
                    .pickerStyle(.segmented)

                    if newAttack && attack.symptoms.isEmpty && !attack.pressing && !attack.pulsating && !nextFrom.contains("painType") {
                        nextButton(addToNext: "painType")
                    }
                }

                // Accompanying symptoms
                if !attack.symptoms.isEmpty || attack.pressing || attack.pulsating || nextFrom.contains("painType") || nextFrom.contains("painLevel") || !newAttack {
                    MultiSelector(
                        label: "Symptoms",
                        options: basicSymptoms + (mAppData.first?.customSymptoms ?? []), // TODO: basicSymptoms + customSymptoms
                        selected: $attack.symptoms
                    )

                    if newAttack && attack.symptoms.isEmpty && !nextFrom.contains("symptoms") {
                        nextButton(addToNext: "symptoms")
                    }
                }

                // Aura
                if !attack.symptoms.isEmpty || nextFrom.contains("symptoms") || !newAttack {
                    MultiSelector(
                        label: "Aura",
                        options: auraTypes,
                        selected: $attack.auras
                    )

                    if newAttack && attack.auras.isEmpty && !nextFrom.contains("auras") {
                        nextButton(addToNext: "auras")
                    }
                }

                // Type of headache
                if !attack.auras.isEmpty || nextFrom.contains("auras") || !newAttack {
                    HStack {
                        Text("Type of headache")
                        Spacer()
                        Picker("Type of headache", selection: $attack.headacheType) {
                            Text("Migraine").tag(Headaches.migraine)
                            Text("Tension").tag(Headaches.tension)
                            Text("Cluster").tag(Headaches.cluster)
                            Text("Exertional").tag(Headaches.exertional)
                            Text("Hypnic").tag(Headaches.hypnic)
                            Text("Sinus").tag(Headaches.sinus)
                            Text("Caffeine").tag(Headaches.caffeine)
                            Text("Injury").tag(Headaches.injury)
                            Text("Menstrual").tag(Headaches.menstrual)
                            Text("Other").tag(Headaches.other)
                        }
                        .onChange(of: attack.headacheType) { _ in saveData() }
                    }

                    if newAttack {
                        Button {
                            dismiss()
                        } label: {
                            Text("Done")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.accentColor)
                    }
                }

                Spacer()
            }
            .padding()
        }
        .onAppear() {
            if newAttack {
                if !dayData.isEmpty {
                    if !(dayData.first?.attacks.contains(attack) ?? true) {
                        dayData.first?.addToAttack(attack)
                        saveData()
                    }
                } else {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    let dateString = dateFormatter.string(from: inputDate ?? Date.now)
                    
                    let newDay = DayData(context: viewContext)
                    newDay.date = dateString
                    newDay.addToAttack(attack)
                    saveData()
                }
            }
        }
    }
    
    private func startTimeRange() -> ClosedRange<Date> {
        return (Calendar.current.date(from: startDateComps) ?? .now) ... (attack.stopTime ?? Date.now)
    }
    
    private func stopTimeRange() -> ClosedRange<Date> {
        return (attack.startTime ?? Calendar.current.date(from: startDateComps) ?? .now) ... Date.now
    }
    
    private func unlimitedRange() -> ClosedRange<Date> {
        return (attack.startTime ?? Calendar.current.date(from: startDateComps) ?? .now)  ... (Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: inputDate ?? .now) ?? .now)
    }
        
    private func nextButton(addToNext: String) -> some View {
        return Button {
            nextFrom.insert(addToNext)
        } label: {
            Text("Next")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .buttonStyle(.bordered)
        .tint(.accentColor)
    }
    
    private func selectedDayIsToday() -> Bool {
        let selectedDate = Calendar.current.dateComponents([.year, .month, .day], from: inputDate ?? .now)
        let todayDate = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        return selectedDate == todayDate
    }
}

struct AttackView_Previews: PreviewProvider {
    static var previews: some View {
        let viewContext = PersistenceController.shared.container.viewContext
        AttackView(attack: Attack(context: viewContext)).environment(\.managedObjectContext, viewContext)
    }
}
