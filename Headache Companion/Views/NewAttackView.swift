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
        if selectedDayIsToday() {
            attack.startTime = Date.now
        } else {
            attack.startTime = Calendar.current.date(bySettingHour: 8, minute: 00, second: 00, of: inputDate)
            attack.stopTime = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: inputDate)
        }
        return attack
    }
    
    private func selectedDayIsToday() -> Bool {
        let selectedDate = Calendar.current.dateComponents([.year, .month, .day], from: inputDate)
        let todayDate = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        return selectedDate == todayDate
    }
}

struct NewAttackView_Previews: PreviewProvider {
    static var previews: some View {
        NewAttackView(for: .now)
    }
}
