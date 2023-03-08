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
//    @State private var clickedIndex: Int? = nil
    @StateObject var clickedAttack = ClickedAttack(nil)
    
    var body: some View {
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
//                        clickedIndex = getDayData()?.attacks.firstIndex(of: attack) ?? nil
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
                }
                
                if getDayData()?.attacks.isEmpty ?? true {
                    Text("No attacks")
                }
            }
        }
        .onAppear {
            refreshIt.toggle()
        }
        .sheet(isPresented: $attackSheet) {
            AttackView()
                .environmentObject(clickedAttack)
        }
    }
    
    private func getDayData() -> DayData? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let selectedDayFormatted = dateFormatter.string(from: selectedDay)
        return dayData.filter { $0.date == selectedDayFormatted }.first
    }
    
//    private func indexToNil() {
//        clickedIndex = nil
//    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
