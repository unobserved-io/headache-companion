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
    @State private var activitiesSheet: Bool = false
    @State private var selectedActivity: String = ""
    @State private var endAttackConfirmation: Bool = false
    @State private var attackEndTime: Date = .now
    @State private var refreshIt: Bool = false
    
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
        NavigationView {
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
                } else {
                    NavigationLink(
                        "Attack",
                        destination: AttackView()
                            .environmentObject(ClickedAttack(Attack(context: viewContext)))
                            .navigationTitle("Add Attack")
                    )
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.accentColor)
                    .font(.title2)
                }
                
                NavigationLink(
                    "Medication",
                    destination: MedicationView()
                        .navigationTitle("Medication Taken Today")
                )
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.accentColor)
                .padding(.bottom, 20)
                
                // Lifestyle buttons
                HStack {
                    VStack {
                        Button {
                            selectedActivity = "sleep"
                            activitiesSheet.toggle()
                        } label: {
                            Image(systemName: "bed.double")
                        }
                        .font(.system(size: 60))
                        .foregroundColor(correspondingColor(of: dayData.first?.sleep ?? 0))
                        Text("Sleep").padding(.top, 4)
                    }
                    .padding(.trailing, 100)
                    VStack {
                        Button {
                            selectedActivity = "water"
                            activitiesSheet.toggle()
                        } label: {
                            Image(systemName: "drop")
                        }
                        .font(.system(size: 60))
                        .foregroundColor(correspondingColor(of: dayData.first?.water ?? 0))
                        Text("Water").padding(.top, 1)
                    }
                }
                .padding()
                HStack {
                    VStack {
                        Button {
                            selectedActivity = "diet"
                            activitiesSheet.toggle()
                        } label: {
                            Image(systemName: "carrot")
                        }
                        .font(.system(size: 60))
                        .foregroundColor(correspondingColor(of: dayData.first?.diet ?? 0))
                        Text("Diet").padding(.top, 1)
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
                        .foregroundColor(correspondingColor(of: dayData.first?.exercise ?? 0))
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
                        .foregroundColor(correspondingColor(of: dayData.first?.relax ?? 0))
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
                        NavigationLink(
                            "Notes for Doctor",
                            destination: DoctorNotesView()
                                .navigationTitle("Notes for Doctor")
                        )
                            .buttonStyle(.bordered)
                    }
                    .padding(.top, 40)
                }
            }
        }
        .onAppear {
            if dayData.isEmpty {
                initNewDay()
            }
        }
        .sheet(isPresented: $activitiesSheet) {
            ActivitiesView(of: $selectedActivity)
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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: .now)
        
        let newDay = DayData(context: viewContext)
        newDay.date = today
        saveData()
    }
    
    private func currentAttackOngoing() -> Bool{
        if !(dayData.first?.attacks.isEmpty ?? false) {
            if dayData.first?.attacks.last?.stopTime == nil {
                return true
            }
        }
        return false
    }
    
    private func correspondingColor(of i: Int16) -> Color {
        switch i {
        case 0:
            return Color.gray
        case 1:
            return Color.red
        case 2:
            return Color.yellow
        case 3:
            return Color.green
        default:
            return Color.gray
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
