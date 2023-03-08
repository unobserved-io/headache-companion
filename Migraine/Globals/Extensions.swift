//
//  Extensions.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/4/23.
//

import Foundation
import SwiftUI

extension Binding {
     func toUnwrapped<T>(defaultValue: T) -> Binding<T> where Value == Optional<T>  {
        Binding<T>(get: { self.wrappedValue ?? defaultValue }, set: { self.wrappedValue = $0 })
    }
}

extension PresentationDetent {
    static let bar = Self.fraction(0.2)
}
