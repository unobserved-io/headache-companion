//
//  ContentView.swift
//  Migraine
//
//  Created by Ricky Kresslein on 2/27/23.
//

import CoreData
import StoreKit
import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.requestReview) private var requestReview
    @AppStorage("launchCount") private var launchCount = 0
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
    @State private var activitiesSheet: Bool = false
    @State private var selectedActivity: String = ""
    @State private var endAttackConfirmation: Bool = false
    @State private var attackEndTime: Date = .now
    @State private var refreshIt: Bool = false
    @State private var attackOngoing: Bool = false
    @State var todayString: String = dateFormatter.string(from: .now)
    let willEnterForeground = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
        
//        .addObserver(forName:UIApplication.willEnterForegroundNotification, object: nil, queue: nil)

    var body: some View {
        NavigationStack {
            VStack {
                // Top two buttons
                if currentAttackOngoing() {
                    HStack {
                        NavigationLink(
                            "Edit Attack",
                            destination: AttackView(attack: dayData.first?.attacks.last ?? makeTempAttack(), for: .now, new: true, edit: true)
                                .navigationTitle("Edit Attack")
                        )
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .tint(.accentColor)
                        .font(.title2)
                        .disabled(dayData.isEmpty)
                        
                        Button(refreshIt ? "End Attack" : "End Attack") {
                            attackEndTime = .now
                            endAttackConfirmation.toggle()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(.accentColor)
                        .font(.title2)
                        .disabled(dayData.isEmpty)
                    }
                } else {
                    NavigationLink(
                        "Attack",
                        destination: NewAttackView(for: .now)
                            .navigationTitle("Add Attack")
                    )
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.accentColor)
                    .font(.title2)
                    .disabled(dayData.isEmpty)
                }
                
                NavigationLink(
                    "Medication",
                    destination: MedicationView()
                        .navigationTitle("Medication")
                )
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.accentColor)
                .padding(.bottom, 20)
                .disabled(dayData.isEmpty)
                
                // Lifestyle buttons
                Grid {
                    GridRow {
                        VStack {
                            Button {
                                selectedActivity = "water"
                                activitiesSheet.toggle()
                            } label: {
                                Image(systemName: "drop")
                            }
                            .font(.system(size: 60))
                            .frame(height: 70)
                            .foregroundColor(correspondingColor(of: dayData.first?.water ?? .none))
                            .disabled(dayData.isEmpty)
                            Text("Water").padding(.top, 1)
                        }
                        .padding(.trailing, 100)
                        VStack {
                            Button {
                                selectedActivity = "diet"
                                activitiesSheet.toggle()
                            } label: {
                                Image(systemName: "carrot")
                            }
                            .font(.system(size: 60))
                            .frame(height: 70)
                            .foregroundColor(correspondingColor(of: dayData.first?.diet ?? .none))
                            .disabled(dayData.isEmpty)
                            Text("Diet").padding(.top, 1)
                        }
                    }
                    .padding(.bottom)
                    HStack {
                        VStack {
                            Button {
                                selectedActivity = "sleep"
                                activitiesSheet.toggle()
                            } label: {
                                Image(systemName: "bed.double")
                            }
                            .font(.system(size: 60))
                            .frame(height: 70)
                            .foregroundColor(correspondingColor(of: dayData.first?.sleep ?? .none))
                            .disabled(dayData.isEmpty)
                            Text("Sleep").padding(.top, 4)
                        }
                    }
                    GridRow {
                        VStack {
                            Button {
                                selectedActivity = "exercise"
                                activitiesSheet.toggle()
                            } label: {
                                Image(systemName: "figure.strengthtraining.functional")
                            }
                            .font(.system(size: 60))
                            .frame(height: 70)
                            .foregroundColor(correspondingColor(of: dayData.first?.exercise ?? .none))
                            .disabled(dayData.isEmpty)
                            Text("Exercise").padding(.top, 4)
                        }
                        .padding(.trailing, 100)
                        VStack {
                            Button {
                                selectedActivity = "relax"
                                activitiesSheet.toggle()
                            } label: {
                                Image(systemName: "figure.mind.and.body")
                            }
                            .font(.system(size: 60))
                            .frame(height: 70)
                            .foregroundColor(correspondingColor(of: dayData.first?.relax ?? .none))
                            .disabled(dayData.isEmpty)
                            Text("Relax").padding(.top, 4)
                        }
                    }
                    .padding(.top)
                }
                
                // Notes buttons
                if dayData.first != nil {
                    HStack {
                        NavigationLink(
                            "Daily Notes",
                            destination: NotesView(dayData: dayData.first ?? makeTempDayData())
                                .navigationTitle("Daily Notes")
                        )
                        .buttonStyle(.bordered)
                        .tint(.accentColor)
                        .disabled(dayData.isEmpty)
                        NavigationLink(
                            "Notes for Doctor",
                            destination: DoctorNotesView()
                                .navigationTitle("Notes for Doctor")
                        )
                        .buttonStyle(.bordered)
                        .tint(.accentColor)
                        .disabled(dayData.isEmpty)
                    }
                    .padding(.top, 40)
                }
            }
        }
        .onAppear {
            refreshIt.toggle()
            // Reset segmented pickers to be even (Necessary for long languages)
            UISegmentedControl.appearance().apportionsSegmentWidthsByContent = false
            
            // Timer to change day at midnight
            let midnight = Calendar.current.startOfDay(for: .now).addingTimeInterval(86400)
            // Code to be executed at midnight
            let timer = Timer(fire: midnight, interval: 0, repeats: false) { _ in
                changeToNewDay()
            }
            RunLoop.current.add(timer, forMode: .common)
            
            // Ask for in-app review
            if launchCount > 0 && launchCount % 10 == 0 {
                DispatchQueue.main.async {
                    requestReview()
                }
            }
        }
        .onReceive(willEnterForeground) { (output) in
            let newDay = dateFormatter.string(from: .now)
            if todayString != newDay {
                changeToNewDay()
            }
        }
        .sheet(isPresented: $activitiesSheet) {
            ActivitiesView(of: $selectedActivity, for: .now)
                .presentationDetents([.bar])
        }
        .sheet(isPresented: $endAttackConfirmation) {
            VStack {
                DatePicker(
                    "End time",
                    selection: $attackEndTime,
                    in: Date.distantPast ... .now,
                    displayedComponents: [.hourAndMinute]
                )
                .datePickerStyle(.compact)
                .padding(.horizontal, 20)
                .padding(.bottom)
                
                HStack {
                    Button("Cancel", role: .cancel) {
                        endAttackConfirmation.toggle()
                    }
                    .buttonStyle(.bordered)
                    .padding(.trailing)
                    
                    Button("End attack") {
                        if !(dayData.first?.attacks.isEmpty ?? true) {
                            if dayData.first?.attacks.last?.stopTime == nil {
                                dayData.first?.attacks.last?.stopTime = attackEndTime
                                saveData()
                                refreshIt.toggle()
                            }
                        }
                        endAttackConfirmation.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .presentationDetents([.bar])
        }
    }
    
    private func makeTempDayData() -> DayData {
        /// Create an empty DayData object not associated with the context
        let itemEntity = NSEntityDescription.entity(forEntityName: "DayData",
                                                    in: viewContext)!
        return DayData(entity: itemEntity, insertInto: nil)
    }
    
    private func createNewDayWithAttack(ongoingAttack: Attack?) {
        let newDay = DayData(context: viewContext)
        newDay.date = todayString
        if ongoingAttack != nil {
            let newAttack = Attack(context: viewContext)
            newAttack.id = UUID().uuidString
            newAttack.headacheType = ongoingAttack!.headacheType
            newAttack.otherPainText = ongoingAttack!.otherPainText
            newAttack.otherPainGroup = ongoingAttack!.otherPainGroup
            newAttack.painLevel = ongoingAttack!.painLevel
            newAttack.pressing = ongoingAttack!.pressing
            newAttack.pressingSide = ongoingAttack!.pressingSide
            newAttack.pulsating = ongoingAttack!.pulsating
            newAttack.pulsatingSide = ongoingAttack!.pulsatingSide
            newAttack.auras = ongoingAttack!.auras
            newAttack.symptoms = ongoingAttack!.symptoms
            newAttack.onPeriod = ongoingAttack!.onPeriod
            newAttack.startTime = Calendar.current.startOfDay(for: .now)
            newAttack.stopTime = nil
            newDay.addToAttack(newAttack)
        }
        saveData()
    }
    
    private func makeTempAttack() -> Attack {
        /// Create an empty DayData object not associated with the context
        let itemEntity = NSEntityDescription.entity(forEntityName: "Attack",
                                                    in: viewContext)!
        return Attack(entity: itemEntity, insertInto: nil)
    }
    
    private func currentAttackOngoing() -> Bool {
        if !(dayData.first?.attacks.isEmpty ?? false) {
            if dayData.first?.attacks.last?.stopTime == nil {
                return true
            }
        }
        return false
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
    
    private func changeToNewDay() {
        // Check for an ongoing attack and end or don't depending on user setting
        var ongoingAttack: Attack? = nil
        if let index = dayData.first?.attacks.firstIndex(where: { $0.stopTime == nil }) {
            dayData.first?.attacks[index].stopTime = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: dateFormatter.date(from: todayString) ?? (Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now))
            // If user set to not end with day, store the attack
            if !(mAppData.first?.attacksEndWithDay ?? true) {
                ongoingAttack = dayData.first?.attacks[index]
            }
        }
        
        // Change to new day
        todayString = dateFormatter.string(from: .now)
        dayData.nsPredicate = NSPredicate(format: "date = %@", todayString)
        if dayData.isEmpty {
            createNewDayWithAttack(ongoingAttack: ongoingAttack)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if dayData.isEmpty {
                    createNewDayWithAttack(ongoingAttack: ongoingAttack)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
