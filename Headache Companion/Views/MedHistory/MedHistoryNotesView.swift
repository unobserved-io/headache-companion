//
//  MedHistoryNotesView.swift
//  Headache Companion
//
//  Created by Ricky Kresslein on 4/6/23.
//

import SwiftUI

struct MedHistoryNotesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var note: String
    @FocusState private var isNoteFocused: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $note)
                .focused($isNoteFocused)
            if !isNoteFocused && note.isEmpty {
                Text("Type your notes...")
                    .foregroundColor(.gray)
                    .padding(.top, 10)
                    .padding(.leading, 5)
                    .allowsHitTesting(false)
            }
        }
        .padding()
    }
}

struct MedHistoryNotesView_Previews: PreviewProvider {
    static var previews: some View {
        MedHistoryNotesView(note: .constant(""))
    }
}

