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
    var category: ActivityCategory?
    var subcategory: ActivitySubcategory?
    var type: String?
    var frequency: PlotRecurrenceFrequency?
    var interval: Int?
    var description: String?
    var order: Int?
    var mood: MoodType?
    var isCompleted: Bool?
    var subtemplates: [Template]?
    var dateType: DateType?
    var totalEnergyBurned: Double?
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
            dateComponents.year = self.startYearAbsolute ?? date.yearNumber()
            dateComponents.month = self.startMonthAbsolute ?? date.monthNumber()
            dateComponents.day = self.startDayAbsolute ?? date.dayNumber()
            dateComponents.hour = self.startHourAbsolute ?? date.hourNumber()
            dateComponents.minute = self.startMinuteAbsolute ?? date.minuteNumber()
            dateComponents.second = self.startSecondAbsolute ?? date.secondNumber()
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
            dateComponents.year = self.endYearAbsolute ?? date.yearNumber()
            dateComponents.month = self.endMonthAbsolute ?? date.monthNumber()
            dateComponents.day = self.endDayAbsolute ?? date.dayNumber()
            dateComponents.hour = self.endHourAbsolute ?? date.hourNumber()
            dateComponents.minute = self.endMinuteAbsolute ?? date.minuteNumber()
            dateComponents.second = self.endSecondAbsolute ?? date.secondNumber()
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
    case goal = "Goal"
    case subtask = "Subtask"
    case workout = "Workout"
    case mindfulness = "Mindfulness"
    case mood = "Mood"
    case schedule = "Schedule"
    case transaction = "Transaction"
    case account = "Account"
}

enum PlotRecurrenceFrequency: String, Codable {
    case yearly = "YEARLY"
    case monthly = "MONTHLY"
    case bimonthly = "BIMONTHLY"
    case weekly = "WEEKLY"
    case biweekly = "BIWEEKLY"
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
        case .bimonthly: return "BIMONTHLY"
        case .biweekly: return "BIWEEKLY"
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
        case .bimonthly: return .none
        case .biweekly: return .none
        }
    }
    
    var name: String {
        switch self {
        case .secondly: return "Secondly"
        case .minutely: return "Minutely"
        case .hourly: return "Hourly"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .bimonthly: return "Bimonthly"
        case .biweekly: return "Biweekly"
        }
    }
    
    var dayInterval: Int {
        switch self {
        case .secondly, .minutely, .hourly: return 0
        case .daily: return 1
        case .weekly: return 7
        case .biweekly: return 14
        case .bimonthly: return 15
        case .monthly: return 30
        case .yearly: return 365
        }
    }
    
    var errorDayInterval: Int {
        switch self {
        case .secondly, .minutely, .hourly, .daily: return 0
        case .weekly, .biweekly, .bimonthly: return 2
        case .monthly: return 3
        case .yearly: return 5
        }
    }
    
    
}

enum DateType: String, Codable, CaseIterable {
    case absolute = "Absolute"
    case relative = "Relative"
}

class TemplateBuilder {
    class func createActivity(from task: Activity, metric: GoalMetric, unit: GoalUnit, target: Double, submetric: GoalSubMetric?, option: String?) -> Template? {
        guard let name = task.name, var startDate = task.startDate, let object = metric.objectType else {
            return nil
        }
        
        var template = Template(name: name, object: object)
        
        switch object {
        case .event:
            switch submetric {
            case .category:
                if let option = option {
                    template.category = ActivityCategory(rawValue: option)
                    template.subcategory = ActivityCategory(rawValue: option)?.subcategory ?? .uncategorized
                }
            case .subcategory:
                if let option = option {
                    template.category = ActivitySubcategory(rawValue: option)?.category ?? .uncategorized
                    template.subcategory = ActivitySubcategory(rawValue: option)
                }
            case .some(.none), .some(.group), .specific:
                break
            case nil:
                break
            }
        case .task:
            switch submetric {
            case .category:
                if let option = option {
                    template.category = ActivityCategory(rawValue: option)
                    template.subcategory = ActivityCategory(rawValue: option)?.subcategory ?? .uncategorized
                }
            case .subcategory:
                if let option = option {
                    template.category = ActivitySubcategory(rawValue: option)?.category ?? .uncategorized
                    template.subcategory = ActivitySubcategory(rawValue: option)
                }
            case .some(.none), .some(.group), .specific:
                break
            case nil:
                break
            }
        case .workout:
            switch submetric {
            case .category:
                if let option = option {
                    template.name = option
                }
            case .subcategory, .some(.none), .some(.group), .specific:
                template.name = "Running"
            case nil:
                template.name = "Running"
            }
        case .mood:
            switch submetric {
            case .category:
                if let option = option {
                    template.mood = MoodType(rawValue: option)
                }
            case .subcategory, .some(.none), .some(.group), .specific:
                break
            case nil:
                break
            }
        case .mindfulness, .goal, .subtask, .schedule, .transaction, .account:
            break
        }
        
