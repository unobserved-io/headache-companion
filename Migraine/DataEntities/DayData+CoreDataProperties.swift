//
//  DayData+CoreDataProperties.swift
//  Migraine
//
//  Created by Ricky Kresslein on 2/28/23.
//
//

import CoreData
import Foundation

public extension DayData {
    @nonobjc class func fetchRequest() -> NSFetchRequest<DayData> {
        return NSFetchRequest<DayData>(entityName: "DayData")
    }

    @NSManaged var date: String?
    @NSManaged var diet: Int16
    @NSManaged var exercise: Int16
    @NSManaged var notes: String
    @NSManaged var relax: Int16
    @NSManaged var sleep: Int16
    @NSManaged var water: Int16
    @NSManaged var attack: NSSet?
    @NSManaged var medication: NSSet?

    var attacks: [Attack] {
        let set = attack as? Set<Attack> ?? []

        return set.sorted {
            $0.wrappedStartTime < $1.wrappedStartTime
        }
    }

    var medications: [Medication] {
        let set = medication as? Set<Medication> ?? []

        return set.sorted {
            $0.wrappedTime < $1.wrappedTime
        }
    }
}

// MARK: Generated accessors for attack

public extension DayData {
    @objc(addAttackObject:)
    @NSManaged func addToAttack(_ value: Attack)

    @objc(removeAttackObject:)
    @NSManaged func removeFromAttack(_ value: Attack)

    @objc(addAttack:)
    @NSManaged func addToAttack(_ values: NSSet)

    @objc(removeAttack:)
    @NSManaged func removeFromAttack(_ values: NSSet)
}

// MARK: Generated accessors for medication

public extension DayData {
    @objc(addMedicationObject:)
    @NSManaged func addToMedication(_ value: Medication)

    @objc(removeMedicationObject:)
    @NSManaged func removeFromMedication(_ value: Medication)

    @objc(addMedication:)
    @NSManaged func addToMedication(_ values: NSSet)

    @objc(removeMedication:)
    @NSManaged func removeFromMedication(_ values: NSSet)
}

extension DayData: Identifiable {}
