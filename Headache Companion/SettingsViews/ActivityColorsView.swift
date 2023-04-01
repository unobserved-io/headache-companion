//
//  ActivityColorsView.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/19/23.
//

import SwiftUI

struct ActivityColorsView: View {
    @FetchRequest(
        entity: MAppData.entity(),
        sortDescriptors: []
    )
    var mAppData: FetchedResults<MAppData>
    @State private var notRecorded: Color = Color.gray
    @State private var lowColor: Color = Color.gray
    @State private var middleColor: Color = Color.gray
    @State private var highColor: Color = Color.gray
    @State private var showingAlert: Bool = false
    
    var body: some View {
        List {
            Section {
                ColorPicker("Not recorded", selection: $notRecorded)
                ColorPicker("Bad", selection: $lowColor)
                ColorPicker("OK", selection: $middleColor)
                ColorPicker("Good", selection: $highColor)
            }
            Section {
                Button("Reset to defaults") {
                    showingAlert.toggle()
                }
            }
        }
        .onAppear() {
            notRecorded = getColor(from: mAppData.first?.activityColors?[0] ?? Data(), default: Color.gray)
            lowColor = getColor(from: mAppData.first?.activityColors?[1] ?? Data(), default: Color.red)
            middleColor = getColor(from: mAppData.first?.activityColors?[2] ?? Data(), default: Color.yellow)
            highColor = getColor(from: mAppData.first?.activityColors?[3] ?? Data(), default: Color.green)
        }
        .onDisappear() {
            mAppData.first?.activityColors? = [
                getData(from: UIColor(notRecorded)) ?? Data(),
                getData(from: UIColor(lowColor)) ?? Data(),
                getData(from: UIColor(middleColor)) ?? Data(),
                getData(from: UIColor(highColor)) ?? Data()
            ]
            saveData()
        }
        .alert("Reset?", isPresented: $showingAlert) {
            Button("Reset") {
                notRecorded = Color.gray
                lowColor = Color.red
                middleColor = Color.yellow
                highColor = Color.green
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to reset all colors to defaults?")
        }
    }
}

struct ActivityColorsView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityColorsView()
    }
}
