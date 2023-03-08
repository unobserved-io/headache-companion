//
//  ClickedAttack.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/8/23.
//

import Foundation

class ClickedAttack: ObservableObject {
    @Published var attack: Attack?

    init(_ attack: Attack?) {
        self.attack = attack
    }
}
