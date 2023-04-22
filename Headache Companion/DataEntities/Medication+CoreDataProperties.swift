//
//  Medication+CoreDataProperties.swift
//  Headache Companion
//
//  Created by Ricky Kresslein on 3/26/23.
//
//

import CoreData
import Foundation

public extension Medication {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Medication> {
        return NSFetchRequest<Medication>(entityName: "Medication")
    }

    @NSManaged var id: String?
    @NSManaged var amount: Int32
    @NSManaged var dose: String?
    @NSManaged var effective: Effectiveness
    @NSManaged var time: Date?
    @NSManaged var name: String?
    @NSManaged var sideEffects: String?
    @NSManaged var type: String
    @NSManaged var date: DayData?

    var wrappedTime: Date {
        time ?? Date(timeIntervalSince1970: 0)
    }

    var wrappedName: String {
        name ?? "Unknown"
    }
}

extension Medication: Identifiable {}
