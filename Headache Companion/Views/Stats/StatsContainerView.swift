//
//  StatsContainerView.swift
//  Headache Companion
//
//  Created by Ricky Kresslein on 5/12/23.
//

import SwiftUI

struct StatsContainerView: View {
    private enum ViewChoice: String {
        case stats
        case medicationHistory
    }
    @State private var viewChoice: ViewChoice = .stats
    
    var body: some View {
        NavigationStack {
            Picker("", selection: $viewChoice) {
                Text("Stats").tag(ViewChoice.stats)
                Text("Medication History").tag(ViewChoice.medicationHistory)
            }
            .pickerStyle(.segmented)
            .padding()
            
            TabView(selection: $viewChoice) {
                StatsView()
                    .tag(ViewChoice.stats)
                
                MedicationHistoryView()
                    .tag(ViewChoice.medicationHistory)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeIn, value: viewChoice)
        }
        .scrollContentBackground(.hidden)
        .onAppear {
            // Reset segmented pickers to be even (Necessary for long languages)
            UISegmentedControl.appearance().apportionsSegmentWidthsByContent = false
        }
    }
}

struct StatsContainerView_Previews: PreviewProvider {
    static var previews: some View {
        StatsContainerView()
    }
}
