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
    
    var body: some View {
        List {
            Section(header: Text("Calendar")) {
                Toggle("Activities", isOn: $trackActivities)
            }
        }
    }
}

struct ChooseAnalyticsDataPointsView_Previews: PreviewProvider {
    static var previews: some View {
        ChooseAnalyticsDataPointsView()
    }
}
