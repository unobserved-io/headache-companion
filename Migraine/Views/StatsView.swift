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
        case custom
    }

//    private let columns: [GridItem] = [
//        GridItem(.flexible(maximum: 60)),
//        GridItem(.flexible()),
//    ]
    private let statsHelper = StatsHelper()
    @State private var dateRange: DateRange = .week

    var body: some View {
        VStack {
            GroupBox {
                HStack {
                    Spacer()
                    Text("In the last")
                    Picker("", selection: $dateRange) {
                        Text("Week").tag(DateRange.week)
                        Text("30 days").tag(DateRange.thirtyDays)
                        Text("6 months").tag(DateRange.sixMonths)
                        Text("Year").tag(DateRange.year)
                        Text("Date Range").tag(DateRange.custom)
                    }
                    .onChange(of: dateRange) { range in
                        
                    }
                    Spacer()
                }

//                VStack(spacing: 15) {
//                    statStack(stat: "18", description: "Attacks", chevron: true)
//                        .containerShape(Rectangle())
//                        .onTapGesture {
//                            print("tapped")
//                        }
//                    statStack(stat: "18", description: "Days tracked")
//                    statStack(stat: "18%", description: "of days had an attack")
//                    statStack(stat: "10", description: "Symptoms", chevron: true)
//                        .containerShape(Rectangle())
//                        .onTapGesture {
//                            print("tapped")
//                        }
//                    statStack(stat: "2", description: "Types of headache", chevron: true)
//                        .containerShape(Rectangle())
//                        .onTapGesture {
//                            print("tapped")
//                        }
//                    statStack(stat: "3.5", description: "Average pain level")
//                    statStack(stat: "3", description: "Auras", chevron: true)
//                        .containerShape(Rectangle())
//                        .onTapGesture {
//                            print("tapped")
//                        }
//                    // TODO: Under Auras will be number broken down by type
//                    // Time of day?
//                    HStack(alignment: .center) {
//                        Image(systemName: "sunrise")
//                            .font(.title2)
//                            .foregroundColor(.accentColor)
//                            .bold()
//                            .padding(.trailing)
//                        Text("Most common time of day")
//                            .font(.title3)
//                    }
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                }
                
//                LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
//                    mainStat("18")
//                    statDescriptionChevron("Attacks")
//
//                    mainStat("18")
//                    statDescription("Days tracked")
//                }
                Grid(alignment: .leading, verticalSpacing: 5) {
                    GridRow {
                        mainStat("18")
                        statDescriptionChevron("Attacks")
                    }
                    GridRow {
                        mainStat("18")
                        statDescription("Days Tracked")
                    }
                    GridRow {
                        mainStat("18 %")
                        statDescription("Of days had an attack")
                    }
                    GridRow {
                        mainStat("10")
                        statDescriptionChevron("Symptoms")
                    }
                    GridRow {
                        mainStat("2")
                        statDescriptionChevron("Types of headache")
                    }
                    GridRow {
                        mainStat("3.5")
                        statDescription("Average pain level")
                    }
                    GridRow {
                        mainStat("3")
                        statDescriptionChevron("Auras")
                    }
                    GridRow {
                        Image(systemName: "sunrise")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                            .bold()
                            .padding(.trailing)
                        Text("Most common time of day")
                            .font(.title3)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()
        }
        .padding()
    }

//    private func statStack(stat: String, description: String, chevron: Bool = false) -> some View {
//        return HStack(alignment: .center) {
//            Text(stat)
//                .font(.title2)
//                .foregroundColor(.accentColor)
//                .bold()
//                .padding(.trailing)
//            Text(description)
//                .font(.title3)
//            if chevron {
//                Image(systemName: "chevron.right")
//                    .font(.system(size: 12))
//            }
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//    }
    
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
    
    private func getStats() {
        
    }
    
//    func loadQuestion() -> [DayData]? {
//        let fetchRequest: NSFetchRequest<DayData> = DayData.fetchRequest()
//
//        do {
//            let array = try viewContext.fetch(fetchRequest) as [DayData]
//            return array
//        } catch {
//            print("error FetchRequest \(error)")
//        }
//
//        return nil
//    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
    }
}
