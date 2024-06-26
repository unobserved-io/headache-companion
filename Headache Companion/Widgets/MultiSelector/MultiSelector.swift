//
//  MultiSelector.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/5/23.
//

import CoreData
import SwiftUI

struct MultiSelector: View {
    let label: String
    let options: [String]

    var selected: Binding<Set<String>>

    private var formattedSelectedListString: String {
        ListFormatter.localizedString(byJoining: selected.wrappedValue.sorted { $0 < $1 }.map {
            String(localized: String.LocalizationValue($0))
        })
    }

    var body: some View {
        NavigationLink(destination: multiSelectionView().navigationTitle("Add \(label)")) {
            HStack {
                Text(label)
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
            options: options.sorted { String(localized: String.LocalizationValue($0)) < String(localized: String.LocalizationValue($1)) },
            selected: selected
        )
    }
}

struct MultiSelector_Previews: PreviewProvider {
    @State static var selected: Set<String> = Set(["A", "C"].map { $0 })

    static var previews: some View {
        MultiSelector(
            label: "MultiSelector",
            options: ["Red", "White", "Blue"],
            selected: $selected
        )
    }
}
