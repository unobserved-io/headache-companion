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
//    let selectedActivity: String
    @Binding var selectedActivity: String
    @State var currentColor = Color.gray
    
    init(of selectedActivity: Binding<String>) {
        _selectedActivity = selectedActivity
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: .now)
        _dayData = FetchRequest(
            sortDescriptors: [],
            predicate: NSPredicate(format: "date = %@", today)
        )
    }
    
    var body: some View {
        HStack {
            Button {
                currentColor = Color.gray
                saveSelected()
            } label: {
                Image(systemName: selectedImage())
            }
            .font(.system(size: 80))
            .foregroundColor(currentColor)
            VStack {
                Button {
                    currentColor = Color.red
                    saveSelected()
                } label: {
                    Image(systemName: "circle.fill")
                }
                .font(.system(size: 30))
                .foregroundColor(.red)
                Text("Bad")
                    .foregroundColor(.red)
            }
            .padding(.trailing)
            VStack {
                Button {
                    currentColor = Color.yellow
                    saveSelected()
                } label: {
                    Image(systemName: "circle.fill")
                }
                .font(.system(size: 30))
                .foregroundColor(.yellow)
                Text("OK")
                    .foregroundColor(.yellow)
            }
            .padding(.trailing)
            VStack {
                Button {
                    currentColor = Color.green
                    saveSelected()
                } label: {
                    Image(systemName: "circle.fill")
                }
                .font(.system(size: 30))
                .foregroundColor(.green)
                Text("Good")
                    .foregroundColor(.green)
            }
        }
        .onAppear() {
            getCurrentColor()
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
    
    private func correspondingInt() -> Int16 {
        switch currentColor {
        case .gray:
            return 0
        case .red:
            return 1
        case .yellow:
            return 2
        case .green:
            return 3
        default:
            return 0
        }
    }
    
    private func correspondingColor(of i: Int16) -> Color {
        switch i {
        case 0:
            return Color.gray
        case 1:
            return Color.red
        case 2:
            return Color.yellow
        case 3:
            return Color.green
        default:
            return Color.gray
        }
    }
    
    private func saveSelected() {
        switch selectedActivity {
        case "sleep":
            dayData.first?.sleep = correspondingInt()
        case "water":
            dayData.first?.water = correspondingInt()
        case "diet":
            dayData.first?.diet = correspondingInt()
        case "exercise":
            dayData.first?.exercise = correspondingInt()
        case "relax":
            dayData.first?.relax = correspondingInt()
        default:
            break
        }
        
        saveData()
    }
    
    private func getCurrentColor() {
        switch selectedActivity {
        case "sleep":
            currentColor = correspondingColor(of: dayData.first?.sleep ?? 0)
        case "water":
            currentColor = correspondingColor(of: dayData.first?.water ?? 0)
        case "diet":
            currentColor = correspondingColor(of: dayData.first?.diet ?? 0)
        case "exercise":
            currentColor = correspondingColor(of: dayData.first?.exercise ?? 0)
        case "relax":
            currentColor = correspondingColor(of: dayData.first?.relax ?? 0)
        default:
            currentColor = Color.gray
        }
    }
}

struct ActivitiesView_Previews: PreviewProvider {
    static var previews: some View {
        ActivitiesView(of: .constant("sleep"))
    }
}
