//
//  Medication+CoreDataProperties.swift
//  Migraine
//
//  Created by Ricky Kresslein on 2/28/23.
//
//

import Foundation
import CoreData


extension Medication {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Medication> {
        return NSFetchRequest<Medication>(entityName: "Medication")
    }

    @NSManaged public var id: String?
    @NSManaged public var amount: Int32
    @NSManaged public var dose: String?
    @NSManaged public var effective: Bool
    @NSManaged public var time: Date?
    @NSManaged public var name: String?
    @NSManaged public var sideEffects: String?
    @NSManaged public var type: MedTypes
    @NSManaged public var date: DayData?
    
    public var wrappedTime: Date {
        time ?? Date.init(timeIntervalSince1970: 0)
    }
    
    public var wrappedName: String {
        name ?? "Unknown"
    }
}

extension Medication : Identifiable {

}
