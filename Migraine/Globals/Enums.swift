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
    case cluster
    case exertional
    case hypnic
    case sinus
    case caffeine
    case injury
    case menstrual
    case other
}

@objc
public enum MedTypes: Int16 {
    case other
    case preventive
    case symptomRelieving
}
