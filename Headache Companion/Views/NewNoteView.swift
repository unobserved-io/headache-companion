//
//  NewNoteView.swift
//  Headache Companion
//
//  Created by Ricky Kresslein on 4/1/23.
//

import SwiftUI

struct NewNoteView: View {
    /// This is necessary to stop CalendarView's NavigationStack from creating a new Note anytime the View reloads
    @Environment(\.managedObjectContext) private var viewContext
    var inputDate: Date

    var body: some View {
        NotesView(dayData: getDayData())
    }

    private func getDayData() -> DayData {
        let dateString = dateFormatter.string(from: inputDate)

        let newDay = DayData(context: viewContext)
        newDay.date = dateString
        return newDay
    }
}

struct NewNoteView_Previews: PreviewProvider {
    static var previews: some View {
        NewNoteView(inputDate: .now)
    }
}
