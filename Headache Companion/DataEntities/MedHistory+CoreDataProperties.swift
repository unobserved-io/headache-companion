//
//  MedHistory+CoreDataProperties.swift
//  Headache Companion
//
//  Created by Ricky Kresslein on 4/5/23.
//
//

import CoreData
import Foundation

public extension MedHistory {
    @nonobjc class func fetchRequest() -> NSFetchRequest<MedHistory> {
        return NSFetchRequest<MedHistory>(entityName: "MedHistory")
    }

    @NSManaged var id: String?
    @NSManaged var name: String
    @NSManaged var amount: Int32
    @NSManaged var dose: String
    @NSManaged var frequency: String
    @NSManaged var effective: Effectiveness
    @NSManaged var notes: String
    @NSManaged var type: String
    @NSManaged var sideEffects: Set<String>?
    @NSManaged var startDate: Date?
    @NSManaged var stopDate: Date?
}

extension MedHistory: Identifiable {}
