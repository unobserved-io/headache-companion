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
    @Published var waterInSelectedDays: [ActivityRanks] = []
    @Published var dietInSelectedDays: [ActivityRanks] = []
    @Published var exerciseInSelectedDays: [ActivityRanks] = []
    @Published var relaxInSelectedDays: [ActivityRanks] = []
    @Published var sleepInSelectedDays: [ActivityRanks] = []
    
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
//                    if allTypesOfHeadache[headacheTypeString(attack.headacheType)] != nil {
//                        allTypesOfHeadache[headacheTypeString(attack.headacheType)]! += 1
//                    } else {
//                        allTypesOfHeadache[headacheTypeString(attack.headacheType)] = 1
//                    }
                    if allTypesOfHeadache.contains(where: {$0.key == headacheTypeString(attack.headacheType)}) {
                        
                    }
                    
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
    
    private func calculateActivityStats(_ dayData: [DayData], startDate: Date) {
        var listOfDatesBetween: [String] = []
        var date = startDate
        let endDate = Date.now
        while date.compare(endDate) != .orderedDescending {
            listOfDatesBetween.append(dateFormatter.string(from: date))
            // Advance by one day:
            date = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? Date.now
        }
        
        var found = false
        for between in listOfDatesBetween {
            for oneDayData in dayData {
                if oneDayData.date == between {
                    waterInSelectedDays.append(oneDayData.water)
                    dietInSelectedDays.append(oneDayData.diet)
                    exerciseInSelectedDays.append(oneDayData.exercise)
                    relaxInSelectedDays.append(oneDayData.relax)
                    sleepInSelectedDays.append(oneDayData.sleep)
                    found = true
                    break
                }
            }
            if !found {
                waterInSelectedDays.append(.none)
                dietInSelectedDays.append(.none)
                exerciseInSelectedDays.append(.none)
                relaxInSelectedDays.append(.none)
                sleepInSelectedDays.append(.none)
            }
            found = false
        }
    }
    
    private func resetAllStats() {
        daysTracked = 0
        daysWithAttack = 0
        numberOfAttacks = 0
        allSymptoms = []
        allAuras = []
        allTypesOfHeadache = []
        averagePainLevel = 0.0
        percentWithAttack = 0
        waterInSelectedDays = []
        dietInSelectedDays = []
        exerciseInSelectedDays = []
        relaxInSelectedDays = []
        sleepInSelectedDays = []
    }
    
    private func getPercentWithAttack() {
        if daysTracked == 0 {
            percentWithAttack = 0
        } else {
            percentWithAttack = Int((Double(daysWithAttack) / Double(daysTracked)) * 100)
        }
    }
    
    private func headacheTypeString(_ type: Headaches) -> String {
        switch type {
        case .migraine:
            return "Migraine"
        case .tension:
            return "Tension"
        case .cluster:
            return "Cluster"
        case .exertional:
            return "Exertional"
        case .hypnic:
            return "Hypnic"
        case .sinus:
            return "Sinus"
        case .caffeine:
            return "Caffeine"
        case .injury:
            return "Inuury"
        case .menstrual:
            return "Menstrual"
        case .other:
            return "Other"
        }
    }
    
//    func getAllData() -> [DayData] {
//        let fetchRequest: NSFetchRequest<DayData> = DayData.fetchRequest()
//
//        do {
//            return try PersistenceController.shared.container.viewContext.fetch(fetchRequest)
//        } catch {
//            print("Failed to fetch day data: \(error)")
//            return []
//        }
//    }
}
