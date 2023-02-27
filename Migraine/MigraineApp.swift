//
//  MigraineApp.swift
//  Migraine
//
//  Created by Ricky Kresslein on 2/27/23.
//

import SwiftUI

@main
struct MigraineApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
