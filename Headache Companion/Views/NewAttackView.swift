//
//  NewAttackView.swift
//  Headache Companion
//
//  Created by Ricky Kresslein on 3/28/23.
//

import SwiftUI

struct NewAttackView: View {
    /// This is necessary to stop ContentView's NavigationStack from creating a new Attack anytime the View reloads
    @Environment(\.managedObjectContext) private var viewContext
    var inputDate: Date
    
    init(for inputDate: Date) {
        self.inputDate = inputDate
    }
    
    var body: some View {
        AttackView(attack: createNewAttack(), for: inputDate)
    }
    
    private func createNewAttack() -> Attack {
        let attack = Attack(context: viewContext)
        attack.id = UUID().uuidString
        attack.startTime = Date.now
        return attack
    }
}

struct NewAttackView_Previews: PreviewProvider {
    static var previews: some View {
        NewAttackView(for: .now)
    }
}
