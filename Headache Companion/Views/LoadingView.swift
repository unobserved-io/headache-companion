//
//  LoadingView.swift
//  Headache Companion
//
//  Created by Ricky Kresslein on 3/27/23.
//

import SwiftUI

struct LoadingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: DayData.entity(), sortDescriptors: [])
    var dayData: FetchedResults<DayData>
    @FetchRequest(entity: MAppData.entity(), sortDescriptors: [])
    var mAppData: FetchedResults<MAppData>
    @AppStorage("lastLaunch") private var lastLaunch: String = ""
    @State var isAnimated: Bool = false
    let todayString: String = dateFormatter.string(from: .now)
    
    var body: some View {
        if lastLaunch == todayString {
            MainView()
        } else if dayData.isEmpty || mAppData.isEmpty || !dayData.contains(where: { $0.date == todayString}) {
            LoadingBars(animate: $isAnimated, count: 3)
                .foregroundColor(.accentColor)
                .frame(maxWidth: 100)
                .onAppear() {
                    isAnimated = true
                    
                    // Use last launch to potentially speed up loading time on first run of the day
                    if lastLaunch.isEmpty {
                        initializeDataInThree()
                    } else {
                        if dayData.isEmpty {
                            initializeDataInThree()
                        } else {
                            // Double check that dayData doesn't contain date before creating
                            if !dayData.contains(where: { $0.date == todayString}) {
                                initNewDay()
                                lastLaunch = todayString
                            }
                        }
                    }
                }
                .onDisappear { isAnimated = false }
        } else {
            MainView()
        }
    }
    
    private func initializeDataInThree() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if mAppData.isEmpty {
                initializeMAppData()
            }
            if !dayData.contains(where: { $0.date == todayString}) {
                initNewDay()
                lastLaunch = todayString
            }
        }
    }
    
    private func initNewDay() {
        let newDay = DayData(context: viewContext)
        newDay.date = todayString
        saveData()
    }
    
//    private func initializeMApp() {
//        let newMAppData = MAppData(context: viewContext)
//        newMAppData.doctorNotes = ""
//        newMAppData.customSymptoms = []
//        newMAppData.activityColors = [
//            getData(from: UIColor(Color.gray)) ?? Data(),
//            getData(from: UIColor(Color.red)) ?? Data(),
//            getData(from: UIColor(Color.yellow)) ?? Data(),
//            getData(from: UIColor(Color.green)) ?? Data(),
//        ]
//        newMAppData.launchDay = Calendar.current.startOfDay(for: .now)
//        
//        // Double check that it does not exist before saving
//        if !mAppData.contains(where: { $0.doctorNotes == "" }) {
//            saveData()
//        } else {
//            viewContext.delete(newMAppData)
//        }
//    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}
