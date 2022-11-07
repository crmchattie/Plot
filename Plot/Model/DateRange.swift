//
//  DateRange.swift
//  Plot
//
//  Created by Botond Magyarosi on 26.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import Charts

enum DateRangeType: CaseIterable {
    case week, month
//         year
    
    var initial: (Date, Date) {
        switch self {
        case .week: return (Date().localTime.startOfDay.UTCTime.weekBefore.advanced(by: 86400), Date().localTime.startOfDay.UTCTime.advanced(by: 86399))
        case .month: return (Date().monthBefore, Date().localTime)
//        case .year: return (Date().yearBefore, Date())
        }
    }
    
    var filterTitle: String {
        switch self {
        case .week: return "Weekly"
        case .month: return "Monthly"
//        case .year: return "Yearly"
        }
    }
}

struct DateRange {
    
    var type: DateRangeType {
        didSet {
            (startDate, endDate) = type.initial
        }
    }
    
    private(set) var startDate: Date
    private(set) var endDate: Date
    
    init(type: DateRangeType) {
        self.type = type
        (startDate, endDate) = type.initial
    }
    
    mutating func next() {
        switch type {
        case .week:
            startDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
            endDate = Calendar.current.date(byAdding: .day, value: 7, to: endDate)!
        case .month:
            startDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate)!
            endDate = Calendar.current.date(byAdding: .month, value: 1, to: endDate)!
//        case .year:
//            startDate = Calendar.current.date(byAdding: .year, value: 1, to: startDate)!
//            endDate = Calendar.current.date(byAdding: .year, value: 1, to: endDate)!
        }
    }
    
    mutating func previous() {
        switch type {
        case .week:
            startDate = Calendar.current.date(byAdding: .day, value: -7, to: startDate)!
            endDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
        case .month:
            startDate = Calendar.current.date(byAdding: .month, value: -1, to: startDate)!
            endDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate)!
//        case .year:
//            startDate = Calendar.current.date(byAdding: .year, value: -1, to: startDate)!
//            endDate = Calendar.current.date(byAdding: .year, value: -1, to: endDate)!
        }
    }
    
    var daysInRange: Int {
        endDate.daysSince(startDate)
    }
    
    var timeSegment: TimeSegmentType {
        switch type {
        case .week: return .week
        case .month: return .month
//        case .year: return .year
        }
    }
}

private extension Date {
    
    var mStart: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components)!
    }

    var mEnd: Date {
        Calendar.current.date(byAdding: DateComponents(month: 1, second: -1), to: mStart)!
    }
    
    var yStart: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: self)
        return calendar.date(from: components)!
    }

    var yEnd: Date {
        Calendar.current.date(byAdding: DateComponents(year: 1, second: -1), to: yStart)!
    }
    
    var wStart: Date {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))!
    }
    
    var wEnd: Date {
        Calendar.current.date(byAdding: DateComponents(day: 7, second: -1), to: wStart)!
    }
}
