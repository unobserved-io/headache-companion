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
    @Published var attacksWithAura: Int = 0
    @Published var allSymptoms = Set<String>()
    @Published var symptomsByHeadache: [(key: String, value: Set<String>)] = []
    @Published var allAuras: [(key: String, value: Int)] = []
    @Published var allTypesOfHeadache: [(key: String, value: Int)] = []
    @Published var daysWithMedication: Int = 0
    @Published var daysByMedType: [(key: String, value: Int)] = []
    @Published var medicationByMedType: [(key: String, value: Set<String>)] = []
    @Published var percentWithMedication: Int = 0
    @Published var mostCommonTypeOfHeadache: String = ""
    @Published var averagePainLevel: Double = 0.0
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
        resetAllStats()
        calculateMainStats(dayData)
        calculateActivityStats(dayData, startDate: startDate, stopDate: stopDate)
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
                day.attacks.forEach { attack in
                    if !attack.auras.isEmpty {
                        attacksWithAura += 1
                    }
                    if !attack.symptoms.isEmpty {
                        for symptom in attack.symptoms {
                            allSymptoms.insert(symptom)
                            if let index = symptomsByHeadache.firstIndex(where: {$0.key == attack.headacheType}) {
                                symptomsByHeadache[index].value.insert(symptom)
                            } else {
                                symptomsByHeadache.append((attack.headacheType, [symptom]))
                            }
                        }
                    }
                    if !attack.auras.isEmpty {
                        for aura in attack.auras {
                            if let index = allAuras.firstIndex(where: {$0.key == aura}) {
                                allAuras[index].value += 1
                            } else {
                                allAuras.append((aura, 1))
                            }
                        }
                    }
                    
                    painLevels.append(attack.painLevel)
                    
                    if let index = allTypesOfHeadache.firstIndex(where: {$0.key == attack.headacheType}) {
                        allTypesOfHeadache[index].value += 1
                    } else {
                        allTypesOfHeadache.append((attack.headacheType, 1))
                    }
                }
                painLevelsPerDay.append(painLevels.reduce(0,+) / Double(painLevels.count))
            }
            
            // Medication stats
            if !day.medications.isEmpty {
                var medTypesThisDay: Set<String> = []
                daysWithMedication += 1
                
                day.medications.forEach { medication in
                    medTypesThisDay.insert(medication.type)
                    if let index = medicationByMedType.firstIndex(where: {$0.key == medication.type}) {
                        medicationByMedType[index].value.insert(medication.name ?? "Unknown")
                    } else {
                        medicationByMedType.append((medication.type, [medication.name ?? "Unknown"]))
                    }
                }
                
                medTypesThisDay.forEach { medType in
                    if let index = daysByMedType.firstIndex(where: {$0.key == medType}) {
                        daysByMedType[index].value += 1
                    } else {
                        daysByMedType.append((medType, 1))
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
        daysByMedType.sort(by: {$0.key > $1.key})
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
    
    private func resetAllStats() {
        daysTracked = 0
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
        percentWithAttack = 0
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
    
    private func getPercentWithMedication() {
        if daysTracked == 0 {
            percentWithMedication = 0
        } else {
            percentWithMedication = Int((Double(daysWithMedication) / Double(daysTracked)) * 100)
        }
    }
}
