//
//  NotesView.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/6/23.
//

import SwiftUI

struct NotesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var dayData: DayData
    @FocusState private var isNoteFocused: Bool

    init(dayData: DayData) {
        self.dayData = dayData
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $dayData.notes)
                .focused($isNoteFocused)
            if !isNoteFocused && dayData.notes.isEmpty {
                Text("Type your notes...")
                    .foregroundColor(.gray)
                    .padding(.top, 10)
                    .padding(.leading, 5)
                    .allowsHitTesting(false)
            }
        }
        .padding()
        .onDisappear {
            saveData()
        }
    }
}

struct NotesView_Previews: PreviewProvider {
    static var previews: some View {
        let viewContext = PersistenceController.shared.container.viewContext
        NotesView(dayData: DayData(context: viewContext)).environment(\.managedObjectContext, viewContext)
    }
}
