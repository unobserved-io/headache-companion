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
    private let dateFormatter: DateFormatter = {
        let dateformat = DateFormatter()
        dateformat.dateFormat = "yyyy-MM-dd"
        return dateformat
    }()
//    private var activityItems: [GridItem] {
//        Array(repeating: .init(.flexible(minimum: 20)), count: 999)
//    }
    private var activityItems = [GridItem(.flexible(minimum: 20, maximum: 20))]

    @ObservedObject var statsHelper = StatsHelper.sharedInstance
    @State private var dateRange: DateRange = .week
    @State private var clickedAttacks: Bool = false

    var body: some View {
        VStack {
            GroupBox {
                Grid(alignment: .leading, verticalSpacing: 5) {
                    GridRow(alignment: .top) {
                        mainStat(String(statsHelper.daysTracked))
                        statDescription("Days tracked")
                    }
                    GridRow(alignment: .top) {
                        mainStat(String(statsHelper.daysWithAttack))
                        statDescription("Days with an attack")
                    }
                    GridRow(alignment: .top) {
                        mainStat(String(statsHelper.numberOfAttacks))
                        statDescriptionChevron("Attacks")
                    }
                    //TODO: Only show all others if attacks > 0
                    if statsHelper.daysWithAttack > 0 {
                        GridRow(alignment: .top) {
                            mainStat("\(statsHelper.percentWithAttack) %")
                            statDescription("Of days had an attack")
                        }
                        
                        GridRow(alignment: .top) {
                            mainStat(String(statsHelper.numberOfSymptoms))
                            statDescriptionChevron("Symptoms")
                        }
                        
                        GridRow(alignment: .top) {
                            mainStat(String(statsHelper.numberOfTypesOfHeadaches))
                            statDescriptionChevron("Types of headache")
                        }
                        
                        GridRow(alignment: .top) {
                            mainStat(String(statsHelper.averagePainLevel))
                            statDescription("Average pain level")
                        }
                        
                        GridRow(alignment: .top) {
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
                .padding(.bottom)
                
//                mainStat(String(statsHelper.mostCommonTypeOfHeadache))
//                statDescription("Most common type")
                
                VStack(spacing: 10) {
                    Text("Water")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if dateRange == .week || dateRange == .thirtyDays {
                        noScrollActivity(statsHelper.waterInSelectedDays)
                    } else {
                        scrollActivity(statsHelper.waterInSelectedDays)
                    }
                    
                    Text("Diet")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if dateRange == .week || dateRange == .thirtyDays {
                        noScrollActivity(statsHelper.dietInSelectedDays)
                    } else {
                        scrollActivity(statsHelper.dietInSelectedDays)
                    }
                    
                    Text("Exercise")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if dateRange == .week || dateRange == .thirtyDays {
                        noScrollActivity(statsHelper.exerciseInSelectedDays)
                    } else {
                        scrollActivity(statsHelper.exerciseInSelectedDays)
                    }
                    
                    Text("Relax")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if dateRange == .week || dateRange == .thirtyDays {
                        noScrollActivity(statsHelper.relaxInSelectedDays)
                    } else {
                        scrollActivity(statsHelper.relaxInSelectedDays)
                    }
                    
                    Text("Sleep")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if dateRange == .week || dateRange == .thirtyDays {
                        noScrollActivity(statsHelper.sleepInSelectedDays)
                    } else {
                        scrollActivity(statsHelper.sleepInSelectedDays)
                    }
                }
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
                        statsHelper.getStats(from: dayDataInRange(range), startDate: getFromDate(range))
                        
                    }
                    Spacer()
                }
            }
            
            HStack {
                mainStat(String(dayData.count))
                statDescription("Days with recorded data") // TODO: Change app name
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading)
            
            HStack {
                mainStat(String((Calendar.current.dateComponents([.day], from: dateFormatter.date(from: dayData.first?.date ?? dateFormatter.string(from: Date.now)) ?? Date.now, to: Calendar.current.startOfDay(for: Date.now)).day ?? 0) + 1))
                statDescription("Days using Migraine") // TODO: Change app name
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading)
            
            Spacer()
        }
        .padding()
        .onAppear() {
            statsHelper.getStats(from: dayDataInRange(dateRange), startDate: getFromDate(dateRange))
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
        var clicked = false
        return VStack {
            HStack {
                Text(description)
                    .font(.title3)
                Image(systemName: clicked ? "chevron.down" : "chevron.right")
                    .font(.system(size: 12))
            }
            if clicked {
                ForEach(Array(statsHelper.allSymptoms), id: \.self) { symptom in
                    Text(symptom)
                }
            }
        }
        .containerShape(Rectangle())
        .onTapGesture {
            print("tapped")
            clicked = true
        }
    }
    
    private func dayDataInRange(_ range: DateRange) -> [DayData] {
        var inRange: [DayData] = []
        let today: Date = .now
        
        let fromDate = getFromDate(range)
        
        for day in dayData {
            let dayDate = dateFormatter.date(from: day.date ?? "1970-01-01")
            
            if dayDate?.isBetween(fromDate, and: today) ?? false {
                inRange.append(day)
            }
        }
        
        return inRange
    }
    
    private func getFromDate(_ range: DateRange) -> Date {
        var fromDate: Date = Calendar.current.startOfDay(for: Date.now)
        
        switch range {
        case .week:
            fromDate = Calendar.current.date(byAdding: .day, value: -6, to: fromDate) ?? Date.now
        case .thirtyDays:
            fromDate = Calendar.current.date(byAdding: .day, value: -29, to: fromDate) ?? Date.now
        case .sixMonths:
            fromDate = Calendar.current.date(byAdding: .day, value: -179, to: fromDate) ?? Date.now
        case .year:
            fromDate = Calendar.current.date(byAdding: .day, value: -364, to: fromDate) ?? Date.now
        case .allTime:
            fromDate = Date.init(timeIntervalSince1970: 0)
        case .custom:
            // TODO: use custom dates
            break
        }
        
        return fromDate
    }
    
    private func noScrollActivity(_ activityRanks: [ActivityRanks]) -> some View {
        HStack(spacing: 1) {
            ForEach(activityRanks) { activity in
                Rectangle()
                    .fill(activityColor(of: activity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
    }
    
    private func scrollActivity(_ activityRanks: [ActivityRanks]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 1) {
                ForEach(activityRanks) { activity in
                    Rectangle()
                        .fill(activityColor(of: activity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 15, alignment: .leading)
        }
    }

}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
    }
}
