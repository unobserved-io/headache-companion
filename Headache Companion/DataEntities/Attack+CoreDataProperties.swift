//
//  Attack+CoreDataProperties.swift
//  Headache Companion
//
//  Created by Ricky Kresslein on 3/26/23.
//
//

import CoreData
import Foundation

public extension Attack {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Attack> {
        return NSFetchRequest<Attack>(entityName: "Attack")
    }

    @NSManaged var id: String?
    @NSManaged var headacheType: String
    @NSManaged var otherPainGroup: Int16
    @NSManaged var otherPainText: String?
    @NSManaged var painLevel: Double
    @NSManaged var pressing: Bool
    @NSManaged var pressingSide: Sides
    @NSManaged var pulsating: Bool
    @NSManaged var pulsatingSide: Sides
    @NSManaged var auras: Set<String>
    @NSManaged var symptoms: Set<String>
    @NSManaged var onPeriod: Bool
    @NSManaged var startTime: Date?
    @NSManaged var stopTime: Date?
    @NSManaged var date: DayData?

    var wrappedStartTime: Date {
        startTime ?? Date(timeIntervalSince1970: 0)
    }

    var wrappedStopTime: Date {
        stopTime ?? Date(timeIntervalSince1970: 0)
    }
}

extension Attack: Identifiable {}
