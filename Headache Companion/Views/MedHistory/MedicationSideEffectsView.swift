//
//  MedicationSymptomsView.swift
//  Headache Companion
//
//  Created by Ricky Kresslein on 4/5/23.
//

import SwiftUI

struct MedicationSideEffectsView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var sideEffects: Set<String>
    
    @State var showingAdd: Bool = false
    @State var newSideEffect: String = ""

    var body: some View {
        List {
            Section {
                Button("Add a side effect") {
                    showingAdd.toggle()
                }
                .alert("New Side Effect", isPresented: $showingAdd, actions: {
                    TextField("", text: $newSideEffect)
                        .labelsHidden()
                    
                    Button("Add") {
                        if !newSideEffect.isEmpty {
                            sideEffects.insert(newSideEffect)
                            newSideEffect = ""
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                })
            }
            .listRowBackground(colorScheme == .light ? Color.gray.opacity(0.10) : Color.white.opacity(0.10))
            
            Section {
                ForEach(sideEffects.sorted { $0 < $1 }, id: \.self) { sideEffect in
                    Text(sideEffect)
                }
                .onDelete(perform: deleteSideEffect)
            }
            .listRowBackground(colorScheme == .light ? Color.gray.opacity(0.10) : Color.white.opacity(0.10))
        }
    }
    
    private func deleteSideEffect(at offsets: IndexSet) {
        let index = offsets.first
        if index != nil {
            let sideEffectsSorted = sideEffects.sorted { $0 < $1 }
            let stringToDelete = sideEffectsSorted[index!]
            sideEffects.remove(stringToDelete)
            saveData()
        }
    }
}

struct MedicationSideEffectsView_Previews: PreviewProvider {
    static var previews: some View {
        MedicationSideEffectsView(sideEffects: .constant(["too", "you"]))
    }
}
