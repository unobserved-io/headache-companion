//
//  StatsHelper.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/12/23.
//

import CoreData
import Foundation
import SwiftUI

class StatsHelper: ObservableObject {
    static let sharedInstance = StatsHelper()
    
    @Published var daysInRange: Int = 0
    @Published var daysTrackedInRange: Int = 0
    @Published var daysTrackedTotal: Int = 0
    @Published var daysWithAttack: Int = 0
    @Published var numberOfAttacks: Int = 0
    @Published var attacksWithAura: Int = 0
    @Published var allSymptoms = Set<String>()
    @Published var symptomsByHeadache: [(key: String, value: Set<String>)] = []
    @Published var allAuras: [(key: String, value: Int)] = []
    @Published var allTypesOfHeadache: [(key: String, value: Int)] = []
    @Published var daysWithMedication: Int = 0
    @Published var daysByMedType: [(key: String, value: Int)] = []
    @Published var medicationByMedType: [(key: String, value: [(key: String, value: Int)])] = []
    @Published var percentWithMedication: Int = 0
    @Published var mostCommonTypeOfHeadache: String = ""
    @Published var averagePainLevel: Double = 0.0
    @Published var percentTrackedWithAttack: Int = 0
    @Published var percentWithAttack: Int = 0
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
    
    func getStats(from dayData: [DayData], startDate: Date, stopDate: Date) {
        print("Start: \(startDate)")
        print("Stop: \(stopDate)")
        resetAllStats()
        
        // Get total days
        let difference = Calendar.current.dateComponents([Calendar.Component.day], from: startDate, to: stopDate)
        daysInRange = (difference.day ?? 0) + 1
        
        // Calculate stats
        DispatchQueue.main.async {
            self.calculateMainStats(dayData)
            self.calculateActivityStats(dayData, startDate: startDate, stopDate: stopDate)
        }
    }
    
