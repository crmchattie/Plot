//
//  DateRangeFormatter.swift
//  Plot
//
//  Created by Botond Magyarosi on 26.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation

let monthFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM"
    return formatter
}()

let dayMonthFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"
    return formatter
}()

struct DateRangeFormatter {
    let currentWeek: String
    let currentMonth: String
    let currentYear: String
    
    func format(range: DateRange) -> String {
        let current = Date()
        
        switch range.type {
        case .week:
            if range.startDate < current && range.endDate > current {
                return currentWeek
            }
            return dayMonthFormatter.string(from: range.startDate) + " - " + dayMonthFormatter.string(from: range.endDate)
        case .month:
            if range.startDate < current && range.endDate > current {
                return currentMonth
            }
            return monthFormatter.string(from: range.startDate) + " \(Calendar.current.component(.year, from: range.startDate))"
        case .year:
            if range.startDate < current && range.endDate > current {
                return currentYear
            }
            return "\(Calendar.current.component(.year, from: range.startDate))"
        }
    }
}
