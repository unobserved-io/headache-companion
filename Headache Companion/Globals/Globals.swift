//
//  Globals.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/6/23.
//

import Foundation
import SwiftUI

/*
 COLOR HEX
 Gray: 8E8E93FF
 Red: EB4E3DFF
 Yellow: F7CE46FF
 Green: 65C466FF
 */

let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()

let defaultHeadacheTypes: [String] = ["migraine", "tension", "other"]

let defaultMedicationTypes: [String] = ["preventive", "symptom relieving", "other"]

func ??<T>(lhs: Binding<Optional<T>>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}

func saveData() {
    let viewContext = PersistenceController.shared.container.viewContext
//    print("NEW: \(viewContext.insertedObjects)")
    if viewContext.hasChanges {
        do {
            try viewContext.save()
        } catch {
            print("Error saving changes \(error)")
        }
    }
}

func initializeMAppData() {
    let viewContext = PersistenceController.shared.container.viewContext
    let newMAppData = MAppData(context: viewContext)
    newMAppData.doctorNotes = ""
    newMAppData.getsPeriod = false
    newMAppData.customSymptoms = []
    newMAppData.customAuras = []
    newMAppData.customHeadacheTypes = []
    newMAppData.customMedTypes = []
    newMAppData.customSideEffects = []
    newMAppData.activityColors = [
        getData(from: UIColor(Color.gray)) ?? Data(),
        getData(from: UIColor(Color.red)) ?? Data(),
        getData(from: UIColor(Color.yellow)) ?? Data(),
        getData(from: UIColor(Color.green)) ?? Data(),
    ]
    newMAppData.launchDay = Calendar.current.startOfDay(for: .now)
    saveData()
}

func getData(from color: UIColor) -> Data? {
    do {
        return try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
    } catch {
        print(error)
    }
    return nil
}

func getColor(from data: Data, default defaultColor: Color) -> Color {
    do {
        return try Color(NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data)!)
    } catch {
        print(error)
    }

    return defaultColor
}
