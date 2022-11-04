//
//  WeekdayAxisValueFormatter.swift
//  Plot
//
//  Created by Botond Magyarosi on 17.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import Charts

class WeekdayAxisValueFormatter: AxisValueFormatter {
    
    let weekdaySymbols: [String] = {
        var weekDays = Calendar.current.veryShortWeekdaySymbols
        weekDays.shiftLeft(Calendar.current.firstWeekday - 1)
        return weekDays
    }()
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let intValue = Int(value)
        guard value >= 0, intValue < Calendar.current.veryShortWeekdaySymbols.count else {
            return "\(intValue)"
        }
        return weekdaySymbols[intValue]
    }
}
