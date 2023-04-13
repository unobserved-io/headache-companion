//
//  LoadingView.swift
//  Headache Companion
//
//  Created by Ricky Kresslein on 3/27/23.
//

import SwiftUI

struct LoadingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: DayData.entity(), sortDescriptors: [])
    var dayData: FetchedResults<DayData>
    @FetchRequest(entity: MAppData.entity(), sortDescriptors: [])
    var mAppData: FetchedResults<MAppData>
    @AppStorage("lastLaunch") private var lastLaunch: String = ""
    @State var isAnimated: Bool = false
    let todayString: String = dateFormatter.string(from: .now)
    
    var body: some View {
        if lastLaunch == todayString {
            MainView()
        } else if dayData.isEmpty || mAppData.isEmpty || !dayData.contains(where: { $0.date == todayString}) {
            LoadingBars(animate: $isAnimated, count: 3)
                .foregroundColor(.accentColor)
                .frame(maxWidth: 100)
                .onAppear() {
                    isAnimated = true
                    
                    // Use last launch to potentially speed up loading time on first run of the day
                    if lastLaunch.isEmpty {
                        initializeDataInThree()
                    } else {
                        if dayData.isEmpty {
                            initializeDataInThree()
                        } else {
                            continueOrEndOngoingAttack()
                            
                            // Double check that dayData doesn't contain date before creating
                            if !dayData.contains(where: { $0.date == todayString}) {
                                initNewDay()
                                lastLaunch = todayString
                            }
                        }
                    }
                }
                .onDisappear { isAnimated = false }
        } else {
            MainView()
                .onAppear() {
                    continueOrEndOngoingAttack()
                    lastLaunch = todayString
                }
        }
    }
    
    private func initializeDataInThree() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if mAppData.isEmpty {
                initializeMAppData()
            }
            if !dayData.contains(where: { $0.date == todayString}) {
                initNewDay()
                lastLaunch = todayString
            }
        }
    }
    
    private func initNewDay() {
        let newDay = DayData(context: viewContext)
        newDay.date = todayString
        saveData()
    }
    
    private func continueOrEndOngoingAttack() {
        // Create ongoing attack on every day if !attacksEndWithDay
        let today = Calendar.current.startOfDay(for: .now)
        var lastRecorded = Calendar.current.startOfDay(for: dateFormatter.date(from: lastLaunch) ?? Calendar.current.startOfDay(for: .now))
        
        if let index = dayData.firstIndex(where: { $0.date == lastLaunch }) {
            if let attackIndex = dayData[index].attacks.firstIndex(where: { $0.stopTime == nil }) {
                if !(mAppData.first?.attacksEndWithDay ?? true) { // Continue ongoing attack
                    let modelAttack = dayData[index].attacks[attackIndex]
                    modelAttack.stopTime = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: lastRecorded)
                    lastRecorded = Calendar.current.date(byAdding: .day, value: 1, to: lastRecorded) ?? Date.now
                    
                    while lastRecorded.compare(today) != .orderedDescending {
                        if let index = dayData.firstIndex(where: { $0.date == dateFormatter.string(from: lastRecorded) }) {
                            let newAttack = Attack(context: viewContext)
                            newAttack.id = UUID().uuidString
                            newAttack.headacheType = modelAttack.headacheType
                            newAttack.otherPainText = modelAttack.otherPainText
                            newAttack.otherPainGroup = modelAttack.otherPainGroup
                            newAttack.painLevel = modelAttack.painLevel
                            newAttack.pressing = modelAttack.pressing
                            newAttack.pressingSide = modelAttack.pressingSide
                            newAttack.pulsating = modelAttack.pulsating
                            newAttack.pulsatingSide = modelAttack.pulsatingSide
                            newAttack.auras = modelAttack.auras
                            newAttack.symptoms = modelAttack.symptoms
                            newAttack.onPeriod = modelAttack.onPeriod
                            newAttack.startTime = lastRecorded
                            if lastRecorded != today {
                                newAttack.stopTime = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: lastRecorded)
                            }
                            dayData[index].addToAttack(newAttack)
                            saveData()
                        } else {
                            let newDay = DayData(context: viewContext)
                            newDay.date = dateFormatter.string(from: lastRecorded)
                            
                            let newAttack = Attack(context: viewContext)
                            newAttack.id = UUID().uuidString
                            newAttack.headacheType = modelAttack.headacheType
                            newAttack.otherPainText = modelAttack.otherPainText
                            newAttack.otherPainGroup = modelAttack.otherPainGroup
                            newAttack.painLevel = modelAttack.painLevel
                            newAttack.pressing = modelAttack.pressing
                            newAttack.pressingSide = modelAttack.pressingSide
                            newAttack.pulsating = modelAttack.pulsating
                            newAttack.pulsatingSide = modelAttack.pulsatingSide
                            newAttack.auras = modelAttack.auras
                            newAttack.symptoms = modelAttack.symptoms
                            newAttack.onPeriod = modelAttack.onPeriod
                            newAttack.startTime = lastRecorded
                            if lastRecorded != today {
                                newAttack.stopTime = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: lastRecorded)
                            }
                            newDay.addToAttack(newAttack)
                            saveData()
                        }
                        lastRecorded = Calendar.current.date(byAdding: .day, value: 1, to: lastRecorded) ?? Date.now
                    }
                } else { // End ongoing attack
                    let lastUnendedAttack = dayData[index].attacks[attackIndex]
                    lastUnendedAttack.stopTime = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: lastRecorded)
                }
            }
        }
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}
