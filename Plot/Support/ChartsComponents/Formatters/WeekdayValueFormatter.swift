//
//  WeekdayValueFormatter.swift
//  Plot
//
//  Created by Botond Magyarosi on 17.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import Charts

class WeekdayValueFormatter: IAxisValueFormatter {
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let intValue = Int(value)
        guard value >= 0, intValue < Calendar.current.veryShortWeekdaySymbols.count else {
            return "\(intValue)"
        }
        return Calendar.current.veryShortWeekdaySymbols[intValue]
    }
}
