//
//  MAppData+CoreDataProperties.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/10/23.
//
//

import SwiftUI
import CoreData


extension MAppData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MAppData> {
        return NSFetchRequest<MAppData>(entityName: "MAppData")
    }

    @NSManaged public var doctorNotes: String?
    @NSManaged public var customSymptoms: [String]?
    @NSManaged public var activityColors: [Data]?
    @NSManaged public var getsPeriod: Bool
    @NSManaged public var regularMedications: NSSet?
    
    var regularMeds: [Medication] {
        let set = regularMedications as? Set<Medication> ?? []

        return set.sorted {
            $0.wrappedName < $1.wrappedName
        }
    }

}

// MARK: Generated accessors for commonMedications
extension MAppData {

    @objc(addRegularMedicationsObject:)
    @NSManaged public func addToRegularMedications(_ value: Medication)

    @objc(removeRegularMedicationsObject:)
    @NSManaged public func removeFromRegularMedications(_ value: Medication)

    @objc(addRegularMedications:)
    @NSManaged public func addToRegularMedications(_ values: NSSet)

    @objc(removeRegularMedications:)
    @NSManaged public func removeFromRegularMedications(_ values: NSSet)

}

extension MAppData : Identifiable {

}