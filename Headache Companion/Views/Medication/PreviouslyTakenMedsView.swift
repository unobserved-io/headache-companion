//
//  PreviouslyTakenMedsView.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/11/23.
//

import SwiftUI

struct PreviouslyTakenMedsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss // TODO: From iOS 15+. Test on iOS 14
    @FetchRequest(
        entity: DayData.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \DayData.date, ascending: false)]
    )
    var dayData: FetchedResults<DayData>
    
    var body: some View {
        List {
            ForEach(getUniqueMeds()) { uniqueMed in
                Button {
                    let newMedication = Medication(context: viewContext)
                    newMedication.id = UUID().uuidString
                    newMedication.name = uniqueMed.name
                    newMedication.dose = uniqueMed.dose
                    newMedication.amount = uniqueMed.amount
                    newMedication.type = uniqueMed.type
                    newMedication.effective = .none
                    newMedication.time = Date.now
                    dayData.first?.addToMedication(newMedication)
                    saveData()
                    dismiss()
                } label: {
                    HStack {
                        // Amount number
                        Text("\(uniqueMed.amount)")
                            .font(Font.system(.title).monospacedDigit())
                            .padding(.trailing)
                            
                        // Med details
                        HStack {
                            Text("\(uniqueMed.name ?? "Unknown")")
                                .bold()
                            Text("(\(uniqueMed.dose ?? ""))")
                        }
                        
                        Spacer()
                        
                        Image(systemName: "plus.circle")
                            .foregroundColor(.accentColor)
                    }
                }
                .tint(.primary)
            }
        }
    }
    
    private func getUniqueMeds() -> [Medication] {
        var uniqueMeds: [Medication] = []
        for day in dayData {
            for medication in day.medications {
                if uniqueMeds.isEmpty {
                    uniqueMeds.append(medication)
                } else if !uniqueMeds.contains(where: { $0.name == medication.name && $0.dose == medication.dose && $0.amount == medication.amount}) {
                    uniqueMeds.append(medication)
                }
            }
        }
        
        return uniqueMeds
    }
}

struct PreviouslyTakenMedsView_Previews: PreviewProvider {
    static var previews: some View {
        PreviouslyTakenMedsView()
    }
}
