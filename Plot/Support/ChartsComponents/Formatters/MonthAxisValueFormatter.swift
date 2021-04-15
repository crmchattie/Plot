//
//  MonthAxisValueFormatter.swift
//  Plot
//
//  Created by Botond Magyarosi on 31.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import Charts

class MonthAxisValueFormatter: IAxisValueFormatter {
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let intValue = Int(value)
        guard value >= 0, intValue < Calendar.current.veryShortMonthSymbols.count else {
            return "\(intValue)"
        }
        return Calendar.current.veryShortMonthSymbols[intValue]
    }
}
