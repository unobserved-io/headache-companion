//
//  StatsView.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/11/23.
//

import Charts
import CoreData
import StoreKit
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
    
    private enum GroupStatsBy {
        case days
        case weeks
        case months
        case years
    }

    private enum ChosenActivity: String {
        case water
        case diet
        case exercise
        case relax
        case sleep
    }

    @ObservedObject var statsHelper = StatsHelper.sharedInstance
    @ObservedObject var storeModel = StoreModel.shared
    
    @State private var dateRange: DateRange = .sevenDays
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
    @State private var showingPurchaseAlert: Bool = false
    @State private var chosenActivity: ChosenActivity = .water
    @State private var medTypeTriggers: [String: Bool] = [:]
    @State private var chevronTriggers: [String: Bool] = [:]
    @State private var groupingType: GroupStatsBy = .days
    @State private var dayDataInRange: [DayDataGrouping] = []
    @State private var dayDataWithAttackInRange: [DayData] = []
    @State private var dayDataGroupingWithAttackInRange: [DayDataGrouping] = []
    @State private var hasAttackOrNot: [AttackOrNot]  = []
    @State private var rangeStartDate: Date = Calendar.current.date(byAdding: .day, value: -6, to: .now) ?? .now
    @State private var rangeEndDate: Date = .now
    
    
    private let daySingular = String(localized: "day")
    private let dayPlural = String(localized: "days")
    private let attackSingular = String(localized: "attack")
    private let attackPlural = String(localized: "attacks")
    private let chartFrameHeight: CGFloat? = 200
    private let thresholdLineColor: Color = .gray

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
                    .onChange(of: dateRange) { newRange in
                        updateRangeStartDate(range: newRange)
                        updateRangeEndDate(range: newRange)
                        statsHelper.getStats(
                            from: dayDataInRange(newRange),
                            startDate: rangeStartDate,
                            stopDate: rangeEndDate
                        )
                        updateAllStats()
                    }
                    if dateRange == .custom {
                        HStack {
                            DatePicker(
                                selection: $rangeStartDate,
                                in: Date(timeIntervalSinceReferenceDate: 0) ... rangeEndDate,
                                displayedComponents: [.date],
                                label: {}
                            )
                            .labelsHidden()
                            .onChange(of: rangeStartDate) { _ in
                                rangeStartDate = Calendar.current.startOfDay(for: rangeStartDate)
                                statsHelper.getStats(from: dayDataInRange(dateRange), startDate: rangeStartDate, stopDate: rangeEndDate)
                                updateAllStats()
                            }
                            Text("to")
                            DatePicker(
                                selection: $rangeEndDate,
                                in: rangeStartDate ... Date.now,
                                displayedComponents: [.date],
                                label: {}
                            )
                            .frame(minHeight: 35)
                            .labelsHidden()
                            .onChange(of: rangeEndDate) { _ in
                                statsHelper.getStats(from: dayDataInRange(dateRange), startDate: rangeStartDate, stopDate: rangeEndDate)
                                updateAllStats()
                            }
                        }
                        .padding(.bottom)
                    }
                    
                    // MARK: Graphs
                    attacksBarChart
                        .padding(.top, 30.0)
                    
                    VStack(spacing: 30.0) {
                        if storeModel.purchasedIds.isEmpty {
                            Button("Upgrade to Pro to see more graphs") {
                                showingPurchaseAlert.toggle()
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            // Pain level line graph (only days with an attack)
                            painLevelLineGraph
                            
                            daysWithAttackPieChart
                            
                            headacheTypeChart
                        }
                    }
                    .padding(.top, 30.0)
                    
                    // MARK: Text stats
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
                    .padding(.top, 20)
                    
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
//                .addBorder(Color.accentColor, width: 4, cornerRadius: 15)
                .padding(.bottom)
                
                Spacer()
        }
        .padding(.horizontal)
        .onAppear {
            statsHelper.getStats(from: dayDataInRange(dateRange), startDate: rangeStartDate, stopDate: rangeEndDate)
            updateAllStats()
        }
        .alert("Go Pro?", isPresented: $showingPurchaseAlert) {
            if let product = storeModel.products.first {
                Button("Upgrade (\(product.displayPrice))") {
                    Task {
                        try await storeModel.purchase()
                    }
                }
                Button("Restore purchase") {
                    Task {
                        try await AppStore.sync()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Upgrade to Pro to see better stats.")
        }
    }
    
    private var attacksBarChart: some View {
        VStack(spacing: 12.0) {
            Text("Attacks")
            Chart(dayDataInRange) { day in
                BarMark(
                    x: .value("Date", day.grouping),
                    y: .value("Attacks", day.attackCount)
                )
//                        .annotation {
//                            if showQuestionsAnsweredOverlay {
//                                Text(String("\(totalCount)"))
//                                    .rotationEffect(.degrees(-90))
//                            }
//                        }

                if statsHelper.numberOfAttacks != 0 {
                    let attackCountThreshold = statsHelper.numberOfAttacks / dayDataInRange.count
                    if attackCountThreshold != 0 {
                        RuleMark(
                            y: .value("Threshold", attackCountThreshold)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .foregroundStyle(thresholdLineColor)
                        .annotation(position: .top, alignment: .leading) {
                            Text(String(attackCountThreshold))
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                                .background {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.background)
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.quaternary.opacity(0.7))
                                    }
                                    .padding(.horizontal, -8)
                                    .padding(.vertical, -4)
                                }
                                .padding(.bottom, 4)
                        }
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
//                .onTapGesture {
//                    showQuestionsAnsweredOverlay.toggle()
//                }
        .frame(height: chartFrameHeight)
    }
    
    private var painLevelLineGraph: some View {
        VStack(spacing: 12.0) {
            Text("Average Pain")
            Chart(dayDataGroupingWithAttackInRange) { day in
                LineMark(
                    x: .value("Date", day.grouping),
                    y: .value("Average Pain", day.pain)
                )
                
                PointMark(
                    x: .value("Date", day.grouping),
                    y: .value("Average Pain", day.pain)
                )
//                        .annotation {
//                            if showQuestionsAnsweredOverlay {
//                                Text(String("\(totalCount)"))
//                                    .rotationEffect(.degrees(-90))
//                            }
//                        }

                if statsHelper.numberOfAttacks != 0 {
                    if statsHelper.averagePainLevel > 0 {
                        RuleMark(
                            y: .value("Threshold", statsHelper.averagePainLevel)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .foregroundStyle(thresholdLineColor)
                        .annotation(position: .top, alignment: .leading) {
                            Text(String(format: "%.1f", statsHelper.averagePainLevel))
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                                .background {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.background)
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.quaternary.opacity(0.7))
                                    }
                                    .padding(.horizontal, -8)
                                    .padding(.vertical, -4)
                                }
                                .padding(.bottom, 4)
                        }
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
//                .onTapGesture {
//                    showQuestionsAnsweredOverlay.toggle()
//                }
        .frame(height: chartFrameHeight)
    }
    
    private var daysWithAttackPieChart: some View {
        if #available(iOS 17, *) {
            return VStack(spacing: 12.0) {
                Text("Days With An Attack")
                Chart(hasAttackOrNot) { attackOrNot in
                    SectorMark(
                        angle: .value("Days With An Attack", attackOrNot.count),
                        angularInset: 3.0
                    )
                    .annotation(position: .overlay) {
//                                                if showResponseSplitPercent {
//                                                    Text("\(countType.percent) %")
//                                                } else {
//                                                    Text("\(countType.count)")
//                                                }
                        Text("\(attackOrNot.count)")
                    }
                    .cornerRadius(6.0)
                    .foregroundStyle(by: .value("", attackOrNot.type))
                }
                .chartForegroundStyleScale([
                    "Attacks": Color.accent,
                    "No Attacks": Color.gray
                ])
//                                .onTapGesture {
//                                    showResponseSplitPercent.toggle()
//                                }
                .frame(height: chartFrameHeight)
            }
        } else {
            return EmptyView()
        }
    }
    
    private var headacheTypeChart: some View {
        VStack(spacing: 12.0) {
            Text("Attack Types")
            Chart(dayDataGroupingWithAttackInRange) { day in
                ForEach(day.attackTypes.sorted(by: >), id: \.key) { attackType, count in
                    BarMark(
                        x: .value("Date", day.grouping),
                        y: .value("Attack Type", count)
                    )
                    .foregroundStyle(by: .value("", attackType))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: chartFrameHeight)
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
        
        dayData.forEach { day in
            let dayDate = dateFormatter.date(from: day.date ?? "1970-01-01")
            
            if dayDate?.isBetween(rangeStartDate, and: rangeEndDate) ?? false {
                inRange.append(day)
            }
        }
        
        return inRange
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
    
    private func updateRangeStartDate(range: DateRange) {
        let fromDate: Date = Calendar.current.startOfDay(for: Date.now)
        switch range {
        case .thisWeek:
            rangeStartDate = Calendar.current.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: fromDate).date ?? Date.now
        case .lastWeek:
            let weekAgo = Calendar.current.date(byAdding: .day, value: -6, to: fromDate) ?? Date.now
            rangeStartDate = Calendar.current.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: weekAgo).date ?? Date.now
        case .sevenDays:
            rangeStartDate = Calendar.current.date(byAdding: .day, value: -6, to: fromDate) ?? Date.now
        case .thirtyDays:
            rangeStartDate = Calendar.current.date(byAdding: .day, value: -29, to: fromDate) ?? Date.now
        case .sixMonths:
            rangeStartDate = Calendar.current.date(byAdding: .day, value: -179, to: fromDate) ?? Date.now
        case .year:
            rangeStartDate = Calendar.current.date(byAdding: .day, value: -364, to: fromDate) ?? Date.now
        case .allTime:
            rangeStartDate = dateFormatter.date(from: dayData.first?.date ?? "1970-01-01") ?? Date(timeIntervalSince1970: 0)
        case .custom:
            break
        }
    }

    private func updateRangeEndDate(range: DateRange) {
        switch range {
        case .lastWeek:
            rangeEndDate = Calendar.current.date(byAdding: .day, value: 6, to: rangeStartDate) ?? Date.now
        case .custom:
            break
        default:
            rangeEndDate = Date.now
        }
    }
    
    private func updateAllStats() {
        rangeIsEmpty = false
        DispatchQueue.main.async {
            getDatesInRange()
            getDatesWithAttackInRange()
            hasAttackOrNot = [
                .init(type: "Attacks", count: statsHelper.daysWithAttack),
                .init(type: "No Attacks", count: statsHelper.daysInRange - statsHelper.daysWithAttack)
            ]
        }
    }
    
    private func getDatesInRange() {
        var tempDayDataInRange = dayData.filter {
            (rangeStartDate ... rangeEndDate).contains(dateFormatter.date(from: $0.date ?? "1970-01-01") ?? .distantFuture)
        }

        if tempDayDataInRange.isEmpty {
            rangeIsEmpty = true
        } else {
            // Save days with attacks for later use
            dayDataWithAttackInRange = tempDayDataInRange.filter { $0.attack?.count ?? 0 > 0 }
            
            // Add any missing days
            let childContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            let oneDay = TimeInterval(24 * 60 * 60) // seconds in one day
            for date in stride(from: rangeStartDate, through: rangeEndDate, by: oneDay) {
                if !tempDayDataInRange.contains(where: { $0.date == dateFormatter.string(from: date) }) {
                    let tempDay = DayData(context: childContext)
                    tempDay.date = dateFormatter.string(from: date)
                    tempDayDataInRange.append(tempDay)
                }
                
            }
            // Sort the list
            tempDayDataInRange.sort(by: {
                dateFormatter.date(from: $0.date ?? "1970-01-01")! < dateFormatter.date(from: $1.date ?? "1970-01-01")!
            })

            // Group dayDataInRange by week/month, etc.
            groupingType = decideGroupingType()
            dayDataInRange = groupDayDataInRange(tempDayDataInRange)
        }
    }
    
    private func getDatesWithAttackInRange() {
        dayDataWithAttackInRange.sort(by: {
            dateFormatter.date(from: $0.date ?? "1970-01-01")! < dateFormatter.date(from: $1.date ?? "1970-01-01")!
        })
        dayDataGroupingWithAttackInRange = groupDayDataInRange(dayDataWithAttackInRange)
    }

    private func decideGroupingType() -> GroupStatsBy {
        let calendar = Calendar.current
        let numberOfDaysInRange = (calendar.dateComponents([.day], from: rangeStartDate, to: rangeEndDate).day ?? 0) + 1
        if numberOfDaysInRange <= 31 {
            return .days
        } else if numberOfDaysInRange <= 62 {
            return .weeks
        } else if numberOfDaysInRange <= 731 {
            return .months
        } else {
            return .years
        }
    }

    private func groupDayDataInRange(_ tempDayDataInRange: [DayData]) -> [DayDataGrouping] {
        switch groupingType {
        case .days: return groupDataByDay(tempDayDataInRange)
        default: return groupDataByOther(tempDayDataInRange)
        }
    }
    
    private func groupDataByDay(_ dataInRange: [DayData]) -> [DayDataGrouping] {
        var dataGrouping: [DayDataGrouping] = []
        for currentDay in dataInRange {
            dataGrouping.append(
                .init(
                    attackCount: currentDay.attack?.count ?? 0,
                    attackTypes: Dictionary(grouping: currentDay.attacks, by: { $0.headacheType }).mapValues { items in items.count },
                    pain: currentDay.attacks.lazy.compactMap { $0.painLevel }.reduce(0, +) / Double(currentDay.attack?.count ?? 0),
                    // TODO: Localize date for grouping
                    grouping: String((currentDay.date ?? "1970-01-01").dropFirst(5))
                )
            )
        }
        return dataGrouping
    }

    private func groupDataByOther(_ dataInRange: [DayData]) -> [DayDataGrouping] {
        let component = getComponentType()

        var dataGrouping: [DayDataGrouping] = []
        var tempGrouping: [Int: DayDataGrouping] = [:]
        var groupingYear: Int?
        var groupingWithYears: [Int: Int] = [:]
        for currentDay in dataInRange {
            if let currentDate = dateFormatter.date(from: currentDay.date ?? "1970-01-01") {
                var grouping = Calendar.current.component(component, from: currentDate)
                if groupingType == .months {
                    groupingYear = Calendar.current.component(.year, from: currentDate)
                    grouping = grouping * (groupingYear ?? 2023)
                    groupingWithYears[grouping] = groupingYear
                }
                if let _ = tempGrouping[grouping] {
                    tempGrouping[grouping]!.attackCount += currentDay.attack?.count ?? 0
                    for attack in currentDay.attacks {
                        tempGrouping[grouping]!.attackTypes[attack.headacheType, default: 0] += 1
                    }
                    tempGrouping[grouping]!.pain += currentDay.attacks.lazy.compactMap { $0.painLevel }.reduce(0, +)
                    // TODO: Add pain
                } else {
                    tempGrouping[grouping] = .init(
                        attackCount: currentDay.attack?.count ?? 0,
                        attackTypes: Dictionary(grouping: currentDay.attacks, by: { $0.headacheType }).mapValues { items in items.count },
                        pain:  currentDay.attacks.lazy.compactMap { $0.painLevel }.reduce(0, +),
                        grouping: ""
                    )
                }
            }
        }

        if groupingType == .months {
            let formatter: DateFormatter = {
                let df = DateFormatter()
                df.locale = Locale(identifier: "en_US_POSIX")
                df.dateFormat = "MM yyyy"
                return df
            }()
            // Convert Month/Year string to date to be sorted properly
            for grouping in tempGrouping.sorted(by: { (formatter.date(from: "\(DateFormatter().monthSymbols[($0.key / (groupingWithYears[$0.key] ?? 1)) - 1]) \(groupingWithYears[$0.key] ?? 1)") ?? .now) < (formatter.date(from: "\(DateFormatter().monthSymbols[($1.key / (groupingWithYears[$1.key] ?? 1)) - 1]) \(groupingWithYears[$1.key] ?? 1)") ?? .now) }) {
                dataGrouping.append(
                    .init(
                        attackCount: grouping.value.attackCount,
                        attackTypes: grouping.value.attackTypes,
                        pain: grouping.value.pain / Double(grouping.value.attackCount),
                        grouping: getGroupingString(key: grouping.key, year: groupingWithYears)
                    )
                )
            }
        } else {
            for grouping in tempGrouping.sorted(by: { $0.key < $1.key }) {
                dataGrouping.append(
                    .init(
                        attackCount: grouping.value.attackCount,
                        attackTypes: grouping.value.attackTypes,
                        pain: grouping.value.pain / Double(grouping.value.attackCount),
                        grouping: getGroupingString(key: grouping.key, year: groupingWithYears)
                    )
                )
            }
        }
        return dataGrouping
    }
    
    private func getComponentType() -> Calendar.Component {
        switch groupingType {
        case .days:
            return .day
        case .weeks:
            return .weekOfYear
        case .months:
            return .month
        case .years:
            return .year
        }
    }
    
    private func getGroupingString(key: Int, year: [Int: Int]) -> String {
        switch groupingType {
        case .weeks:
            return "Wk \(key)"
        case .months:
            let monthNum = key / (year[key] ?? 1)
            let monthName = DateFormatter().monthSymbols[monthNum - 1]
            return "\(monthName[monthName.startIndex ... monthName.index(monthName.startIndex, offsetBy: 2)]) '\((year[key] ?? 2023) % 100)"
        default:
            return String(key)
        }
    }
}

struct DayDataGrouping: Identifiable, Equatable {
    var attackCount: Int
    var attackTypes: [String:Int]
    var pain: Double
    var grouping: String
    var id = UUID()
}

struct AttackOrNot: Identifiable {
    var type: String
    var count: Int
    var id = UUID()
}


#Preview {
    StatsView()
}
