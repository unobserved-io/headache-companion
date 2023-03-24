//
//  StatsHelper.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/12/23.
//

import Foundation
import SwiftUI
import CoreData

class StatsHelper: ObservableObject {
    static let sharedInstance = StatsHelper()
    
    @Published var daysTracked: Int = 0
    @Published var daysWithAttack: Int = 0
    @Published var numberOfAttacks: Int = 0
    @Published var allSymptoms = Set<String>()
    @Published var allAuras = Set<String>()
    @Published var allTypesOfHeadache: [(key: String, value: Int)] = []
    @Published var mostCommonTypeOfHeadache: String = ""
    @Published var averagePainLevel: Double = 0.0
    @Published var percentWithAttack: Int = 0
//    @Published var waterInSelectedDays: [ActivityRanks] = []
//    @Published var dietInSelectedDays: [ActivityRanks] = []
//    @Published var exerciseInSelectedDays: [ActivityRanks] = []
//    @Published var relaxInSelectedDays: [ActivityRanks] = []
//    @Published var sleepInSelectedDays: [ActivityRanks] = []
    @Published var waterInSelectedDays: [Double] = [0, 0, 0, 0]
    @Published var dietInSelectedDays: [Double] = [0, 0, 0, 0]
    @Published var exerciseInSelectedDays: [Double] = [0, 0, 0, 0]
    @Published var relaxInSelectedDays: [Double] = [0, 0, 0, 0]
    @Published var sleepInSelectedDays: [Double] = [0, 0, 0, 0]
    
    private let dateFormatter: DateFormatter = {
        let dateformat = DateFormatter()
        dateformat.dateFormat = "yyyy-MM-dd"
        return dateformat
    }()
    
    func getStats(from dayData: [DayData], startDate: Date) {
        resetAllStats()
        calculateMainStats(dayData)
        calculateActivityStats(dayData, startDate: startDate)
    }
    
