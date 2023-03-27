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
    @State var newAttack: Bool = false
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
    
    init(attack: Attack) {
        self.attack = attack
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: .now)
        _dayData = FetchRequest(
            sortDescriptors: [],
            predicate: NSPredicate(format: "date = %@", today)
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Start time picker
                DatePicker(
                    "When did the attack start?",
                    selection: $attack.startTime.toUnwrapped(defaultValue: Date.now),
                    in: timeRange(),
                    displayedComponents: [.hourAndMinute]
                )
                .onChange(of: attack.startTime) { _ in saveData() }

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
        .onAppear {
            if attack.id == nil {
                // New attack (add to DayData and give id & startTime)
                dayData.first?.addToAttack(attack)

                attack.id = UUID().uuidString
                attack.startTime = Date.now
                newAttack = true
                saveData()
            }
        }
    }
    
    private func timeRange() -> ClosedRange<Date> {
        let startTime = DateComponents(hour: 0, minute: 0)
        return Calendar.current.date(from: startTime)! ... Date.now
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
}

struct AttackView_Previews: PreviewProvider {
    static var previews: some View {
        let viewContext = PersistenceController.shared.container.viewContext
        AttackView(attack: Attack(context: viewContext)).environment(\.managedObjectContext, viewContext)
    }
}
