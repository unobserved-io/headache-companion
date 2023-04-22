//
//  MAppData+CoreDataProperties.swift
//  Headache Companion
//
//  Created by Ricky Kresslein on 3/26/23.
//
//

import CoreData
import SwiftUI

public extension MAppData {
    @nonobjc class func fetchRequest() -> NSFetchRequest<MAppData> {
        return NSFetchRequest<MAppData>(entityName: "MAppData")
    }

    @NSManaged var doctorNotes: String?
    @NSManaged var customAuras: [String]?
    @NSManaged var customSideEffects: [String]?
    @NSManaged var customHeadacheTypes: [String]?
    @NSManaged var customMedTypes: [String]?
    @NSManaged var customSymptoms: [String]?
    @NSManaged var defaultEffectiveness: Effectiveness
    @NSManaged var activityColors: [String]?
    @NSManaged var getsPeriod: Bool
    @NSManaged var attacksEndWithDay: Bool
    @NSManaged var launchDay: Date
    @NSManaged var regularMedications: NSSet?

    internal var regularMeds: [Medication] {
        let set = regularMedications as? Set<Medication> ?? []

        return set.sorted {
            $0.wrappedName < $1.wrappedName
        }
    }
}

// MARK: Generated accessors for commonMedications

public extension MAppData {
    @objc(addRegularMedicationsObject:)
    @NSManaged func addToRegularMedications(_ value: Medication)

    @objc(removeRegularMedicationsObject:)
    @NSManaged func removeFromRegularMedications(_ value: Medication)

    @objc(addRegularMedications:)
    @NSManaged func addToRegularMedications(_ values: NSSet)

    @objc(removeRegularMedications:)
    @NSManaged func removeFromRegularMedications(_ values: NSSet)
}

extension MAppData: Identifiable {}
