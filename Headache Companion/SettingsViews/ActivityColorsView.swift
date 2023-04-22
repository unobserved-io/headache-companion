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
    @State private var notRecorded: Color = .gray
    @State private var lowColor: Color = .gray
    @State private var middleColor: Color = .gray
    @State private var highColor: Color = .gray
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
        .onAppear {
            notRecorded = Color(hex: mAppData.first?.activityColors?[0]) ?? Color.gray
            lowColor = Color(hex: mAppData.first?.activityColors?[1]) ?? Color.red
            middleColor = Color(hex: mAppData.first?.activityColors?[2]) ?? Color.yellow
            highColor = Color(hex: mAppData.first?.activityColors?[3]) ?? Color.green
        }
        .onDisappear {
            mAppData.first?.activityColors? = [
                notRecorded.hex ?? "8E8E93FF",
                lowColor.hex ?? "EB4E3DFF",
                middleColor.hex ?? "F7CE46FF",
                highColor.hex ?? "65C466FF"
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
            Button("Cancel", role: .cancel) {}
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
