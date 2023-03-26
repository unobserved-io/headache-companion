//
//  DoctorNotesView.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/6/23.
//

import SwiftUI

struct DoctorNotesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: MAppData.entity(),
        sortDescriptors: []
    )
    var mAppData: FetchedResults<MAppData>
    @FocusState private var isNoteFocused: Bool
    
    private var noteBinding: Binding<String> {
        Binding {
            mAppData.first?.doctorNotes ?? .init("")
        } set: {
            mAppData.first?.doctorNotes = $0
        }
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: noteBinding)
                .focused($isNoteFocused)
            if !isNoteFocused && mAppData.first?.doctorNotes?.isEmpty ?? true {
                Text("Type notes for your doctor...")
                    .foregroundColor(Color(uiColor: .placeholderText))
                    .padding(.top, 10)
                    .padding(.leading, 5)
                    .allowsHitTesting(false)
            }
        }
        .padding()
        .onDisappear() {
            saveData()
        }
    }
}

struct DoctorNotesView_Previews: PreviewProvider {
    static var previews: some View {
        let viewContext = PersistenceController.shared.container.viewContext
        DoctorNotesView().environment(\.managedObjectContext, viewContext)
    }
}
