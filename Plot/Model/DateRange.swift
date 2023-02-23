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
        case .month: return (Date().localTime.startOfDay.UTCTime.monthBefore.advanced(by: 86400), Date().localTime.startOfDay.UTCTime.advanced(by: 86399))
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
    
    var type: DateRangeType? {
        didSet {
            if let type = type {
                filterOff = true
                (startDate, endDate) = type.initial
            }
        }
    }
    
    private(set) var startDate: Date
    private(set) var endDate: Date
    //for saving prior start and end dates when filter is on
    private(set) var priorStartDate: Date?
    private(set) var priorEndDate: Date?
    //for grabbing last period start and end date for comparison
    private(set) var pastStartDate: Date?
    private(set) var pastEndDate: Date?
    
    var filterOff: Bool = true
    
    init(type: DateRangeType) {
        self.type = type
        (startDate, endDate) = type.initial
        switch type {
        case .week:
            pastStartDate = Calendar.current.date(byAdding: .day, value: -7, to: startDate)!
            pastEndDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
        case .month:
            pastStartDate = Calendar.current.date(byAdding: .month, value: -1, to: startDate)!
            pastEndDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate)!
        }
    }
    
    init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }
    
    mutating func next() {
        if !filterOff, let priorStartDate = priorStartDate, let priorEndDate = priorEndDate {
            startDate = priorStartDate
            endDate = priorEndDate
            filterOff = true
        }
        pastStartDate = startDate
        pastEndDate = endDate
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
        case .none:
            break
        }
    }
    
    mutating func previous() {
        if !filterOff, let priorStartDate = priorStartDate, let priorEndDate = priorEndDate {
            startDate = priorStartDate
            endDate = priorEndDate
            filterOff = true
        }
        switch type {
        case .week:
            startDate = Calendar.current.date(byAdding: .day, value: -7, to: startDate)!
            endDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
            pastStartDate = Calendar.current.date(byAdding: .day, value: -7, to: startDate)!
            pastEndDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
        case .month:
            startDate = Calendar.current.date(byAdding: .month, value: -1, to: startDate)!
            endDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate)!
            pastStartDate = Calendar.current.date(byAdding: .month, value: -1, to: startDate)!
            pastEndDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate)!
//        case .year:
//            startDate = Calendar.current.date(byAdding: .year, value: -1, to: startDate)!
//            endDate = Calendar.current.date(byAdding: .year, value: -1, to: endDate)!
        case .none:
            break
        }
    }
    
    mutating func filter(date: Date?) {
        if let date = date {
            if filterOff {
                priorStartDate = startDate
                priorEndDate = endDate
            }
            startDate = date.startOfDay
            endDate = date.endOfDay
            filterOff = false
        } else if let priorStartDate = priorStartDate, let priorEndDate = priorEndDate {
            startDate = priorStartDate
            endDate = priorEndDate
            filterOff = true
        }
    }
    
    func previousDatesForComparison() -> DateRange? {
        switch type {
        case .week:
            let startDate = Calendar.current.date(byAdding: .day, value: -7, to: startDate)!
            let endDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
            return DateRange(startDate: startDate, endDate: endDate)
        case .month:
            let startDate = Calendar.current.date(byAdding: .month, value: -1, to: startDate)!
            let endDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate)!
            return DateRange(startDate: startDate, endDate: endDate)
//        case .year:
//            startDate = Calendar.current.date(byAdding: .year, value: -1, to: startDate)!
//            endDate = Calendar.current.date(byAdding: .year, value: -1, to: endDate)!
        case .none:
            return nil
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
        case .none: return .week
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
