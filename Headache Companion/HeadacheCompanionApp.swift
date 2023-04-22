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
    @ObservedObject var storeModel = StoreModel.sharedInstance

    var body: some Scene {
        WindowGroup {
            LoadingView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    Task {
                        try await storeModel.fetchProducts()
                    }
                }
        }
    }
}
