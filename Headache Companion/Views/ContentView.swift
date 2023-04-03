//
//  ContentView.swift
//  Migraine
//
//  Created by Ricky Kresslein on 2/27/23.
//

import CoreData
import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest var dayData: FetchedResults<DayData>
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
    let todayString: String = dateFormatter.string(from: .now)
    
    init() {
        _dayData = FetchRequest(
            sortDescriptors: [],
            predicate: NSPredicate(format: "date = %@", todayString)
        )
        scheduleMidnightTimer()
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Top two buttons
                if currentAttackOngoing() {
                    Button(refreshIt ? "End Attack" : "End Attack") {
                        attackEndTime = .now
                        endAttackConfirmation.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.accentColor)
                    .font(.title2)
                    .disabled(dayData.isEmpty)
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
                HStack {
                    VStack {
                        Button {
                            selectedActivity = "water"
                            activitiesSheet.toggle()
                        } label: {
                            Image(systemName: "drop")
                        }
                        .font(.system(size: 60))
                        .foregroundColor(activityColor(of: dayData.first?.water ?? .none))
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
                        .foregroundColor(activityColor(of: dayData.first?.diet ?? .none))
                        .disabled(dayData.isEmpty)
                        Text("Diet").padding(.top, 1)
                    }
                }
                .padding()
                HStack {
                    VStack {
                        Button {
                            selectedActivity = "sleep"
                            activitiesSheet.toggle()
                        } label: {
                            Image(systemName: "bed.double")
                        }
                        .font(.system(size: 60))
                        .foregroundColor(activityColor(of: dayData.first?.sleep ?? .none))
                        .disabled(dayData.isEmpty)
                        Text("Sleep").padding(.top, 4)
                    }
                }
                HStack {
                    VStack {
                        Button {
                            selectedActivity = "exercise"
                            activitiesSheet.toggle()
                        } label: {
                            Image(systemName: "figure.strengthtraining.functional")
                        }
                        .font(.system(size: 60))
                        .foregroundColor(activityColor(of: dayData.first?.exercise ?? .none))
                        .disabled(dayData.isEmpty)
                        Text("Excercise").padding(.top, 4)
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
                        .foregroundColor(activityColor(of: dayData.first?.relax ?? .none))
                        .disabled(dayData.isEmpty)
                        Text("Relax").padding(.top, 4)
                    }
                }
                .padding()
                
                // Notes buttons
                if dayData.first != nil {
                    HStack {
                        NavigationLink(
                            "Daily Notes",
                            destination: NotesView(dayData: dayData.first!)
                                .navigationTitle("Daily Notes")
                        )
                            .buttonStyle(.bordered)
                            .disabled(dayData.isEmpty)
                        NavigationLink(
                            "Notes for Doctor",
                            destination: DoctorNotesView()
                                .navigationTitle("Notes for Doctor")
                        )
                            .buttonStyle(.bordered)
                            .disabled(dayData.isEmpty)
                    }
                    .padding(.top, 40)
                }
            }
        }
        .onAppear() {
            refreshIt.toggle()
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
    
    private func initNewDay() {
        let newDay = DayData(context: viewContext)
        newDay.date = todayString
        saveData()
    }
    
    private func scheduleMidnightTimer() {
        /// Schedule a timer to change the day at midnight
        let midnight = Calendar.current.startOfDay(for: .now).addingTimeInterval(86400)
        let timer = Timer(fire: midnight, interval: 0, repeats: true) { _ in
            // Code to be executed at midnight
            let newDayString = dateFormatter.string(from: .now)
            dayData.nsPredicate = NSPredicate(format: "date = %@", newDayString)
            if dayData.isEmpty {
                let newDay = DayData(context: viewContext)
                newDay.date = newDayString
                saveData()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if dayData.isEmpty {
                        let newDay = DayData(context: viewContext)
                        newDay.date = newDayString
                        saveData()
                    }
                }
            }
        }
        RunLoop.current.add(timer, forMode: .common)
    }
    
    private func currentAttackOngoing() -> Bool {
        if !(dayData.first?.attacks.isEmpty ?? false) {
            if dayData.first?.attacks.last?.stopTime == nil {
                return true
            }
        }
        return false
    }
    
    private func initializeMApp() {
        let newMAppData = MAppData(context: viewContext)
        newMAppData.doctorNotes = ""
        newMAppData.customSymptoms = []
        newMAppData.activityColors = [
            getData(from: UIColor(Color.gray)) ?? Data(),
            getData(from: UIColor(Color.red)) ?? Data(),
            getData(from: UIColor(Color.yellow)) ?? Data(),
            getData(from: UIColor(Color.green)) ?? Data(),
        ]
        saveData()
    }
    
    private func activityColor(of i: ActivityRanks) -> Color {
        switch i {
        case .none:
            return getColor(from: mAppData.first?.activityColors?[0] ?? Data(), default: Color.gray)
        case .bad:
            return getColor(from: mAppData.first?.activityColors?[1] ?? Data(), default: Color.red)
        case .ok:
            return getColor(from: mAppData.first?.activityColors?[2] ?? Data(), default: Color.yellow)
        case .good:
            return getColor(from: mAppData.first?.activityColors?[3] ?? Data(), default: Color.green)
        default:
            return getColor(from: mAppData.first?.activityColors?[0] ?? Data(), default: Color.gray)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
