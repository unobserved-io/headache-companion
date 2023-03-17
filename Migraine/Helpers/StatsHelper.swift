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
    @Published var numberOfSymptoms: Int = 0
    @Published var numberOfAuras: Int = 0
    @Published var numberOfTypesOfHeadaches: Int = 0
    @Published var averagePainLevel: Double = 0.0
    @Published var percentWithAttack: Int = 0
    
    func getStats(from dayData: [DayData]) {
        resetAllStats()
        calculateMainStats(dayData)
    }
    
    private func calculateMainStats(_ dayData: [DayData]) {
        var allSymptoms = Set<String>()
        var allAuras = Set<String>()
        var allTypesOfHeadache = Set<Headaches>()
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
                    allTypesOfHeadache.insert(attack.headacheType)
                }
                painLevelsPerDay.append(painLevels.reduce(0,+) / Double(painLevels.count))
            }
        }
        
        // Get final numbers from sets
        numberOfSymptoms = allSymptoms.count
        numberOfAuras = allAuras.count
        numberOfTypesOfHeadaches = allTypesOfHeadache.count
        averagePainLevel = daysWithAttack == 0 ? 0 : painLevelsPerDay.reduce(0,+) / Double(daysWithAttack)
        getPercentWithAttack()
    }
    
    private func resetAllStats() {
        daysTracked = 0
        daysWithAttack = 0
        numberOfAttacks = 0
        numberOfSymptoms = 0
        numberOfAuras = 0
        numberOfTypesOfHeadaches = 0
        averagePainLevel = 0.0
        percentWithAttack = 0
    }
    
    private func getPercentWithAttack() {
        if daysTracked == 0 {
            percentWithAttack = 0
        } else {
            percentWithAttack = Int((Double(daysWithAttack) / Double(daysTracked)) * 100)
        }
    }
    
    func getAllData() -> [DayData] {
        let fetchRequest: NSFetchRequest<DayData> = DayData.fetchRequest()

        do {
            return try PersistenceController.shared.container.viewContext.fetch(fetchRequest)
        } catch {
            print("Failed to fetch movies: \(error)")
            return []
        }
    }
}
