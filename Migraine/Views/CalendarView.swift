//
//  CalendarView.swift
//  Migraine
//
//  Created by Ricky Kresslein on 2/28/23.
//

import SwiftUI

struct CalendarView: View {
    @FetchRequest(
        entity: DayData.entity(),
        sortDescriptors: []
    )
    var dayData: FetchedResults<DayData>
    @State private var selectedDay: Date = .now
    @State private var refreshIt: Bool = false
    @State private var attackSheet: Bool = false
    @StateObject var clickedAttack = ClickedAttack(nil)
    
    var body: some View {
//        NavigationView {
            Form {
                Section {
                    DatePicker(
                        "Attacks",
                        selection: $selectedDay,
                        in: Date(timeIntervalSince1970: 0) ... Date.now,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                }
                
                Section("Attacks") {
                    ForEach(getDayData()?.attacks ?? []) { attack in
                        Button {
                            clickedAttack.attack = attack
                            attackSheet.toggle()
                        } label: {
                            if attack.stopTime != nil {
                                Text("\(refreshIt ? "" : "")\(attack.wrappedStartTime.formatted(date: .omitted, time: .shortened)) - \(attack.wrappedStopTime.formatted(date: .omitted, time: .shortened))")
                            } else {
                                Text(attack.wrappedStartTime.formatted(date: .omitted, time: .shortened))
                            }
                        }
                        .tint(.primary)
                        
//                        NavigationLink (destination: AttackView().environmentObject(clickedAttack)) {
//                            if attack.stopTime != nil {
//                                Text("\(refreshIt ? "" : "")\(attack.wrappedStartTime.formatted(date: .omitted, time: .shortened)) - \(attack.wrappedStopTime.formatted(date: .omitted, time: .shortened))")
//                            } else {
//                                Text(attack.wrappedStartTime.formatted(date: .omitted, time: .shortened))
//                            }
//                        }
                        
                    }
                    
                    if getDayData()?.attacks.isEmpty ?? true {
                        Text("No attacks")
                    }
                }
            }
//        }
        .onAppear {
            refreshIt.toggle()
        }
        .sheet(isPresented: $attackSheet) {
            NavigationView {
                AttackView()
                    .environmentObject(clickedAttack)
            }
        }
    }
    
    private func getDayData() -> DayData? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let selectedDayFormatted = dateFormatter.string(from: selectedDay)
        return dayData.filter { $0.date == selectedDayFormatted }.first
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
