//
//  ChooseAnalyticsDataPointsView.swift
//  Plot
//
//  Created by Botond Magyarosi on 31.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import SwiftUI

struct ChooseAnalyticsDataPointsView: View {
    @SwiftUI.State private var trackActivities = true
    @SwiftUI.State private var trackEnergy = true
    @SwiftUI.State private var trackCashFlow = true
    @SwiftUI.State private var trackNetWorth = true
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Calendar")) {
                    Toggle("Activities", isOn: $trackActivities)
                }
                Section(header: Text("Health")) {
                    Toggle("Energy", isOn: $trackEnergy)
                }
                Section(header: Text("Finance")) {
                    Toggle("Cash flow", isOn: $trackCashFlow)
                    Toggle("Net worth", isOn: $trackNetWorth)
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle(Text("Data points"))
        }
    }
}

struct ChooseAnalyticsDataPointsView_Previews: PreviewProvider {
    static var previews: some View {
        ChooseAnalyticsDataPointsView()
    }
}
