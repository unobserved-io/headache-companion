//
//  Globals.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/6/23.
//

import Foundation
import SwiftUI

let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()

let defaultHeadacheTypes: [String] = [
    String(localized: "migraine"),
    String(localized: "tension"),
    String(localized: "other")
]

let defaultMedicationTypes: [String] = [
    String(localized: "preventive"),
    String(localized: "symptom relieving"),
    String(localized: "migraine")
]

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
        "8E8E93FF", // Gray
        "EB4E3DFF", // Red
        "F7CE46FF", // Yellow
        "65C466FF", // Green
    ]
    newMAppData.launchDay = Calendar.current.startOfDay(for: .now)
    saveData()
}
