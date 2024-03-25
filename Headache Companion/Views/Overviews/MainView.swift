//
//  MainView.swift
//  Migraine
//
//  Created by Ricky Kresslein on 3/7/23.
//

import SwiftUI

struct MainView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label(String(localized: "Home"), systemImage: "house")
                }

            CalendarView()
                .tabItem {
                    Label("History", systemImage: "calendar")
                }

            StatsContainerView()
                .tabItem {
                    Label("Stats", systemImage: "chart.line.uptrend.xyaxis")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
