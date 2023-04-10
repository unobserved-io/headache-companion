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

let defaultHeadacheTypes: [String] = ["migraine", "tension", "other"]

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

//func headacheTypeString(_ type: Headaches) -> String {
//    switch type {
//    case .migraine:
//        return "Migraine"
//    case .tension:
//        return "Tension"
//    case .other:
//        return "Other"
//    }
//}

func medTypeString(_ type: MedTypes) -> String {
    switch type {
    case .preventive:
        return "Preventive"
    case .symptomRelieving:
        return "Symptom Relieving"
    case .other:
        return "Other"
    }
}
