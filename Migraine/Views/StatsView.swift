//
//  StatsView.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/11/23.
//

import SwiftUI

struct StatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: DayData.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \DayData.date, ascending: true)]
    )
    var dayData: FetchedResults<DayData>
    private enum DateRange {
        case week
        case thirtyDays
        case sixMonths
        case year
        case allTime
        case custom
    }

    @ObservedObject var statsHelper = StatsHelper.sharedInstance
    @State private var dateRange: DateRange = .week

    var body: some View {
        VStack {
            GroupBox {
                Grid(alignment: .leading, verticalSpacing: 5) {
                    GridRow {
                        mainStat(String(statsHelper.daysTracked))
                        statDescription("Days tracked")
                    }
                    GridRow {
                        mainStat(String(statsHelper.daysWithAttack))
                        statDescription("Days with an attack")
                    }
                    GridRow {
                        mainStat(String(statsHelper.numberOfAttacks))
                        statDescriptionChevron("Attacks")
                    }
                    //TODO: Only show all others if attacks > 0
                    if statsHelper.daysWithAttack > 0 {
                        GridRow {
                            mainStat("\(statsHelper.percentWithAttack) %")
                            statDescription("Of days had an attack")
                        }
                        
                        GridRow {
                            mainStat(String(statsHelper.numberOfSymptoms))
                            statDescriptionChevron("Symptoms")
                        }
                        
                        GridRow {
                            mainStat(String(statsHelper.numberOfTypesOfHeadaches))
                            statDescriptionChevron("Types of headache")
                        }
                        
                        GridRow {
                            mainStat(String(statsHelper.averagePainLevel))
                            statDescription("Average pain level")
                        }
                        
                        GridRow {
                            mainStat(String(statsHelper.numberOfAuras))
                            statDescriptionChevron("Auras")
                        }
                        // TODO: Under Auras will be number broken down by type
                        
//                        GridRow {
//                            Image(systemName: "sunrise")
//                                .font(.title2)
//                                .foregroundColor(.accentColor)
//                                .bold()
//                                .padding(.trailing)
//                            Text("Most common time of day")
//                                .font(.title3)
//                        }
                        // TODO: Add most common type of headache
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
//                mainStat(String(statsHelper.mostCommonTypeOfHeadache))
//                statDescription("Most common type")
                
            } label: {
                HStack {
                    Spacer()
                    Text("In the last")
                    Picker("", selection: $dateRange) {
                        Text("Week").tag(DateRange.week)
                        Text("30 days").tag(DateRange.thirtyDays)
                        Text("6 months").tag(DateRange.sixMonths)
                        Text("Year").tag(DateRange.year)
                        Text("All time").tag(DateRange.allTime)
                        Text("Date Range").tag(DateRange.custom)
                    }
                    .onChange(of: dateRange) { range in
                        statsHelper.getStats(from: dayDataInRange(range))
                    }
                    Spacer()
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear() {
            statsHelper.getStats(from: dayDataInRange(dateRange))
        }
    }
    
    private func mainStat(_ stat: String) -> some View {
        return Text(stat)
            .font(.title2)
            .foregroundColor(.accentColor)
            .bold()
            .padding(.trailing)
    }
    
    private func statDescription(_ description: String) -> some View {
        return Text(description)
                .font(.title3)
    }
    
    private func statDescriptionChevron(_ description: String) -> some View {
        return HStack {
            Text(description)
                .font(.title3)
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
        }
        .containerShape(Rectangle())
        .onTapGesture {
            print("tapped")
        }
    }
    
    private func dayDataInRange(_ range: DateRange) -> [DayData] {
        var inRange: [DayData] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var fromDate: Date = Calendar.current.startOfDay(for: Date.now)
        let today: Date = .now
        
        switch range {
        case .week:
            fromDate = Calendar.current.date(byAdding: .day, value: -7, to: fromDate) ?? Date.now
        case .thirtyDays:
            fromDate = Calendar.current.date(byAdding: .day, value: -30, to: fromDate) ?? Date.now
        case .sixMonths:
            fromDate = Calendar.current.date(byAdding: .day, value: -180, to: fromDate) ?? Date.now
        case .year:
            fromDate = Calendar.current.date(byAdding: .day, value: -365, to: fromDate) ?? Date.now
        case .allTime:
            fromDate = Date.init(timeIntervalSince1970: 0)
        case .custom:
            // TODO: use custom dats
            break
        }
        
        for day in dayData {
            let dayDate = dateFormatter.date(from: day.date ?? "1970-01-01")
            
            if dayDate?.isBetween(fromDate, and: today) ?? false {
                inRange.append(day)
            }
        }
        
        return inRange
    }

}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
    }
}
