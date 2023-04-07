//
//  StatsView.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/11/23.
//

import SwiftUI

struct StatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme
    @FetchRequest(
        entity: DayData.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \DayData.date, ascending: true)]
    )
    var dayData: FetchedResults<DayData>
    @FetchRequest(
        entity: MAppData.entity(),
        sortDescriptors: []
    )
    var mAppData: FetchedResults<MAppData>
    private enum DateRange {
        case week
        case thirtyDays
        case sixMonths
        case year
        case allTime
        case custom
    }
    private enum ChosenActivity: String {
        case water
        case diet
        case exercise
        case relax
        case sleep
    }

    @ObservedObject var statsHelper = StatsHelper.sharedInstance
    @State private var dateRange: DateRange = .allTime
    @State private var selectedStart: Date =  Date.now
    @State private var selectedStop: Date = Date.now
    @State private var clickedAttacks: Bool = false
    @State private var clickedSymptoms: Bool = false
    @State private var clickedAuras: Bool = false
    @State private var clickedMedNames: Bool = false
    @State private var chosenActivity: ChosenActivity = .water

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                        Picker("", selection: $dateRange) {
                            dayData.count > 6 ? Text("Past week").tag(DateRange.week) : nil
                            dayData.count > 15 ? Text("Past 30 days").tag(DateRange.thirtyDays) : nil
                            dayData.count > 90 ? Text("Past 6 months").tag(DateRange.sixMonths) : nil
                            dayData.count > 200 ? Text("Past year").tag(DateRange.year) : nil
                            Text("All time").tag(DateRange.allTime)
                            Text("Date Range").tag(DateRange.custom)
                        }
                        .onChange(of: dateRange) { range in
                            statsHelper.getStats(from: dayDataInRange(range), startDate: getFromDate(range), stopDate: getStopDate(range))
                        }
                    if dateRange == .custom {
                        HStack {
                            // TODO: Replace with DatePicker when bug showing short date format is fixed
                            DatePicker(
                                selection: $selectedStart,
                                in: Date(timeIntervalSinceReferenceDate: 0) ... selectedStop,
                                displayedComponents: [.date],
                                label: {}
                            )
                            .labelsHidden()
                            .onChange(of: selectedStart) { range in
                                statsHelper.getStats(from: dayDataInRange(dateRange), startDate: getFromDate(dateRange), stopDate: getStopDate(dateRange))
                            }
                            Text("to")
                            DatePicker(
                                selection: $selectedStop,
                                in: selectedStart ... Date.now,
                                displayedComponents: [.date],
                                label: {}
                            )
                            .frame(minHeight: 35)
                            .labelsHidden()
                            .onChange(of: selectedStop) { range in
                                statsHelper.getStats(from: dayDataInRange(dateRange), startDate: getFromDate(dateRange), stopDate: getStopDate(dateRange))
                            }
                        }
                        .padding(.bottom)
                    }
                    Grid(alignment: .leading, verticalSpacing: 5) {
                        GridRow(alignment: .top) {
                            mainStat(String(statsHelper.daysTracked))
                            statDescription("\(statsHelper.daysTracked == 1 ? "day" : "days") tracked")
                        }
                        GridRow(alignment: .top) {
                            mainStat(String(statsHelper.daysWithAttack))
                            statDescription("\(statsHelper.daysWithAttack == 1 ? "day" : "days") with an attack")
                        }
                        GridRow(alignment: .top) {
                            mainStat(String(statsHelper.numberOfAttacks))
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("\(statsHelper.numberOfAttacks == 1 ? "attack" : "attacks")")
                                        .font(.title3)
                                    Image(systemName: clickedAttacks ? "chevron.down" : "chevron.right")
                                        .font(.system(size: 12))
                                }
                                if clickedAttacks {
                                    Grid(alignment: .leading, verticalSpacing: 5) {
                                        ForEach(statsHelper.allTypesOfHeadache, id: \.key) { type, num in
                                            GridRow {
                                                Text(String(num))
                                                    .foregroundColor(.accentColor)
                                                    .bold()
                                                    .padding(.trailing)
                                                Text(type)
                                            }
                                        }
                                    }
                                    .padding(.leading)
                                }
                            }
                            .containerShape(Rectangle())
                            .onTapGesture {
                                clickedAttacks.toggle()
                            }
                        }
                        //TODO: Only show all others if attacks > 0
                        if statsHelper.daysWithAttack > 0 {
                            GridRow(alignment: .top) {
                                mainStat("\(statsHelper.percentWithAttack)%")
                                statDescription("of days had an attack")
                            }
                            
                            GridRow(alignment: .top) {
                                mainStat(String(statsHelper.allSymptoms.count))
                                statDescriptionChevron(for: "\(statsHelper.allSymptoms.count == 1 ? "symptom" : "symptoms")", clicked: clickedSymptoms, list: statsHelper.allSymptoms)
                            }
                            
                            GridRow(alignment: .top) {
                                mainStat(String(format: "%.1f", statsHelper.averagePainLevel))
                                statDescription("average pain level")
                            }
                            
                            GridRow(alignment: .top) {
                                mainStat(String(statsHelper.allAuras.count))
                                statDescriptionChevron(for: "\(statsHelper.allAuras.count == 1 ? "aura" : "auras")", clicked: clickedAuras, list: statsHelper.allAuras)
                            }
                            
                            GridRow(alignment: .top) {
                                mainStat(String(statsHelper.allMedicationNames.count))
                                statDescriptionChevron(for: "\(statsHelper.allMedicationNames.count == 1 ? "type" : "types") of medication taken", clicked: clickedMedNames, list: statsHelper.allMedicationNames)
                            }
                            
                            GridRow(alignment: .top) {
                                mainStat("\(statsHelper.percentWithMedication)%")
                                statDescription("of days you took medication")
                            }
                            
                            //                        GridRow {
                            //                            Image(systemName: "sunrise")
                            //                                .font(.title2)
                            //                                .foregroundColor(.accentColor)
                            //                                .bold()
                            //                                .padding(.trailing)
                            //                            Text("most common time of day")
                            //                                .font(.title3)
                            //                        }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom)
                    
                    // MARK: Activities Stats
                    VStack {
                        Picker("Activity", selection: $chosenActivity) {
                            Image(systemName: "drop.fill").tag(ChosenActivity.water)
                            Image(systemName: "carrot.fill").tag(ChosenActivity.diet)
                            Image(systemName: "bed.double.fill").tag(ChosenActivity.sleep)
                            Image(systemName: "figure.strengthtraining.functional").tag(ChosenActivity.exercise)
                            Image(systemName: "figure.mind.and.body").tag(ChosenActivity.relax)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        switch chosenActivity {
                        case .water:
                            PieChart(values: statsHelper.waterInSelectedDays, colors: [activityColor(of: .none), activityColor(of: .bad), activityColor(of: .ok), activityColor(of: .good)], icon: "drop.fill")
                        case .diet:
                            PieChart(values: statsHelper.dietInSelectedDays, colors: [activityColor(of: .none), activityColor(of: .bad), activityColor(of: .ok), activityColor(of: .good)], icon: "carrot.fill")
                        case .exercise:
                            PieChart(values: statsHelper.exerciseInSelectedDays, colors: [activityColor(of: .none), activityColor(of: .bad), activityColor(of: .ok), activityColor(of: .good)], icon: "figure.strengthtraining.functional")
                        case .relax:
                            PieChart(values: statsHelper.relaxInSelectedDays, colors: [activityColor(of: .none), activityColor(of: .bad), activityColor(of: .ok), activityColor(of: .good)], icon: "figure.mind.and.body")
                        case .sleep:
                            PieChart(values: statsHelper.sleepInSelectedDays, colors: [activityColor(of: .none), activityColor(of: .bad), activityColor(of: .ok), activityColor(of: .good)], icon: "bed.double.fill")
                        }
                    }
                    
                }
                .padding()
                .addBorder(Color.accentColor, width: 4, cornerRadius: 15)
                .padding(.bottom)
                
                // MARK: Medication History button
                NavigationLink(
                    "Medication History",
                    destination: MedicationHistoryView()
                        .navigationTitle("Medication History")
                )
                .buttonStyle(.bordered)
                .tint(.accentColor)
                .font(.title2)
                
                Grid(alignment: .leading, verticalSpacing: 5) {
                    GridRow(alignment: .top) {
                        mainStat(String(dayData.count))
                        statDescription("\(dayData.count == 1 ? "day" : "days") with recorded data")
                    }
                    
                    GridRow(alignment: .top) {
                        mainStat(String((Calendar.current.dateComponents([.day], from: mAppData.first?.launchDay ?? .now, to: Calendar.current.startOfDay(for: Date.now)).day ?? 0) + 1))
                        statDescription("\((Calendar.current.dateComponents([.day], from: mAppData.first?.launchDay ?? .now, to: Calendar.current.startOfDay(for: Date.now)).day ?? 0) + 1 == 1 ? "day" : "days") using Headache Companion")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
        }
        .scrollContentBackground(.hidden)
        .padding(.horizontal)
        .padding(.top)
        .onAppear() {
            statsHelper.getStats(from: dayDataInRange(dateRange), startDate: getFromDate(dateRange), stopDate: getStopDate(dateRange))
        }
    }
    
    private func mainStat(_ stat: String) -> some View {
        return Text(stat)
            .font(.title2)
            .foregroundColor(.accentColor)
            .bold()
    }
    
    private func statDescription(_ description: String) -> some View {
        return Text(description)
                .font(.title3)
    }
    
    private func statDescriptionChevron(for description: String, clicked: Bool, list: Set<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(description)
                    .font(.title3)
                Image(systemName: clicked ? "chevron.down" : "chevron.right")
                    .font(.system(size: 12))
            }
            if clicked {
                ForEach(Array(list).sorted { $0 < $1 }, id: \.self) { listItem in
                    Text(listItem)
                        .padding(.leading)
                }
            }
        }
        .containerShape(Rectangle())
        .onTapGesture {
            switch description {
            case let str where str.contains("symptom"):
                clickedSymptoms.toggle()
            case let str where str.contains("aura"):
                clickedAuras.toggle()
            case let str where str.contains("type"):
                clickedMedNames.toggle()
            default:
                break
            }
        }
    }
    
    private func dayDataInRange(_ range: DateRange) -> [DayData] {
        var inRange: [DayData] = []
        let stopDate: Date = getStopDate(range)
        let fromDate: Date = getFromDate(range)
        
        dayData.forEach { day in
            let dayDate = dateFormatter.date(from: day.date ?? "1970-01-01")
            
            if dayDate?.isBetween(fromDate, and: stopDate) ?? false {
                inRange.append(day)
            }
        }
        
        return inRange
    }
    
    private func getFromDate(_ range: DateRange) -> Date {
        let fromDate: Date = Calendar.current.startOfDay(for: Date.now)
        
        switch range {
        case .week:
            return Calendar.current.date(byAdding: .day, value: -6, to: fromDate) ?? Date.now
        case .thirtyDays:
            return Calendar.current.date(byAdding: .day, value: -29, to: fromDate) ?? Date.now
        case .sixMonths:
            return Calendar.current.date(byAdding: .day, value: -179, to: fromDate) ?? Date.now
        case .year:
            return Calendar.current.date(byAdding: .day, value: -364, to: fromDate) ?? Date.now
        case .allTime:
            return dateFormatter.date(from: dayData.first?.date ?? "1970-01-01") ?? Date(timeIntervalSince1970: 0)
        case .custom:
            return selectedStart
        }
    }
    
    private func getStopDate(_ range: DateRange) -> Date {
        if range == .custom {
            return selectedStop
        } else {
            return Date.now
        }
    }
    
    private func activityColor(of activityRank: ActivityRanks) -> Color {
        switch activityRank {
        case .none:
            return getColor(from: mAppData.first?.activityColors?[0] ?? Data(), default: Color.gray)
        case .bad:
            return getColor(from: mAppData.first?.activityColors?[1] ?? Data(), default: Color.red)
        case .ok:
            return getColor(from: mAppData.first?.activityColors?[2] ?? Data(), default: Color.yellow)
        case .good:
            return getColor(from: mAppData.first?.activityColors?[3] ?? Data(), default: Color.green)
        default:
            return getColor(from: mAppData.first?.activityColors?[0] ?? Data(), default: Color.gray)
        }
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
    }
}
