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
public enum Effectiveness: Int16 {
    case ineffective
    case effective
    case none
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
