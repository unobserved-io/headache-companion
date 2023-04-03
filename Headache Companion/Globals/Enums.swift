//
//  Enums.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/4/23.
//

import Foundation

@objc
public enum Sides: Int16 {
    case none
    case one
    case both
}

@objc
public enum Headaches: Int16 {
    case migraine
    case tension
    case other
}

@objc
public enum MedTypes: Int16 {
    case other
    case preventive
    case symptomRelieving
}

@objc
public enum ActivityRanks: Int16, Identifiable {
    public var id: UUID {
        switch self {
        case .none:
            return UUID()
        case .bad:
            return UUID()
        case .ok:
            return UUID()
        case .good:
            return UUID()
        }
    }

    case none
    case bad
    case ok
    case good
}
