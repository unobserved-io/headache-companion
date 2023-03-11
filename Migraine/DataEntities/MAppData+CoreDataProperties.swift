//
//  MAppData+CoreDataProperties.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/10/23.
//
//

import Foundation
import CoreData


extension MAppData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MAppData> {
        return NSFetchRequest<MAppData>(entityName: "MAppData")
    }

    @NSManaged public var doctorNotes: String?
    @NSManaged public var commonMedications: NSSet?
    
    var commonMeds: [Medication] {
        let set = commonMedications as? Set<Medication> ?? []

        return set.sorted {
            $0.wrappedName < $1.wrappedName
        }
    }

}

// MARK: Generated accessors for commonMedications
extension MAppData {

    @objc(addCommonMedicationsObject:)
    @NSManaged public func addToCommonMedications(_ value: Medication)

    @objc(removeCommonMedicationsObject:)
    @NSManaged public func removeFromCommonMedications(_ value: Medication)

    @objc(addCommonMedications:)
    @NSManaged public func addToCommonMedications(_ values: NSSet)

    @objc(removeCommonMedications:)
    @NSManaged public func removeFromCommonMedications(_ values: NSSet)

}

extension MAppData : Identifiable {

}
