//
//  MultiSelectionView.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/5/23.
//

import SwiftUI

struct MultiSelectionView: View {
    let options: [String]

    @Binding var selected: Set<String>

    var body: some View {
        List {
            ForEach(options, id: \.self) { selectable in
                Button(action: { toggleSelection(selectable: selectable) }) {
                    HStack {
                        Text(selectable).foregroundColor(.black)
                        Spacer()
                        if selected.contains(selectable) {
                            Image(systemName: "checkmark").foregroundColor(.accentColor)
                        }
                    }
                }
            }
        }.listStyle(GroupedListStyle())
    }

    private func toggleSelection(selectable: String) {
        if let existingIndex = selected.firstIndex(of: selectable) {
            selected.remove(at: existingIndex)
        } else {
            selected.insert(selectable)
        }
    }
}

struct MultiSelectionView_Previews: PreviewProvider {
//    struct IdentifiableString: Identifiable, Hashable {
//        let string: String
//        var id: String { string }
//    }

    @State static var selected: Set<String> = Set(["A", "C"].map { $0 })

    static var previews: some View {
        NavigationView {
            MultiSelectionView(
                options: ["A", "B", "C", "D"],
                selected: $selected
            )
        }
    }
}
