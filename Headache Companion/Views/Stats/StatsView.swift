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
        case thisWeek
        case lastWeek
        case sevenDays
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
    @State private var rangeIsEmpty: Bool = false
    @State private var chosenActivity: ChosenActivity = .water
    @State private var medTypeTriggers: [String: Bool] = [:]
    @State private var chevronTriggers: [String: Bool] = [:]
    private let daySingular = String(localized: "day")
    private let dayPlural = String(localized: "days")
    private let attackSingular = String(localized: "attack")
    private let attackPlural = String(localized: "attacks")

    var body: some View {
            ScrollView {
                VStack {
                    Picker("", selection: $dateRange) {
                        Text("This week").tag(DateRange.thisWeek)
                        Text("Last week").tag(DateRange.lastWeek)
                        Text("Past 7 days").tag(DateRange.sevenDays)
                        Text("Past 30 days").tag(DateRange.thirtyDays)
                        Text("Past 6 months").tag(DateRange.sixMonths)
                        Text("Past year").tag(DateRange.year)
                        Text("All time").tag(DateRange.allTime)
                        Text("Date Range").tag(DateRange.custom)
                    }
                    .onChange(of: dateRange) { range in
                        statsHelper.getStats(
                            from: dayDataInRange(range),
                            startDate: getFromDate(range),
                            stopDate: getStopDate(range, start: range == .lastWeek ? getFromDate(range) : Date.now)
                        )
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
                                selectedStart = Calendar.current.startOfDay(for: selectedStart)
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
                        }
                        if statsHelper.daysTrackedInRange > 0 {
                            GridRow {
                                mainStat(String(statsHelper.daysWithAttack))
                                statDescription("\(statsHelper.daysWithAttack == 1 ? daySingular : dayPlural) with an attack")
                            }
                            GridRow {
                                mainStat(String(statsHelper.numberOfAttacks))
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text("\(statsHelper.numberOfAttacks == 1 ? attackSingular : attackPlural)")
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
                                
                                GridRow {
                                    mainStat("\(statsHelper.percentTrackedWithAttack)%")
                                    statDescription("of tracked days had an attack")
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
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom)
                    
                    // MARK: Activities Stats

                    if statsHelper.daysTrackedInRange > 0 {
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
                }
                .padding()
                .addBorder(Color.accentColor, width: 4, cornerRadius: 15)
                .padding(.bottom)
                
                // MARK: Graphs
//                VStack(spacing: 12.0) {
//                    Text("Questions Answered")
//                    Chart(dayDataInRange) { day in
//                        let totalCount = day.responseCount + day.noResponseCount
//                        BarMark(
//                            x: .value("Date", day.grouping),
//                            y: .value("Questions", totalCount)
//                        )
//                        .annotation {
//                            if showQuestionsAnsweredOverlay {
//                                Text(String("\(totalCount)"))
//                                    .rotationEffect(.degrees(-90))
//                            }
//                        }
//
//                        if showChartThresholds {
//                            let questionsAnsweredThreshold = totalQuestionsAnswered / dayDataInRange.count
//                            RuleMark(
//                                y: .value("Threshold", questionsAnsweredThreshold)
//                            )
//                            .lineStyle(StrokeStyle(lineWidth: 2))
//                            .foregroundStyle(thresholdLineColor)
//                            .annotation(position: .top, alignment: .leading) {
//                                Text(String(questionsAnsweredThreshold))
//                                    .font(.title2.bold())
//                                    .foregroundColor(.primary)
//                                    .background {
//                                        ZStack {
//                                            RoundedRectangle(cornerRadius: 8)
//                                                .fill(.background)
//                                            RoundedRectangle(cornerRadius: 8)
//                                                .fill(.quaternary.opacity(0.7))
//                                        }
//                                        .padding(.horizontal, -8)
//                                        .padding(.vertical, -4)
//                                    }
//                                    .padding(.bottom, 4)
//                            }
//                        }
//                    }
//                    .chartYAxis {
//                        AxisMarks(position: .leading)
//                    }
//                    .onTapGesture {
//                        showQuestionsAnsweredOverlay.toggle()
//                    }
//                    .frame(height: chartFrameHeight)
//                }
                
                Spacer()
        }
        .padding(.horizontal)
        .onAppear {
            statsHelper.getStats(from: dayDataInRange(dateRange), startDate: getFromDate(dateRange), stopDate: getStopDate(dateRange))
        }
    }
    
    private func mainStat(_ stat: String) -> some View {
        return Text(stat)
            .font(Font.monospacedDigit(.body)())
            .foregroundColor(.accentColor)
            .bold()
    }
    
    private func statDescription(_ description: LocalizedStringKey) -> some View {
        return Text(description)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private func medTypeRow(for medType: String, amount: Int) -> some View {
        let theTuple = statsHelper.medicationByMedType.first(where: { $0.key == medType })
        
        let sortedDaysByAmount = statsHelper.daysByMedType.sorted(by: { $0.value > $1.value })
        let biggestAmount = sortedDaysByAmount[0].value
        let numOfDigitsInBiggest = biggestAmount.digits.count - 1

        return VStack(alignment: .leading) {
            HStack {
                Text(String(amount))
                    .font(Font.monospacedDigit(.body)())
                    .foregroundColor(.accentColor)
                    .bold()
                // This adds space if needed
                if amount.digits.count - 1 < numOfDigitsInBiggest {
                    Text(String(repeating: " ", count: numOfDigitsInBiggest))
                }
                Text("\(amount == 1 ? daySingular : dayPlural) \(String(localized: String.LocalizationValue(medType)))")
                    .padding(.leading)
                Image(systemName: medTypeTriggers[medType] ?? false ? "chevron.down" : "chevron.right")
                    .font(.system(size: 12))
            }
            .containerShape(Rectangle())
            .onTapGesture {
                if medTypeTriggers[medType] == nil {
                    medTypeTriggers[medType] = false
                }
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
        case .thisWeek:
            return Calendar.current.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: fromDate).date ?? Date.now
        case .lastWeek:
            let weekAgo = Calendar.current.date(byAdding: .day, value: -6, to: fromDate) ?? Date.now
            return Calendar.current.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: weekAgo).date ?? Date.now
        case .sevenDays:
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
    
    private func getStopDate(_ range: DateRange, start: Date = Date.now) -> Date {
        switch range {
        case .lastWeek:
            return Calendar.current.date(byAdding: .day, value: 6, to: start) ?? Date.now
        case .custom:
            return selectedStop
        default:
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
    
//    private func getDatesInRange() {
//        // Get all dayData in range
//        rangeIsEmpty = false
//        let stopDate: Date = getStopDate(dateRange)
//        let fromDate: Date = getFromDate(dateRange)
//        var tempDayDataInRange = dayData.filter {
//            (fromDate ... stopDate).contains(dateFormatter.date(from: $0.date ?? "1970-01-01") ?? .distantFuture)
//        }
//
//        if tempDayDataInRange.isEmpty {
//            rangeIsEmpty = true
//        } else {
//            // Add any missing days
//            let oneDay = TimeInterval(24 * 60 * 60) // seconds in one day
//            for date in stride(from: fromDate, through: stopDate, by: oneDay) {
//                if !tempDayDataInRange.contains(where: { $0.date == dateFormatter.string(from: date) }) {
//                    tempDayDataInRange.append(DayData(date: dateFormatter.string(from: date)))
//                }
//            }
//            // Sort the list
//            tempDayDataInRange.sort(by: { dateFormatter.date(from: $0.day)! < dateFormatter.date(from: $1.day)! })
//
//            // Group dayDataInRange by week/month, etc.
//            groupingType = decideGroupingType()
//            let tempDataGrouped = groupDayDataInRange(tempDayDataInRange)
//
//            dayDataInRange = tempDataGrouped
//        }
//    }
//
//    private func decideGroupingType() -> GroupStatsBy {
//        // TODO: This can be based on number of days in the dayDataInRange, which would be less if "Only show days worked" is turned on
//        let calendar = Calendar.current
//        let numberOfDaysInRange = (calendar.dateComponents([.day], from: rangeStartDate, to: rangeEndDate).day ?? 0) + 1
//        if numberOfDaysInRange <= 31 {
//            return .days
//        } else if numberOfDaysInRange <= 62 {
//            return .weeks
//        } else if numberOfDaysInRange <= 731 {
//            return .months
//        } else {
//            return .years
//        }
//    }
//
//    private func groupDayDataInRange(_ tempDayDataInRange: [DayData]) -> [DayDataGrouping] {
//        switch groupingType {
//        case .days: return groupDataByDay(tempDayDataInRange)
//        default: return groupDataByOther(tempDayDataInRange)
//        }
//    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
    }
}
