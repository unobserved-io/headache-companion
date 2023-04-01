//
//  MedicationLabelView.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/10/23.
//

import SwiftUI

struct MedicationLabelView: View {
    @State var medication: Medication
    @State var refresh: Bool = false
        
    var body: some View {
        HStack {
            // Amount number
            Text("\(refresh ? "" : "")\(medication.amount)")
                .font(Font.system(.title).monospacedDigit())
                .padding(.trailing)
                
            // Med details
            VStack(alignment: .leading) {
                HStack {
                    Text("\(medication.name ?? "Unknown")")
                        .bold()
                    medication.dose?.isEmpty ?? true ? nil : Text("(\(medication.dose ?? ""))")
                }
                if medication.effective {
                    Text("Effective")
                        .font(.footnote)
                } else {
                    Text("Ineffective")
                        .font(.footnote)
                }
            }
                
            Spacer()
                
            // Time taken
            Text("\(medication.wrappedTime.formatted(date: .omitted, time: .shortened))")
        }
    }
}

struct MedicationLabelView_Previews: PreviewProvider {
    static var previews: some View {
        let viewContext = PersistenceController.shared.container.viewContext
        MedicationLabelView(medication: Medication(context: viewContext))
    }
}
