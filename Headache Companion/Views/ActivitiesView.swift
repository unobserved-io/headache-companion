//
//  ActivitiesView.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/2/23.
//

import SwiftUI

struct ActivitiesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest var dayData: FetchedResults<DayData>
    @FetchRequest(
        entity: MAppData.entity(),
        sortDescriptors: []
    )
    var mAppData: FetchedResults<MAppData>
    @Binding var selectedActivity: String
    let forDateString: String
    @State var currentColor = Color.gray
    @State var badColor = Color.red
    @State var okColor = Color.yellow
    @State var goodColor = Color.green
    
    init(of selectedActivity: Binding<String>, for forDate: Date) {
        _selectedActivity = selectedActivity
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        forDateString = dateFormatter.string(from: forDate)
        _dayData = FetchRequest(
            sortDescriptors: [],
            predicate: NSPredicate(format: "date = %@", forDateString)
        )
    }
    
    var body: some View {
        HStack {
            Button {
                currentColor = correspondingColor(of: .none)
                saveSelected(rank: .none)
            } label: {
                Image(systemName: selectedImage())
            }
            .font(.system(size: 80))
            .foregroundColor(currentColor)
            VStack {
                Button {
                    currentColor = correspondingColor(of: .bad)
                    saveSelected(rank: .bad)
                } label: {
                    Image(systemName: "circle.fill")
                }
                .font(.system(size: 30))
                .foregroundColor(badColor)
                Text("Bad")
                    .foregroundColor(badColor)
            }
            .padding(.trailing)
            VStack {
                Button {
                    currentColor = correspondingColor(of: .ok)
                    saveSelected(rank: .ok)
                } label: {
                    Image(systemName: "circle.fill")
                }
                .font(.system(size: 30))
                .foregroundColor(okColor)
                Text("OK")
                    .foregroundColor(okColor)
            }
            .padding(.trailing)
            VStack {
                Button {
                    currentColor = correspondingColor(of: .good)
                    saveSelected(rank: .good)
                } label: {
                    Image(systemName: "circle.fill")
                }
                .font(.system(size: 30))
                .foregroundColor(goodColor)
                Text("Good")
                    .foregroundColor(goodColor)
            }
        }
        .onAppear {
            getCurrentColor()
            badColor = correspondingColor(of: .bad)
            okColor = correspondingColor(of: .ok)
            goodColor = correspondingColor(of: .good)
        }
    }
    
    private func selectedImage() -> String {
        switch selectedActivity {
        case "sleep":
            return "bed.double"
        case "water":
            return "drop"
        case "diet":
            return "carrot"
        case "exercise":
            return "figure.strengthtraining.functional"
        case "relax":
            return "figure.mind.and.body"
        default:
            return "questionmark.circle"
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
    
    private func saveSelected(rank: ActivityRanks) {
        var foundDayData = dayData.first
        if foundDayData == nil {
            foundDayData = DayData(context: viewContext)
            foundDayData?.date = forDateString
        }
        
        switch selectedActivity {
        case "sleep":
            foundDayData?.sleep = rank
        case "water":
            foundDayData?.water = rank
        case "diet":
            foundDayData?.diet = rank
        case "exercise":
            foundDayData?.exercise = rank
        case "relax":
            foundDayData?.relax = rank
        default:
            break
        }
        
        saveData()
    }
    
    private func getCurrentColor() {
        switch selectedActivity {
        case "sleep":
            currentColor = correspondingColor(of: dayData.first?.sleep ?? .none)
        case "water":
            currentColor = correspondingColor(of: dayData.first?.water ?? .none)
        case "diet":
            currentColor = correspondingColor(of: dayData.first?.diet ?? .none)
        case "exercise":
            currentColor = correspondingColor(of: dayData.first?.exercise ?? .none)
        case "relax":
            currentColor = correspondingColor(of: dayData.first?.relax ?? .none)
        default:
            currentColor = Color.gray
        }
    }
}

struct ActivitiesView_Previews: PreviewProvider {
    static var previews: some View {
        ActivitiesView(of: .constant("sleep"), for: .now)
    }
}
