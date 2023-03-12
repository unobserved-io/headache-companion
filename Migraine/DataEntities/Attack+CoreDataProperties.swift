//
//  Attack+CoreDataProperties.swift
//  Migraine
//
//  Created by Ricky Kresslein on 2/28/23.
//
//

import Foundation
import CoreData


extension Attack {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Attack> {
        return NSFetchRequest<Attack>(entityName: "Attack")
    }

    @NSManaged public var id: String?
    @NSManaged public var headacheType: Headaches
    @NSManaged public var otherPainGroup: Int16
    @NSManaged public var otherPainText: String?
    @NSManaged public var painLevel: Double
    @NSManaged public var pressing: Bool
    @NSManaged public var pressingSide: Sides
    @NSManaged public var pulsating: Bool
    @NSManaged public var pulsatingSide: Sides
    @NSManaged public var auras: Set<String>
    @NSManaged public var symptoms: Set<String>
    @NSManaged public var startTime: Date?
    @NSManaged public var stopTime: Date?
    @NSManaged public var date: DayData?
    
    public var wrappedStartTime: Date {
        startTime ?? Date.init(timeIntervalSince1970: 0)
    }
    
    public var wrappedStopTime: Date {
        stopTime ?? Date.init(timeIntervalSince1970: 0)
    }

}

extension Attack : Identifiable {

}
