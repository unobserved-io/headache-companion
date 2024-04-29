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
    @Environment(\.dismiss) var dismiss
    @FetchRequest var dayData: FetchedResults<DayData>
    @ObservedObject var attack: Attack
    @FetchRequest(
        entity: MAppData.entity(),
        sortDescriptors: []
    )
    var mAppData: FetchedResults<MAppData>
    @State var nextFrom: Set<String> = []
    @State var cancelClicked: Bool = false
    let startDateComps = DateComponents(hour: 0, minute: 0)
    let stopDateComps = DateComponents(hour: 23, minute: 59)
    let newAttack: Bool
    let editCurrent: Bool
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
        "Brainstem",
        "Motor",
        "Retinal",
        "Sensory",
        "Speech/Language",
        "Visual"
    ]
    var cancelBtn: some View {
        Button("Cancel") {
            cancelClicked = true
            dismiss()
        }
    }

    init(attack: Attack, for inputDate: Date? = nil, new: Bool = false, edit: Bool = false) {
        self.attack = attack
        self.inputDate = inputDate
        self.newAttack = new
        self.editCurrent = edit

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

                // Stop time picker
                if !newAttack || !selectedDayIsToday() {
                    DatePicker(
                        "When did the attack end?",
                        selection: $attack.stopTime.toUnwrapped(defaultValue: selectedDayIsToday() ? .now : (Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: inputDate ?? .now) ?? .now)),
                        in: selectedDayIsToday() ? stopTimeRange() : unlimitedRange(),
                        displayedComponents: [.hourAndMinute]
                    )
                }

                // Type of headache
                HStack {
                    Text("Type of headache")
                    Spacer()
                    Picker("Type of headache", selection: $attack.headacheType) {
                        ForEach(defaultHeadacheTypes + (mAppData.first?.customHeadacheTypes ?? []), id: \.self) { type in
                            Text(LocalizedStringKey(type.localizedCapitalized))
                        }
                    }
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

                            if attack.pressing {
                                Picker("Where?", selection: $attack.pressingSide) {
                                    Text("One side").tag(Sides.one)
                                    Text("Both sides").tag(Sides.both)
                                }
                            }
                        }
                        .padding(.leading)
                        VStack {
                            Toggle(isOn: $attack.pulsating) {
                                Text("Pulsating / throbbing")
                            }

                            if attack.pulsating {
                                Picker("Where?", selection: $attack.pulsatingSide) {
                                    Text("One side").tag(Sides.one)
                                    Text("Both sides").tag(Sides.both)
                                }
                            }
                        }
                        .padding(.leading)
                    }
                    .pickerStyle(.segmented)

                    if newAttack && 
                        attack.symptoms.isEmpty &&
                        !attack.pressing &&
                        !attack.pulsating &&
                        !nextFrom.contains("painType") &&
                        !nextFrom.contains("symptoms") &&
                        !(nextFrom.contains("painLevel") && attack.painLevel != 0)
                    {
                        nextButton(addToNext: "painType")
                    }
                }

                // Accompanying symptoms
                if !attack.symptoms.isEmpty || attack.pressing || attack.pulsating || nextFrom.contains("painType") || nextFrom.contains("painLevel") || !newAttack {
                    MultiSelector(
                        label: String(localized: "Symptoms"),
                        options: basicSymptoms + (mAppData.first?.customSymptoms ?? []),
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
                }

                Spacer()
            }
            .padding()
        }
        .toolbar {
            Button("Save") {
                if newAttack && !editCurrent {
                    if !dayData.isEmpty {
                        if !(dayData.first?.attacks.contains(attack) ?? true) {
                            dayData.first?.addToAttack(attack)
                        }
                    } else {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        let dateString = dateFormatter.string(from: inputDate ?? Date.now)

                        let newDay = DayData(context: viewContext)
                        newDay.date = dateString
                        newDay.addToAttack(attack)
                    }
                }
                saveData()
                dismiss()
            }
        }
        .navigationBarBackButtonHidden(true)
        #if os(iOS)
            .navigationBarItems(leading: cancelBtn)
        #endif
            .onAppear {
                // Make sure the stopTime gets set when editing a previous attack without a stopTime
                if !newAttack && !editCurrent && attack.stopTime == nil {
                    if selectedDayIsToday() {
                        attack.stopTime = .now
                    } else {
                        attack.stopTime = (Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: inputDate ?? .now) ?? .now)
                    }
                }
            }
            .onDisappear {
                if cancelClicked && attack.id == nil {
                    viewContext.delete(attack)
                    saveData()
                } else if cancelClicked {
                    viewContext.rollback()
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
        return (attack.startTime ?? Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: inputDate ?? .now) ?? .now) ... (Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: inputDate ?? .now) ?? .now)
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
        return Calendar.current.isDateInToday(inputDate ?? .now)
    }
}

struct AttackView_Previews: PreviewProvider {
    static var previews: some View {
        let viewContext = PersistenceController.shared.container.viewContext
        AttackView(attack: Attack(context: viewContext)).environment(\.managedObjectContext, viewContext)
    }
}
