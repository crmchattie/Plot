//
//  Template.swift
//  Plot
//
//  Created by Cory McHattie on 9/27/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import Foundation
import RRuleSwift

let templateEntity = "templates"

struct Template: Codable, Equatable, Hashable {
    var name: String
    var object: ObjectType
    var category: ActivityCategory
    var subcategory: ActivitySubcategory
    var type: String
    var frequency: PlotRecurrenceFrequency?
    var interval: Int?
    var description: String?
    var order: Int?
    var subtemplates: [Template]?
    var dateType: DateType?
    var startYearAbsolute: Int?
    var startMonthAbsolute: Int?
    var startDayAbsolute: Int?
    var startHourAbsolute: Int?
    var startMinuteAbsolute: Int?
    var startSecondAbsolute: Int?
    var endYearAbsolute: Int?
    var endMonthAbsolute: Int?
    var endDayAbsolute: Int?
    var endHourAbsolute: Int?
    var endMinuteAbsolute: Int?
    var endSecondAbsolute: Int?
    var startYearRelative: Int?
    var startMonthRelative: Int?
    var startDayRelative: Int?
    var startHourRelative: Int?
    var startMinuteRelative: Int?
    var startSecondRelative: Int?
    var endYearRelative: Int?
    var endMonthRelative: Int?
    var endDayRelative: Int?
    var endHourRelative: Int?
    var endMinuteRelative: Int?
    var endSecondRelative: Int?
    
    func getStartDate() -> Date? {
        let original = Date()
        var date = Date(timeIntervalSinceReferenceDate:
                            (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
        switch self.dateType {
        case .absolute:
            var dateComponents = DateComponents()
            dateComponents.timeZone = TimeZone.current
            dateComponents.year = self.startYearAbsolute ?? date.yearNumber()
            dateComponents.month = self.startMonthAbsolute ?? date.monthNumber()
            dateComponents.day = self.startDayAbsolute ?? date.dayNumber()
            dateComponents.hour = self.startHourAbsolute ?? date.hourNumber()
            dateComponents.minute = self.startMinuteRelative ?? date.minuteNumber()
            dateComponents.minute = self.startSecondRelative ?? date.secondNumber()
            let calendar = Calendar.current
            date = calendar.date(from: dateComponents) ?? Date()
        case .relative:
            date = Calendar.current.date(byAdding: .year, value: self.startYearRelative ?? 0, to: date) ?? Date()
            date = Calendar.current.date(byAdding: .month, value: self.startMonthRelative ?? 0, to: date) ?? Date()
            date = Calendar.current.date(byAdding: .day, value: self.startDayRelative ?? 0, to: date) ?? Date()
            date = Calendar.current.date(byAdding: .hour, value: self.startHourRelative ?? 0, to: date) ?? Date()
            date = Calendar.current.date(byAdding: .minute, value: self.startMinuteRelative ?? 0, to: date) ?? Date()
            date = Calendar.current.date(byAdding: .second, value: self.startSecondRelative ?? 0, to: date) ?? Date()
        case .none:
            if self.object == .event || self.object == .schedule || self.object == .workout || self.frequency != nil {
                return date
            }
            return nil
        }
        return date
    }
    
    func getEndDate() -> Date? {
        let original = Date()
        var date = Date(timeIntervalSinceReferenceDate:
                            (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
        switch self.dateType {
        case .absolute:
            var dateComponents = DateComponents()
            dateComponents.timeZone = TimeZone.current
            dateComponents.year = self.endYearAbsolute ?? date.yearNumber()
            dateComponents.month = self.endMonthAbsolute ?? date.monthNumber()
            dateComponents.day = self.endDayAbsolute ?? date.dayNumber()
            dateComponents.hour = self.endHourAbsolute ?? date.hourNumber()
            dateComponents.minute = self.endMinuteRelative ?? date.minuteNumber()
            dateComponents.minute = self.endSecondRelative ?? date.secondNumber()
            let calendar = Calendar.current
            date = calendar.date(from: dateComponents) ?? Date()
        case .relative:
            date = Calendar.current.date(byAdding: .year, value: self.endYearRelative ?? 0, to: date) ?? Date()
            date = Calendar.current.date(byAdding: .month, value: self.endMonthRelative ?? 0, to: date) ?? Date()
            date = Calendar.current.date(byAdding: .day, value: self.endDayRelative ?? 0, to: date) ?? Date()
            date = Calendar.current.date(byAdding: .hour, value: self.endHourRelative ?? 0, to: date) ?? Date()
            date = Calendar.current.date(byAdding: .minute, value: self.endMinuteRelative ?? 0, to: date) ?? Date()
            date = Calendar.current.date(byAdding: .second, value: self.endSecondRelative ?? 0, to: date) ?? Date()
        case .none:
            if self.object == .event || self.object == .schedule || self.object == .workout || self.frequency != nil {
                return date
            }
            return nil
        }
        return date
    }
}

enum ObjectType: String, Codable, CaseIterable {
    case event = "Event"
    case task = "Task"
    case subtask = "Subtask"
    case workout = "Workout"
    case schedule = "Schedule"
}

enum PlotRecurrenceFrequency: String, Codable {
    case yearly = "YEARLY"
    case monthly = "MONTHLY"
    case weekly = "WEEKLY"
    case daily = "DAILY"
    case hourly = "HOURLY"
    case minutely = "MINUTELY"
    case secondly = "SECONDLY"
    
    func toString() -> String {
        switch self {
        case .secondly: return "SECONDLY"
        case .minutely: return "MINUTELY"
        case .hourly: return "HOURLY"
        case .daily: return "DAILY"
        case .weekly: return "WEEKLY"
        case .monthly: return "MONTHLY"
        case .yearly: return "YEARLY"
        }
    }
    
    var recurrenceFrequency: RecurrenceFrequency? {
        switch self {
        case .secondly: return .secondly
        case .minutely: return .minutely
        case .hourly: return .hourly
        case .daily: return .daily
        case .weekly: return .weekly
        case .monthly: return .monthly
        case .yearly: return .yearly
        }
    }
}

enum DateType: String, Codable, CaseIterable {
    case absolute = "Absolute"
    case relative = "Relative"
}
