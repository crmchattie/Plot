//
//  HourAxisValueFormatter.swift
//  Plot
//
//  Created by Botond Magyarosi on 16.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import Charts

public class HourAxisValueFormatter: NSObject, IAxisValueFormatter {
    
    private let formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        return formatter
    }()
    
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return formatter.string(from: value) ?? "-"
    }
}
