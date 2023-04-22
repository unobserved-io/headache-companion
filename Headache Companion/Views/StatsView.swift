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
    @State private var selectedStart: Date = .now
    @State private var selectedStop: Date = .now
    @State private var clickedAttacks: Bool = false
    @State private var clickedSymptoms: Bool = false
    @State private var clickedDaysWithMeds: Bool = false
    @State private var clickedPreventiveMeds: Bool = false
    @State private var clickedSRMeds: Bool = false
    @State private var clickedOtherMeds: Bool = false
    @State private var clickedAuraTypes: Bool = false
    @State private var clickedAuraTotals: Bool = false
    @State private var clickedMedNames: Bool = false
    @State private var chosenActivity: ChosenActivity = .water
    @State private var medTypeTriggers: [String: Bool] = [:]
    @State private var chevronTriggers: [String: Bool] = [:]
    private let daySingular = String(localized: "day")
    private let dayPlural = String(localized: "days")
    private let attackSingular = String(localized: "attack")
    private let attackPlural = String(localized: "attacks")

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
                            DatePicker(
                                selection: $selectedStart,
                                in: Date(timeIntervalSinceReferenceDate: 0) ... selectedStop,
                                displayedComponents: [.date],
                                label: {}
                            )
                            .labelsHidden()
                            .onChange(of: selectedStart) { _ in
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
                            .onChange(of: selectedStop) { _ in
                                statsHelper.getStats(from: dayDataInRange(dateRange), startDate: getFromDate(dateRange), stopDate: getStopDate(dateRange))
                            }
                        }
                        .padding(.bottom)
                    }
                    Grid(alignment: .topLeading, verticalSpacing: 5) {
                        GridRow {
                            mainStat(String(statsHelper.daysTrackedInRange))
                            statDescription("\(statsHelper.daysTrackedInRange == 1 ? daySingular : dayPlural) tracked")
//                            Text("^[\(statsHelper.daysTracked) \("day")](inflect: true) tracked")
                        }
                        GridRow {
                            mainStat(String(statsHelper.daysWithAttack))
                            statDescription("\(statsHelper.daysWithAttack == 1 ? daySingular : dayPlural) with an attack")
                        }
                        GridRow {
                            mainStat(String(statsHelper.numberOfAttacks))
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("\(statsHelper.numberOfAttacks == 1 ? attackSingular : attackPlural)")
                                        .font(.title3)
                                    Image(systemName: clickedAttacks ? "chevron.down" : "chevron.right")
                                        .font(.system(size: 12))
                                }
                                if clickedAttacks {
                                    Grid(alignment: .leading, verticalSpacing: 5) {
                                        ForEach(statsHelper.allTypesOfHeadache, id: \.key) { type, num in
                                            GridRow {
                                                Text(String(num))
                                                    .font(Font.monospacedDigit(.body)())
                                                    .foregroundColor(.accentColor)
                                                    .bold()
                                                    .padding(.trailing)
                                                Text(LocalizedStringKey(type.localizedCapitalized))
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

                        if statsHelper.daysWithAttack > 0 {
                            GridRow {
                                mainStat("\(statsHelper.percentWithAttack)%")
                                statDescription("of days had an attack")
                            }
                            
                            Divider()
                                .background(Color.accentColor)
                                .frame(minHeight: 1)
                                .overlay(Color.accentColor)
                            
                            GridRow {
                                mainStat(String(format: "%.1f", statsHelper.averagePainLevel))
                                statDescription("average pain level")
                            }
                            
                            GridRow {
                                mainStat(String(statsHelper.allSymptoms.count))
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack {
                                        Text("\(statsHelper.allSymptoms.count == 1 ? String(localized: "symptom") : String(localized: "symptoms"))")
                                            .font(.title3)
                                        Image(systemName: clickedSymptoms ? "chevron.down" : "chevron.right")
                                            .font(.system(size: 12))
                                    }
                                    if clickedSymptoms {
                                        ForEach(statsHelper.symptomsByHeadache, id: \.key) { type, symptoms in
                                            Text(LocalizedStringKey(type.localizedCapitalized))
                                            ForEach(symptoms.sorted(), id: \.self) { symptom in
                                                Text(LocalizedStringKey(symptom))
                                            }
                                            .padding(.leading)
                                        }
                                        .padding(.leading)
                                    }
                                }
                                .containerShape(Rectangle())
                                .onTapGesture {
                                    clickedSymptoms.toggle()
                                }
                            }
                            
                            GridRow {
                                mainStat(String(statsHelper.attacksWithAura))
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text("\(statsHelper.attacksWithAura == 1 ? attackSingular : attackPlural) with an aura")
                                            .font(.title3)
                                        Image(systemName: clickedAuraTotals ? "chevron.down" : "chevron.right")
                                            .font(.system(size: 12))
                                    }
                                    if clickedAuraTotals {
                                        Grid(alignment: .leading, verticalSpacing: 5) {
                                            ForEach(statsHelper.allAuras, id: \.key) { type, num in
                                                GridRow {
                                                    Text(String(num))
                                                        .foregroundColor(.accentColor)
                                                        .bold()
                                                        .padding(.trailing)
                                                    Text(LocalizedStringKey(type))
                                                }
                                            }
                                        }
                                        .padding(.leading)
                                    }
                                }
                                .containerShape(Rectangle())
                                .onTapGesture {
                                    clickedAuraTotals.toggle()
                                }
                            }
                        }
                        
                        Divider()
                            .background(Color.accentColor)
                            .frame(minHeight: 1)
                            .overlay(Color.accentColor)
                        
                        if statsHelper.daysWithMedication > 0 {
                            GridRow {
                                mainStat("\(statsHelper.daysWithMedication)")
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack {
                                        Text("\(statsHelper.daysWithMedication == 1 ? daySingular : dayPlural) you took medication")
                                            .font(.title3)
                                        Image(systemName: clickedDaysWithMeds ? "chevron.down" : "chevron.right")
                                            .font(.system(size: 12))
                                        Spacer() // Stops other text from jumping when expanded
                                    }
                                    if clickedDaysWithMeds {
                                        ForEach(statsHelper.daysByMedType, id: \.key) { type, amount in
                                            medTypeRow(for: type, amount: amount)
                                        }
                                        .padding(.leading)
                                    }
                                }
                                .containerShape(Rectangle())
                                .onTapGesture {
                                    clickedDaysWithMeds.toggle()
                                }
                            }
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
                            PieChart(values: statsHelper.waterInSelectedDays, colors: [correspondingColor(of: .none), correspondingColor(of: .bad), correspondingColor(of: .ok), correspondingColor(of: .good)], icon: "drop.fill")
                        case .diet:
                            PieChart(values: statsHelper.dietInSelectedDays, colors: [correspondingColor(of: .none), correspondingColor(of: .bad), correspondingColor(of: .ok), correspondingColor(of: .good)], icon: "carrot.fill")
                        case .exercise:
                            PieChart(values: statsHelper.exerciseInSelectedDays, colors: [correspondingColor(of: .none), correspondingColor(of: .bad), correspondingColor(of: .ok), correspondingColor(of: .good)], icon: "figure.strengthtraining.functional")
                        case .relax:
                            PieChart(values: statsHelper.relaxInSelectedDays, colors: [correspondingColor(of: .none), correspondingColor(of: .bad), correspondingColor(of: .ok), correspondingColor(of: .good)], icon: "figure.mind.and.body")
                        case .sleep:
                            PieChart(values: statsHelper.sleepInSelectedDays, colors: [correspondingColor(of: .none), correspondingColor(of: .bad), correspondingColor(of: .ok), correspondingColor(of: .good)], icon: "bed.double.fill")
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
                .padding(.bottom)
                
                Grid(alignment: .topLeading, verticalSpacing: 5) {
                    GridRow {
                        mainStat(String(statsHelper.daysTrackedTotal))
                        statDescription("\(statsHelper.daysTrackedTotal == 1 ? daySingular : dayPlural) with recorded data")
                    }
                    
                    GridRow {
                        mainStat(String((Calendar.current.dateComponents([.day], from: mAppData.first?.launchDay ?? .now, to: Calendar.current.startOfDay(for: Date.now)).day ?? 0) + 1))
                        statDescription("\((Calendar.current.dateComponents([.day], from: mAppData.first?.launchDay ?? .now, to: Calendar.current.startOfDay(for: Date.now)).day ?? 0) + 1 == 1 ? daySingular : dayPlural) using Headache Companion")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom)
                
                Spacer()
            }
        }
        .scrollContentBackground(.hidden)
        .padding(.horizontal)
        .padding(.top)
        .onAppear {
            statsHelper.getStats(from: dayDataInRange(dateRange), startDate: getFromDate(dateRange), stopDate: getStopDate(dateRange))
        }
    }
    
    private func mainStat(_ stat: String) -> some View {
        return Text(stat)
            .font(Font.monospacedDigit(.title3)())
            .foregroundColor(.accentColor)
            .bold()
    }
    
    private func statDescription(_ description: LocalizedStringKey) -> some View {
        return Text(description)
            .font(.title3)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private func medTypeRow(for medType: String, amount: Int) -> some View {
        if medTypeTriggers[medType] == nil {
            medTypeTriggers[medType] = false
        }
        let theTuple = statsHelper.medicationByMedType.first(where: { $0.key == medType })
        
        return VStack(alignment: .leading) {
            HStack {
                Text(String(amount))
                    .font(Font.monospacedDigit(.body)())
                    .foregroundColor(.accentColor)
                    .bold()
                    .padding(.trailing)
                Text(amount == 1 ? daySingular : dayPlural) + Text(" ") + Text(LocalizedStringKey(medType))
                Image(systemName: medTypeTriggers[medType] ?? false ? "chevron.down" : "chevron.right")
                    .font(.system(size: 12))
            }
            .containerShape(Rectangle())
            .onTapGesture {
                medTypeTriggers[medType]?.toggle()
            }
            if medTypeTriggers[medType] ?? false && theTuple != nil {
                VStack(alignment: .leading) {
                    Grid(alignment: .leading, verticalSpacing: 5) {
                        ForEach(theTuple!.value, id: \.key) { name, days in
                            GridRow {
                                Text(String(days))
                                    .font(Font.monospacedDigit(.body)())
                                    .foregroundColor(.accentColor)
                                    .bold()
                                    .padding(.trailing)
                                Text("\(days == 1 ? daySingular : dayPlural) \(name)")
                            }
                        }
                    }
                    .padding(.leading)
                }
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
    
    private func correspondingColor(of activityRank: ActivityRanks) -> Color {
        switch activityRank {
        case .none:
            return Color(hex: mAppData.first?.activityColors?[0]) ?? Color.gray
        case .bad:
            return Color(hex: mAppData.first?.activityColors?[1]) ?? Color.red
        case .ok:
            return Color(hex: mAppData.first?.activityColors?[2]) ?? Color.yellow
        case .good:
            return Color(hex: mAppData.first?.activityColors?[3]) ?? Color.green
        default:
            return Color(hex: mAppData.first?.activityColors?[0]) ?? Color.gray
        }
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
    }
}
