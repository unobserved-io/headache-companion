//
//  Globals.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/6/23.
//

import Foundation
import SwiftUI

func ??<T>(lhs: Binding<Optional<T>>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}

func saveData() {
    let viewContext = PersistenceController.shared.container.viewContext
    if viewContext.hasChanges {
        do {
            try viewContext.save()
        } catch {
            print("Error saving changes \(error)")
        }
    }
}

//func activityColor(of i: ActivityRanks) -> Color {
//    switch i {
//    case .none:
//        return Color.gray
//    case .bad:
//        return Color.red
//    case .ok:
//        return Color.yellow
//    case .good:
//        return Color.green
//    default:
//        return Color.gray
//    }
//}

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
