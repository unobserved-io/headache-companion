//
//  MigraineApp.swift
//  Migraine
//
//  Created by Ricky Kresslein on 2/27/23.
//

import SwiftUI

@main
struct HeadacheCompanionApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            LoadingView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
