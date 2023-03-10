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
    @FetchRequest var dayData: FetchedResults<DayData>
    @EnvironmentObject var attack: ClickedAttack
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
    
    init() {
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
                    selection: $attack.attack.toUnwrapped(defaultValue: Attack(context: viewContext)).startTime.toUnwrapped(defaultValue: Date.now),
                    in: timeRange(),
                    displayedComponents: [.hourAndMinute]
                )
                .onDisappear(perform: {
                    saveData()
                })
                
                // Pain level slider
                VStack {
                    HStack {
                        Text("What is your pain level?")
                            .padding(.trailing)
                        Text("\(Int(attack.attack?.painLevel ?? 0))").bold()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Slider(
                        value: $attack.attack.toUnwrapped(defaultValue: Attack(context: viewContext)).painLevel,
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
                
                if attack.attack?.stopTime == nil && attack.attack?.symptoms.isEmpty ?? true && attack.attack?.painLevel == 0 && !nextFrom.contains("painLevel") {
                    nextButton(addToNext: "painLevel")
                }
                
                // Type of pain
                if attack.attack?.painLevel ?? 0 > 0 || attack.attack?.stopTime != nil {
                    VStack {
                        Text("What type of pain are you experiencing?")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        VStack {
                            Toggle(isOn: $attack.attack.toUnwrapped(defaultValue: Attack(context: viewContext)).pressing) {
                                Text("Pressure / pressing")
                            }
                            .onChange(of: attack.attack?.pressing) { _ in saveData() }
                            if attack.attack?.pressing ?? false {
                                Picker("Where?", selection: $attack.attack.toUnwrapped(defaultValue: Attack(context: viewContext)).pressingSide) {
                                    Text("One side").tag(Sides.one)
                                    Text("Both sides").tag(Sides.both)
                                }
                                .onChange(of: attack.attack?.pressingSide) { _ in saveData() }
                            }
                        }
                        .padding(.leading)
                        VStack {
                            Toggle(isOn: $attack.attack.toUnwrapped(defaultValue: Attack(context: viewContext)).pulsating) {
                                Text("Pulsating / throbbing")
                            }
                            .onChange(of: attack.attack?.pulsating) { _ in saveData() }
                            if attack.attack?.pulsating ?? false {
                                Picker("Where?", selection: $attack.attack.toUnwrapped(defaultValue: Attack(context: viewContext)).pulsatingSide) {
                                    Text("One side").tag(Sides.one)
                                    Text("Both sides").tag(Sides.both)
                                }
                                .onChange(of: attack.attack?.pulsatingSide) { _ in saveData() }
                            }
                        }
                        .padding(.leading)
                        
                        // TODO: Add an 'Other' section
                    }
                    .pickerStyle(.segmented)
                    
                    if attack.attack?.stopTime == nil && attack.attack?.symptoms.isEmpty ?? true && !(attack.attack?.pressing ?? true) && !(attack.attack?.pulsating ?? true) && !nextFrom.contains("painType") {
                        nextButton(addToNext: "painType")
                    }
                }
                
                // Accompanying symptoms
                if !(attack.attack?.symptoms.isEmpty ?? true) || attack.attack?.pressing ?? false || attack.attack?.pulsating ?? false || nextFrom.contains("painType") || nextFrom.contains("painLevel") || attack.attack?.stopTime != nil {
                    MultiSelector(
                        label: "Symptoms",
                        options: basicSymptoms,
                        selected: $attack.attack.toUnwrapped(defaultValue: Attack(context: viewContext)).symptoms
                    )
                    
                    if attack.attack?.stopTime == nil && attack.attack?.symptoms.isEmpty ?? false && !nextFrom.contains("symptoms") {
                        nextButton(addToNext: "symptoms")
                    }
                }
                
                // Aura
                if !(attack.attack?.symptoms.isEmpty ?? true) || nextFrom.contains("symptoms") || attack.attack?.stopTime != nil {
                    MultiSelector(
                        label: "Aura",
                        options: auraTypes,
                        selected: $attack.attack.toUnwrapped(defaultValue: Attack(context: viewContext)).auras
                    )
                    
                    if attack.attack?.stopTime == nil && attack.attack?.auras.isEmpty ?? false && !nextFrom.contains("auras") {
                        nextButton(addToNext: "auras")
                    }
                }
                
                // Type of headache
                if !(attack.attack?.auras.isEmpty ?? true) || nextFrom.contains("auras") || attack.attack?.stopTime != nil {
                    HStack {
                        Text("Type of headache")
                        Spacer()
                        Picker("Type of headache", selection: $attack.attack.toUnwrapped(defaultValue: Attack(context: viewContext)).headacheType) {
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
                        .onChange(of: attack.attack?.headacheType) { _ in saveData() }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            if attack.attack != nil && attack.attack?.id == nil {
                // New attack (add to DayData and give id & startTime)
                dayData.first?.addToAttack(attack.attack!)
                
                attack.attack?.id = UUID().uuidString
                attack.attack?.startTime = Date.now
                newAttack = true
            }
            saveData()
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
        AttackView().environment(\.managedObjectContext, viewContext)
    }
}
