//
//  MedHistory+CoreDataProperties.swift
//  Headache Companion
//
//  Created by Ricky Kresslein on 4/5/23.
//
//

import Foundation
import CoreData


extension MedHistory {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MedHistory> {
        return NSFetchRequest<MedHistory>(entityName: "MedHistory")
    }

    @NSManaged public var id: String?
    @NSManaged public var name: String
    @NSManaged public var amount: Int32
    @NSManaged public var dose: String
    @NSManaged public var frequency: String
    @NSManaged public var effective: Effectiveness
    @NSManaged public var notes: String
    @NSManaged public var type: String
    @NSManaged public var sideEffects: Set<String>?
    @NSManaged public var startDate: Date?
    @NSManaged public var stopDate: Date?
}

extension MedHistory : Identifiable {

}
