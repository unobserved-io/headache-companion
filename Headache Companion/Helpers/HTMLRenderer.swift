//
//  HTMLRenderer.swift
//  Headache Companion
//
//  Created by Ricky Kresslein on 7/13/23.
//

import SwiftUI

struct HTMLRenderer {
    var dayData: FetchedResults<DayData>
    
    init(dayData: FetchedResults<DayData>) {
        self.dayData = dayData
    }
    
    func renderHTML() -> String? {
        let timeFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter
        }()
        
        do {
            // Load the invoice HTML template code into a String variable.
            var htmlFrame = try String(contentsOfFile: Bundle.main.path(forResource: "ExportTemplate.html", ofType: nil)!)
            let dayRowTemplate = try String(contentsOfFile: Bundle.main.path(forResource: "DayRowTemplate.html", ofType: nil)!)
            let attackTemplate = try String(contentsOfFile: Bundle.main.path(forResource: "AttackTemplate.html", ofType: nil)!)
            let medicationTemplate = try String(contentsOfFile: Bundle.main.path(forResource: "MedicationTemplate.html", ofType: nil)!)
            
            var allDayRows = ""
            dayData.forEach() { day in
                var newDayRow = dayRowTemplate
                
                newDayRow = newDayRow.replacingOccurrences(of: "#DATE#", with: day.date ?? "Unknown")
                newDayRow = newDayRow.replacingOccurrences(of: "#NUM_OF_ATTACKS#", with: String(day.attacks.count))
                
                // ATTACKS
                var allAttacks = ""
                day.attacks.forEach() { attack in
                    var newAttack = attackTemplate
                    
                    if attack.stopTime != nil {
                        let startStop = "\(timeFormatter.string(from: attack.wrappedStartTime)) to \(timeFormatter.string(from: attack.wrappedStopTime))"
                        newAttack = newAttack.replacingOccurrences(of: "#START_TIME#", with: startStop)
                    } else {
                        newAttack = newAttack.replacingOccurrences(of: "#START_TIME#", with: timeFormatter.string(from: attack.wrappedStartTime))
                    }
                    
                    newAttack = newAttack.replacingOccurrences(of: "#TYPE_OF_HEADACHE#", with: attack.headacheType.localizedCapitalized)
                    
                    // PAIN
                    if attack.painLevel == 0 {
                        newAttack = newAttack.replacingOccurrences(of: "#PAIN_LEVEL#", with: String(attack.painLevel))
                    } else {
                        var painString = ""
                        if attack.pulsating || attack.pressing {
                            painString = "<ul>#CONTENTS#</ul>"
                            var painInner = ""
                            
                            if attack.pressing {
                                painInner += "<li>Pressure</li>"
                                if attack.pressingSide != .none {
                                    if attack.pressingSide == .one {
                                        painInner += "<ul><li>One side</li></ul>"
                                    } else {
                                        painInner += "<ul><li>Both sides</li></ul>"
                                    }
                                }
                            }
                            if attack.pulsating {
                                painInner += "<li>Pulsating</li>"
                                if attack.pulsatingSide != .none {
                                    if attack.pulsatingSide == .one {
                                        painInner += "<ul><li>One side</li></ul>"
                                    } else {
                                        painInner += "<ul><li>Both sides</li></ul>"
                                    }
                                }
                            }
                            painString = painString.replacingOccurrences(of: "#CONTENTS#", with: painInner)
                        } else {
                            painString = String(attack.painLevel)
                        }
                        
                        newAttack = newAttack.replacingOccurrences(of: "#PAIN_LEVEL#", with: painString)
                    }
                    
                    var symptoms = ""
                    if attack.symptoms.isEmpty {
                        symptoms = "None"
                    } else {
                        symptoms = String(attack.symptoms.joined(separator: ", "))
                    }
                    newAttack = newAttack.replacingOccurrences(of: "#SYMPTOMS#", with: symptoms)
                    
                    var auras = ""
                    if attack.auras.isEmpty {
                        auras = "None"
                    } else {
                        auras = String(attack.auras.joined(separator: ", "))
                    }
                    newAttack = newAttack.replacingOccurrences(of: "#AURAS#", with: auras)
                    
                    allAttacks += newAttack
                }
                
                // MEDICATION
                var allMedication = ""
                day.medications.forEach() { med in
                    var newMedication = medicationTemplate
                    
                    var medTitle = ""
                    if med.dose != nil {
                        medTitle = "\(med.amount) \(med.name ?? "Unknown") - \(med.dose!)"
                    } else {
                        medTitle = "\(med.amount) \(med.name ?? "Unknown")"
                    }
                    newMedication = newMedication.replacingOccurrences(of: "#MED_TITLE#", with: medTitle)
                    
                    newMedication = newMedication.replacingOccurrences(of: "#MED_TIME#", with: timeFormatter.string(from: med.wrappedTime))
                    
                    var medEffective = ""
                    switch(med.effective) {
                    case .effective:
                        medEffective = "<li>Effective</li>"
                    case .ineffective:
                        medEffective = "<li>Ineffective</li>"
                    case .none:
                        medEffective = ""
                    }
                    newMedication = newMedication.replacingOccurrences(of: "#MED_EFFECTIVE#", with: medEffective)
                    newMedication = newMedication.replacingOccurrences(of: "#MED_TYPE#", with: med.type)
                    
                    allMedication += newMedication
                }
                
                // WELL-BEING
                newDayRow = newDayRow.replacingOccurrences(of: "#WATER_VALUE#", with: getActivityString(day.water))
                newDayRow = newDayRow.replacingOccurrences(of: "#DIET_VALUE#", with: getActivityString(day.diet))
                newDayRow = newDayRow.replacingOccurrences(of: "#SLEEP_VALUE#", with: getActivityString(day.sleep))
                newDayRow = newDayRow.replacingOccurrences(of: "#EXERCISE_VALUE#", with: getActivityString(day.exercise))
                newDayRow = newDayRow.replacingOccurrences(of: "#RELAX_VALUE#", with: getActivityString(day.relax))
                
                newDayRow = newDayRow.replacingOccurrences(of: "#ATTACK_SECTION#", with: allAttacks)
                newDayRow = newDayRow.replacingOccurrences(of: "#MEDICATION_SECTION#", with: allMedication)
                
                allDayRows += newDayRow
            }
            
            htmlFrame = htmlFrame.replacingOccurrences(of: "#DAY_ROWS#", with: allDayRows)
            
            return htmlFrame
        } catch {
            print("Unable to open and use HTML template file.")
        }
         
        return nil
    }
    
    private func getActivityString(_ activity: ActivityRanks) -> String {
        switch(activity) {
        case .none:
            return "N/A"
        case .bad:
            return "Bad"
        case .ok:
            return "OK"
        case .good:
            return "Good"
        }
    }
}
