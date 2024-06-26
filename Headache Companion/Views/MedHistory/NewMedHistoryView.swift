//
//  NewMedHistoryView.swift
//  Headache Companion
//
//  Created by Ricky Kresslein on 4/5/23.
//

import SwiftUI

struct NewMedHistoryView: View {
    /// This is necessary to stop MedicationHistoryView's NavigationStack from creating a new MedHistory anytime the View reloads
    @Environment(\.managedObjectContext) private var viewContext
    @State var firstRun = true

    var body: some View {
        if firstRun {
            AddEditMedHistoryView(medHistory: createMedHistory())
        }
    }

    private func createMedHistory() -> MedHistory {
        let medHistory = MedHistory(context: viewContext)
        medHistory.startDate = Calendar.current.startOfDay(for: .now)
        return medHistory
    }
}

struct NewMedHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NewMedHistoryView()
    }
}
