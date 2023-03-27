//
//  LoadingView.swift
//  Headache Companion
//
//  Created by Ricky Kresslein on 3/27/23.
//

import SwiftUI

struct LoadingView: View {
    @Environment(\.managedObjectContext) private var viewContext
//    @FetchRequest(entity: InitialSetup.entity(), sortDescriptors: [])
//    private var setups: FetchedResults<InitialSetup>
    var setups: [String] = []
    
    var body: some View {
        if !setups.isEmpty {
            MainView()
        } else {
//            Text("Loading...")
            ProgressView()
                .progressViewStyle(.circular)
                .onAppear() {
//                    print("DONE")
//                    let setup = InitialSetup(context: viewContext)
//                    setup.createdAt = Date()
//                    do {
//                        try viewContext.save()
//                    } catch {
//                        debugPrint("an error occurred saving initial setup: \(error.localizedDescription)")
//                    }
                }
        }
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}