        switch unit {
        case .calories:
            template.totalEnergyBurned = target
            startDate = startDate.addHours(12)
            template.dateType = .absolute
            template.startYearAbsolute = startDate.yearNumber()
            template.startMonthAbsolute = startDate.monthNumber()
            template.startDayAbsolute = startDate.dayNumber()
            template.startHourAbsolute = Date().hourNumber()
            template.startMinuteAbsolute = Date().minuteNumber()
            template.startSecondAbsolute = 0
            
            template.startYearAbsolute = startDate.yearNumber()
            template.startMonthAbsolute = startDate.monthNumber()
            template.startDayAbsolute = startDate.dayNumber()
            template.startHourAbsolute = Date().hourNumber()
            template.startMinuteAbsolute = Date().minuteNumber()
            template.startSecondAbsolute = 0
        case .minutes:
            startDate = startDate.addHours(12)
            template.dateType = .absolute
            template.startYearAbsolute = startDate.yearNumber()
            template.startMonthAbsolute = startDate.monthNumber()
            template.startDayAbsolute = startDate.dayNumber()
            template.startHourAbsolute = startDate.hourNumber()
            template.startMinuteAbsolute = startDate.minuteNumber()
            template.startSecondAbsolute = 0
            
            template.endYearAbsolute = startDate.addingTimeInterval(target * 60).yearNumber()
            template.endMonthAbsolute = startDate.addingTimeInterval(target * 60).monthNumber()
            template.endDayAbsolute = startDate.addingTimeInterval(target * 60).dayNumber()
            template.endHourAbsolute = startDate.addingTimeInterval(target * 60).hourNumber()
            template.endMinuteAbsolute = startDate.addingTimeInterval(target * 60).minuteNumber()
            template.endSecondAbsolute = 0
        case .hours:
            startDate = startDate.addHours(12)
            template.dateType = .absolute
            template.startYearAbsolute = startDate.yearNumber()
            template.startMonthAbsolute = startDate.monthNumber()
            template.startDayAbsolute = startDate.dayNumber()
            template.startHourAbsolute = startDate.hourNumber()
            template.startMinuteAbsolute = startDate.minuteNumber()
            template.startSecondAbsolute = 0
            
            template.endYearAbsolute = startDate.addHours(Int(target)).yearNumber()
            template.endMonthAbsolute = startDate.addHours(Int(target)).monthNumber()
            template.endDayAbsolute = startDate.addHours(Int(target)).dayNumber()
            template.endHourAbsolute = startDate.addHours(Int(target)).hourNumber()
            template.endMinuteAbsolute = startDate.addHours(Int(target)).minuteNumber()
            template.endSecondAbsolute = 0
        case .days:
            template.dateType = .absolute
            template.startYearAbsolute = startDate.yearNumber()
            template.startMonthAbsolute = startDate.monthNumber()
            template.startDayAbsolute = startDate.dayNumber()
            template.startHourAbsolute = startDate.hourNumber()
            template.startMinuteAbsolute = startDate.minuteNumber()
            template.startSecondAbsolute = 0
            
            template.endYearAbsolute = startDate.addDays(Int(target)).yearNumber()
            template.endMonthAbsolute = startDate.addDays(Int(target)).monthNumber()
            template.endDayAbsolute = startDate.addDays(Int(target)).dayNumber()
            template.endHourAbsolute = startDate.addDays(Int(target)).hourNumber()
            template.endMinuteAbsolute = startDate.addDays(Int(target)).minuteNumber()
            template.endSecondAbsolute = 0
        case .count, .amount, .percent, .multiple, .level:
            startDate = startDate.addHours(12)
            template.dateType = .absolute
            template.startYearAbsolute = startDate.yearNumber()
            template.startMonthAbsolute = startDate.monthNumber()
            template.startDayAbsolute = startDate.dayNumber()
            template.startHourAbsolute = Date().hourNumber()
            template.startMinuteAbsolute = Date().minuteNumber()
            template.startSecondAbsolute = 0
            
            template.endYearAbsolute = startDate.yearNumber()
            template.endMonthAbsolute = startDate.monthNumber()
            template.endDayAbsolute = startDate.dayNumber()
            template.endHourAbsolute = Date().hourNumber()
            template.endMinuteAbsolute = Date().minuteNumber()
            template.endSecondAbsolute = 0
        }
        return template
    }
}