    private func calculateMainStats(_ dayData: [DayData]) {
        var painLevelsPerDay: [Double] = []
        
        for day in dayData {
            // Check if the day has any data
            if !day.attacks.isEmpty ||
                !day.medications.isEmpty ||
                day.diet != .none ||
                day.water != .none ||
                day.sleep != .none ||
                day.relax != .none ||
                day.exercise != .none
            {
                daysTrackedInRange += 1
            }
            
            // Attack stats
            if !day.attacks.isEmpty {
                daysWithAttack += 1
                numberOfAttacks += day.attacks.count
                
                var painLevels: [Double] = []
                day.attacks.forEach { attack in
                    if !attack.auras.isEmpty {
                        attacksWithAura += 1
                    }
                    if !attack.symptoms.isEmpty {
                        for symptom in attack.symptoms {
                            allSymptoms.insert(symptom)
                            if let index = symptomsByHeadache.firstIndex(where: { $0.key == attack.headacheType }) {
                                symptomsByHeadache[index].value.insert(symptom)
                            } else {
                                symptomsByHeadache.append((attack.headacheType, [symptom]))
                            }
                        }
                    }
                    if !attack.auras.isEmpty {
                        for aura in attack.auras {
                            if let index = allAuras.firstIndex(where: { $0.key == aura }) {
                                allAuras[index].value += 1
                            } else {
                                allAuras.append((aura, 1))
                            }
                        }
                    }
                    
                    painLevels.append(attack.painLevel)
                    
                    if let index = allTypesOfHeadache.firstIndex(where: { $0.key == attack.headacheType }) {
                        allTypesOfHeadache[index].value += 1
                    } else {
                        allTypesOfHeadache.append((attack.headacheType, 1))
                    }
                }
                painLevelsPerDay.append(painLevels.reduce(0,+) / Double(painLevels.count))
            }
            
            // Medication stats
            if !day.medications.isEmpty {
                var medNamesThisDayByType: [(key: String, value: Set<String>)] = []
                daysWithMedication += 1
                
                day.medications.forEach { medication in
                    if let index = medNamesThisDayByType.firstIndex(where: { $0.key == medication.type }) {
                        medNamesThisDayByType[index].value.insert(medication.name ?? "Unknown")
                    } else {
                        medNamesThisDayByType.append((medication.type, [medication.name ?? "Unknown"]))
                    }
                }
                
                medNamesThisDayByType.forEach { medType, medNames in
                    if let index = daysByMedType.firstIndex(where: { $0.key == medType }) {
                        daysByMedType[index].value += 1
                    } else {
                        daysByMedType.append((medType, 1))
                    }
                    
                    if let index = medicationByMedType.firstIndex(where: { $0.key == medType }) {
                        medNames.forEach { medName in
                            if let index2 = medicationByMedType[index].value.firstIndex(where: { $0.key == medName }) {
                                medicationByMedType[index].value[index2].value += 1
                            } else {
                                medicationByMedType[index].value.append((medName, 1))
                            }
                        }
                    } else {
                        medicationByMedType.append((medType, []))
                        if let index = medicationByMedType.firstIndex(where: { $0.key == medType }) {
                            medNames.forEach { medName in
                                if let index2 = medicationByMedType[index].value.firstIndex(where: { $0.key == medName }) {
                                    medicationByMedType[index].value[index2].value += 1
                                } else {
                                    medicationByMedType[index].value.append((medName, 1))
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Get final numbers from sets
        if !allTypesOfHeadache.isEmpty {
            let largest = allTypesOfHeadache.max { a, b in a.value < b.value }
            mostCommonTypeOfHeadache = largest?.key ?? "Unknown"
        }
        averagePainLevel = daysWithAttack == 0 ? 0 : painLevelsPerDay.reduce(0,+) / Double(daysWithAttack)
        getPercentWithAttack()
        getPercentWithMedication()
        daysByMedType.sort(by: { $0.key > $1.key })
    }
    
    private func calculateActivityStats(_ dayData: [DayData], startDate: Date, stopDate: Date) {
        var currentDate = startDate
        
        while currentDate.compare(stopDate) != .orderedDescending {
            if let index = dayData.firstIndex(where: { $0.date == dateFormatter.string(from: currentDate) }) {
                waterInSelectedDays[Int(dayData[index].water.rawValue)] += 1
                dietInSelectedDays[Int(dayData[index].diet.rawValue)] += 1
                exerciseInSelectedDays[Int(dayData[index].exercise.rawValue)] += 1
                relaxInSelectedDays[Int(dayData[index].relax.rawValue)] += 1
                sleepInSelectedDays[Int(dayData[index].sleep.rawValue)] += 1
            }
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? Date.now
        }
    }
    
    private func getPercentWithAttack() {
        // % of days with attack
        if daysInRange == 0 {
            percentWithAttack = 0
        } else {
            percentWithAttack = Int((Double(daysWithAttack) / Double(daysInRange)) * 100)
        }
        
        // % of days tracked with attack
        if daysTrackedInRange == 0 {
            percentTrackedWithAttack = 0
        } else {
            percentTrackedWithAttack = Int((Double(daysWithAttack) / Double(daysTrackedInRange)) * 100)
        }
    }
    
    private func getPercentWithMedication() {
        if daysTrackedInRange == 0 {
            percentWithMedication = 0
        } else {
            percentWithMedication = Int((Double(daysWithMedication) / Double(daysTrackedInRange)) * 100)
        }
    }
    
    private func resetAllStats() {
        daysInRange = 0
        daysTrackedInRange = 0
        daysTrackedTotal = 0
        daysWithAttack = 0
        daysWithMedication = 0
        daysByMedType = []
        medicationByMedType = []
        numberOfAttacks = 0
        attacksWithAura = 0
        allSymptoms.removeAll()
        allAuras.removeAll()
        allTypesOfHeadache.removeAll()
        averagePainLevel = 0.0
        percentTrackedWithAttack = 0
        waterInSelectedDays = [0, 0, 0, 0]
        dietInSelectedDays = [0, 0, 0, 0]
        exerciseInSelectedDays = [0, 0, 0, 0]
        relaxInSelectedDays = [0, 0, 0, 0]
        sleepInSelectedDays = [0, 0, 0, 0]
    }
}
