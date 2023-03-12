//
//  StatsHelper.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/12/23.
//

import Foundation
import SwiftUI
import CoreData

class StatsHelper {
    func getAllData() -> [DayData] {
        let fetchRequest: NSFetchRequest<DayData> = DayData.fetchRequest()

        do {
            return try PersistenceController.shared.container.viewContext.fetch(fetchRequest)
        } catch {
            print("Failed to fetch movies: \(error)")
            return []
        }
    }
}
