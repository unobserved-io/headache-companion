//
//  Extensions.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/4/23.
//

import CoreData
import SwiftUI

extension Binding {
     func toUnwrapped<T>(defaultValue: T) -> Binding<T> where Value == Optional<T>  {
        Binding<T>(get: { self.wrappedValue ?? defaultValue }, set: { self.wrappedValue = $0 })
    }
}

extension PresentationDetent {
    static let bar = Self.fraction(0.2)
}

extension Date {
    func isBetween(_ date1: Date, and date2: Date) -> Bool {
        return (min(date1, date2) ... max(date1, date2)) ~= self
    }
}

// Rounded border
extension View {
     public func addBorder<S>(_ content: S, width: CGFloat = 1, cornerRadius: CGFloat) -> some View where S : ShapeStyle {
         let roundedRect = RoundedRectangle(cornerRadius: cornerRadius)
         return clipShape(roundedRect)
              .overlay(roundedRect.strokeBorder(content, lineWidth: width))
     }
 }

// JSON Encodables
extension Attack: Encodable {
    enum CodingKeys: String, CodingKey {
        case id
        case headacheType
        case otherPainGroup
        case otherPainText
        case painLevel
        case pressing
        case pressingSide
        case pulsating
        case pulsatingSide
        case auras
        case symptoms
        case onPeriod
        case startTime
        case stopTime
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(headacheType, forKey: .headacheType)
        try container.encode(otherPainGroup, forKey: .otherPainGroup)
        try container.encode(otherPainText, forKey: .otherPainText)
        try container.encode(painLevel, forKey: .painLevel)
        try container.encode(pressing, forKey: .pressing)
        try container.encode(pressingSide.rawValue, forKey: .pressingSide)
        try container.encode(pulsating, forKey: .pulsating)
        try container.encode(pulsatingSide.rawValue, forKey: .pulsatingSide)
        try container.encode(auras, forKey: .auras)
        try container.encode(symptoms, forKey: .symptoms)
        try container.encode(onPeriod, forKey: .onPeriod)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(stopTime, forKey: .stopTime)
    }
}

extension Medication: Encodable {
    enum CodingKeys: String, CodingKey {
        case id
        case amount
        case dose
        case effective
        case time
        case name
        case sideEffects
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(amount, forKey: .amount)
        try container.encode(dose, forKey: .dose)
        try container.encode(effective.rawValue, forKey: .effective)
        try container.encode(time, forKey: .time)
        try container.encode(name, forKey: .name)
        try container.encode(sideEffects, forKey: .sideEffects)
        try container.encode(type.rawValue, forKey: .type)
    }
}

extension DayData: Encodable {
    enum CodingKeys: String, CodingKey {
        case date
        case diet
        case exercise
        case notes
        case relax
        case sleep
        case water
        case attacks
        case medications
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(diet.rawValue, forKey: .diet)
        try container.encode(exercise.rawValue, forKey: .exercise)
        try container.encode(notes, forKey: .notes)
        try container.encode(relax.rawValue, forKey: .relax)
        try container.encode(sleep.rawValue, forKey: .sleep)
        try container.encode(water.rawValue, forKey: .water)
        try container.encode(attacks, forKey: .attacks)
        try container.encode(medications, forKey: .medications)
    }
}

extension MedHistory: Encodable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case amount
        case dose
        case frequency
        case effective
        case notes
        case type
        case sideEffects
        case startDate
        case stopDate
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(amount, forKey: .amount)
        try container.encode(dose, forKey: .dose)
        try container.encode(frequency, forKey: .frequency)
        try container.encode(effective.rawValue, forKey: .effective)
        try container.encode(notes, forKey: .notes)
        try container.encode(type.rawValue, forKey: .type)
        try container.encode(sideEffects, forKey: .sideEffects)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(stopDate, forKey: .stopDate)
    }
}

extension CodingUserInfoKey {
    static let context = CodingUserInfoKey(rawValue: "context")!
}

extension JSONDecoder {
    convenience init(context: NSManagedObjectContext) {
        self.init()
        self.userInfo[.context] = context
    }
}
