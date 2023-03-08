//
//  MultiSelector.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/5/23.
//

import SwiftUI
import CoreData

struct MultiSelector<LabelView: View>: View {
    let label: LabelView
    let options: [String]
    
    var selected: Binding<Set<String>>

    private var formattedSelectedListString: String {
        ListFormatter.localizedString(byJoining: selected.wrappedValue.map { $0 as String })
    }

    var body: some View {
        NavigationLink(destination: multiSelectionView()) {
            HStack {
                label
                Spacer()
                if formattedSelectedListString.isEmpty {
                    Text("None")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.trailing)
                } else {
                    Text(formattedSelectedListString)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
    }

    private func multiSelectionView() -> some View {
        MultiSelectionView(
            options: options,
            selected: selected
        )
    }
}

struct MultiSelector_Previews: PreviewProvider {
    @State static var selected: Set<String> = Set(["A", "C"].map { $0 })
    
    static var previews: some View {
        MultiSelector(
            label: Text("MultiSelector"),
            options: ["Red", "White", "Blue"],
            selected: $selected
        )
    }
}