    private func calculateMainStats(_ dayData: [DayData]) {
        var painLevelsPerDay: [Double] = []
        
        for day in dayData {
            daysTracked += 1
            
            // Attack stats
            if !day.attacks.isEmpty {
                daysWithAttack += 1
                numberOfAttacks += day.attacks.count
                
                var painLevels: [Double] = []
                for attack in day.attacks {
                    if !attack.symptoms.isEmpty {
                        for symptom in attack.symptoms {
                            allSymptoms.insert(symptom)
                        }
                    }
                    if !attack.auras.isEmpty {
                        for aura in attack.auras {
                            allAuras.insert(aura)
                        }
                    }
                    
                    painLevels.append(attack.painLevel)
                    
                    if let index = allTypesOfHeadache.firstIndex(where: {$0.key == headacheTypeString(attack.headacheType)}) {
                        allTypesOfHeadache[index].value += 1
                    } else {
                        allTypesOfHeadache.append((headacheTypeString(attack.headacheType), 1))
                    }
                }
                painLevelsPerDay.append(painLevels.reduce(0,+) / Double(painLevels.count))
            }
        }
        
        // Get final numbers from sets
        if !allTypesOfHeadache.isEmpty {
            let largest = allTypesOfHeadache.max { a, b in a.value < b.value }
            mostCommonTypeOfHeadache = largest?.key ?? "Unknown"
        }
        averagePainLevel = daysWithAttack == 0 ? 0 : painLevelsPerDay.reduce(0,+) / Double(daysWithAttack)
        getPercentWithAttack()
    }
    
//    private func calculateActivityStats(_ dayData: [DayData], startDate: Date) {
//        var listOfDatesBetween: [String] = []
//        var beginDate = startDate
//        let endDate = Date.now
//        while beginDate.compare(endDate) != .orderedDescending {
//            listOfDatesBetween.append(dateFormatter.string(from: beginDate))
//            beginDate = Calendar.current.date(byAdding: .day, value: 1, to: beginDate) ?? Date.now
//        }
//
//        for between in listOfDatesBetween {
//            if let index = dayData.firstIndex(where: { $0.date == between }) {
//                waterInSelectedDays.append(dayData[index].water)
//                dietInSelectedDays.append(dayData[index].diet)
//                exerciseInSelectedDays.append(dayData[index].exercise)
//                relaxInSelectedDays.append(dayData[index].relax)
//                sleepInSelectedDays.append(dayData[index].sleep)
//            } else {
//                waterInSelectedDays.append(.none)
//                dietInSelectedDays.append(.none)
//                exerciseInSelectedDays.append(.none)
//                relaxInSelectedDays.append(.none)
//                sleepInSelectedDays.append(.none)
//            }
//        }
//    }
    
//    private func calculateActivityStats(_ dayData: [DayData], startDate: Date) {
//        for day in dayData {
//            if (dateFormatter.date(from: day.date ?? "1970-01-01")?.isBetween(startDate, and: Date.now) ?? false) {
//                waterInSelectedDays.append(day.water)
//                dietInSelectedDays.append(day.diet)
//                exerciseInSelectedDays.append(day.exercise)
//                relaxInSelectedDays.append(day.relax)
//                sleepInSelectedDays.append(day.sleep)
//            }
//        }
//    }
    private func calculateActivityStats(_ dayData: [DayData], startDate: Date) {
        var currentDate = startDate
        
        while currentDate.compare(Date.now) != .orderedDescending {
            if let index = dayData.firstIndex(where: { $0.date == dateFormatter.string(from: currentDate) }) {
                waterInSelectedDays[Int(dayData[index].water.rawValue)] += 1
                dietInSelectedDays[Int(dayData[index].diet.rawValue)] += 1
                exerciseInSelectedDays[Int(dayData[index].exercise.rawValue)] += 1
                relaxInSelectedDays[Int(dayData[index].relax.rawValue)] += 1
                sleepInSelectedDays[Int(dayData[index].sleep.rawValue)] += 1
            } else {
                waterInSelectedDays[0] += 1
                dietInSelectedDays[0] += 1
                exerciseInSelectedDays[0] += 1
                relaxInSelectedDays[0] += 1
                sleepInSelectedDays[0] += 1
            }
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? Date.now
        }
        for day in dayData {
            if (dateFormatter.date(from: day.date ?? "1970-01-01")?.isBetween(startDate, and: Date.now) ?? false) {
                waterInSelectedDays[Int(day.water.rawValue)] += 1
                dietInSelectedDays[Int(day.diet.rawValue)] += 1
                exerciseInSelectedDays[Int(day.exercise.rawValue)] += 1
                relaxInSelectedDays[Int(day.relax.rawValue)] += 1
                sleepInSelectedDays[Int(day.sleep.rawValue)] += 1
            }
        }
    }
    
    private func resetAllStats() {
        daysTracked = 0
        daysWithAttack = 0
        numberOfAttacks = 0
        allSymptoms.removeAll()
        allAuras.removeAll()
        allTypesOfHeadache.removeAll()
        averagePainLevel = 0.0
        percentWithAttack = 0
//        waterInSelectedDays.removeAll()
//        dietInSelectedDays.removeAll()
//        exerciseInSelectedDays.removeAll()
//        relaxInSelectedDays.removeAll()
//        sleepInSelectedDays.removeAll()
        waterInSelectedDays = [0, 0, 0, 0]
        dietInSelectedDays = [0, 0, 0, 0]
        exerciseInSelectedDays = [0, 0, 0, 0]
        relaxInSelectedDays = [0, 0, 0, 0]
        sleepInSelectedDays = [0, 0, 0, 0]
    }
    
    private func getPercentWithAttack() {
        if daysTracked == 0 {
            percentWithAttack = 0
        } else {
            percentWithAttack = Int((Double(daysWithAttack) / Double(daysTracked)) * 100)
        }
    }
}
