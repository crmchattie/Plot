//
//  Activity.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 4/27/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

let activitiesEntity = "activities"
let userActivitiesEntity = "user-activities"

class Activity: NSObject, NSCopying, Codable {
    var activityID: String?
    var externalActivityID: String?
    var name: String?
    var calendarID: String?
    var calendarName: String?
    var calendarColor: String?
    var calendarSource: String?
    var activityType: String?
    var category: String?
    var activityDescription: String?
    var locationName: String?
    var locationAddress: [String : [Double]]?
    var participantsIDs: [String]?
    var transportation: String?
    var activityOriginalPhotoURL: String?
    var activityThumbnailPhotoURL: String?
    var activityPhotos: [String]?
    var activityFiles: [String]?
    var allDay: Bool?
    var startDateTime: NSNumber?
    var startTimeZone: String?
    var endDateTime: NSNumber?
    var endTimeZone: String?
    // A list of RFC-5545 (iCal) expressions.
    // https://tools.ietf.org/html/rfc5545
    //
    // Both Google and iCloud events are transfomed into this expression.
    var recurrences: [String]?
    var reminder: String?
    var notes: String?
    var checklistIDs: [String]?
    var activitylistIDs: [String]?
    var packinglistIDs: [String]?
    var grocerylistID: String?
    var isGroupActivity: Bool?
    var admin: String?
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?
    var containerID: String?
    var conversationID: String?
    var calendarExport: Bool?
    var showExtras: Bool?
    //task will key off of isTask and isComplete
    var isTask: Bool?
    var isComplete: Bool?
    var scheduleIDs: [String]?
    var isSchedule: Bool?
    
    enum CodingKeys: String, CodingKey {
        case activityID
        case externalActivityID
        case name
        case calendarID
        case calendarName
        case calendarColor
        case calendarSource
        case activityType
        case category
        case allDay
        case startTimeZone
        case endTimeZone
        case activityDescription
        case isGroupActivity
        case locationName
        case locationAddress
        case transportation
        case activityOriginalPhotoURL
        case activityThumbnailPhotoURL
        case reminder
        case recurrences
        case notes
        case checklistIDs
        case activitylistIDs
        case packinglistIDs
        case grocerylistID
        case containerID
        case calendarExport
        case showExtras
        case isComplete
        case isTask
        case isSchedule
        case scheduleIDs
    }
    
    init(activityID: String, admin: String, calendarID: String, calendarName: String, calendarColor: String, calendarSource: String, allDay: Bool, startDateTime: NSNumber, startTimeZone: String, endDateTime: NSNumber, endTimeZone: String) {
        self.activityID = activityID
        self.admin = admin
        self.calendarID = calendarID
        self.calendarName = calendarName
        self.calendarColor = calendarColor
        self.calendarSource = calendarSource
        self.allDay = allDay
        self.startDateTime = startDateTime
        self.startTimeZone = startTimeZone
        self.endDateTime = endDateTime
        self.endTimeZone = endTimeZone
    }
    
    init(dictionary: [String: AnyObject]?) {
        super.init()
        
        activityID = dictionary?["activityID"] as? String
        externalActivityID = dictionary?["externalActivityID"] as? String
        name = dictionary?["name"] as? String
        calendarID = dictionary?["calendarID"] as? String
        calendarName = dictionary?["calendarName"] as? String
        calendarColor = dictionary?["calendarColor"] as? String
        calendarSource = dictionary?["calendarSource"] as? String
        activityType = dictionary?["activityType"] as? String
        category = dictionary?["category"] as? String
        activityDescription = dictionary?["activityDescription"] as? String
        locationName = dictionary?["locationName"] as? String
        locationAddress = dictionary?["locationAddress"] as? [String : [Double]]
        
        if let participantsIDsDict = dictionary?["participantsIDs"] as? [String: String] {
            participantsIDs = Array(participantsIDsDict.keys)
        } else if let participantsIDsArray = dictionary?["participantsIDs"] as? [String] {
            participantsIDs = participantsIDsArray
        } else {
            participantsIDs = []
        }
        
        transportation = dictionary?["transportation"] as? String
        activityOriginalPhotoURL = dictionary?["activityOriginalPhotoURL"] as? String
        activityThumbnailPhotoURL = dictionary?["activityThumbnailPhotoURL"] as? String
        activityPhotos = dictionary?["activityPhotos"] as? [String]
        activityFiles = dictionary?["activityFiles"] as? [String]
        allDay = dictionary?["allDay"] as? Bool
        startDateTime = dictionary?["startDateTime"] as? NSNumber
        startTimeZone = dictionary?["startTimeZone"] as? String
        endDateTime = dictionary?["endDateTime"] as? NSNumber
        endTimeZone = dictionary?["endTimeZone"] as? String
        recurrences = dictionary?["recurrences"] as? [String]
        reminder = dictionary?["reminder"] as? String
        notes = dictionary?["notes"] as? String
        isGroupActivity = dictionary?["isGroupActivity"] as? Bool
        admin = dictionary?["admin"] as? String
        badge = dictionary?["badge"] as? Int
        pinned = dictionary?["pinned"] as? Bool
        muted = dictionary?["muted"] as? Bool
        conversationID = dictionary?["conversationID"] as? String
        grocerylistID = dictionary?["grocerylistID"] as? String
        checklistIDs = dictionary?["checklistIDs"] as? [String]
        activitylistIDs = dictionary?["activitylistIDs"] as? [String]
        packinglistIDs = dictionary?["packinglistIDs"] as? [String]
        calendarExport = dictionary?["calendarExport"] as? Bool
        containerID = dictionary?["containerID"] as? String
        showExtras = dictionary?["showExtras"] as? Bool
        isComplete = dictionary?["isComplete"] as? Bool
        isTask = dictionary?["isTask"] as? Bool
        isSchedule = dictionary?["isSchedule"] as? Bool
        scheduleIDs = dictionary?["scheduleIDs"] as? [String]
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Activity(dictionary: self.toAnyObject())
        return copy
    }
    
    func toAnyObject() -> [String: AnyObject] {
        var dictionary = [String: AnyObject]()
        if let value = self.activityID as AnyObject? {
            dictionary["activityID"] = value
        }
        
        if let value = self.externalActivityID as AnyObject? {
            dictionary["externalActivityID"] = value
        }
        
        if let value = self.name as AnyObject? {
            dictionary["name"] = value
        }
        
        if let value = self.admin as AnyObject? {
            dictionary["admin"] = value
        }
        
        if let value = self.calendarID as AnyObject? {
            dictionary["calendarID"] = value
        }
        
        if let value = self.calendarName as AnyObject? {
            dictionary["calendarName"] = value
        }
        
        if let value = self.calendarColor as AnyObject? {
            dictionary["calendarColor"] = value
        }
        
        if let value = self.calendarSource as AnyObject? {
            dictionary["calendarSource"] = value
        }
        
        if let value = self.activityType as AnyObject? {
            dictionary["activityType"] = value
        }
        
        if let value = self.category as AnyObject? {
            dictionary["category"] = value
        }
        
        if let value = self.activityDescription as AnyObject? {
            dictionary["activityDescription"] = value
        }
        
        if let value = self.locationName as AnyObject? {
            dictionary["locationName"] = value
        }
        
        if let value = self.locationAddress as AnyObject? {
            dictionary["locationAddress"] = value
        }
        
        if let value = self.participantsIDs as AnyObject? {
            dictionary["participantsIDs"] = value
        }
        
        if let value = self.transportation as AnyObject? {
            dictionary["transportation"] = value
        }
        
        if let value = self.activityOriginalPhotoURL as AnyObject? {
            dictionary["activityOriginalPhotoURL"] = value
        }
        
        if let value = self.activityThumbnailPhotoURL as AnyObject? {
            dictionary["activityThumbnailPhotoURL"] = value
        }
        
        if let value = self.activityPhotos as AnyObject? {
            dictionary["activityPhotos"] = value
        }
        
        if let value = self.activityFiles as AnyObject? {
            dictionary["activityFiles"] = value
        }
        
        if let value = self.allDay as AnyObject? {
            dictionary["allDay"] = value
        }
        
        if let value = self.startDateTime as AnyObject? {
            dictionary["startDateTime"] = value
        }
        
        if let value = self.startTimeZone as AnyObject? {
            dictionary["startTimeZone"] = value
        }
        
        if let value = self.endDateTime as AnyObject? {
            dictionary["endDateTime"] = value
        }
        
        if let value = self.recurrences as AnyObject? {
            dictionary["recurrences"] = value
        }
        
        if let value = self.endTimeZone as AnyObject? {
            dictionary["endTimeZone"] = value
        }
        
        if let value = self.notes as AnyObject? {
            dictionary["notes"] = value
        }
        
        if let value = self.conversationID as AnyObject? {
            dictionary["conversationID"] = value
        }
        
        if let value = self.grocerylistID as AnyObject? {
            dictionary["grocerylistID"] = value
        }
        
        if let value = self.checklistIDs as AnyObject? {
            dictionary["checklistIDs"] = value
        }
        
        if let value = self.activitylistIDs as AnyObject? {
            dictionary["activitylistIDs"] = value
        }
        
        if let value = self.packinglistIDs as AnyObject? {
            dictionary["packinglistIDs"] = value
        }
        
        if let value = self.containerID as AnyObject? {
            dictionary["containerID"] = value
        }
        
        if let value = self.showExtras as AnyObject? {
            dictionary["showExtras"] = value
        }
        
        if let value = self.isComplete as AnyObject? {
            dictionary["isComplete"] = value
        }
        
        if let value = self.isTask as AnyObject? {
            dictionary["isTask"] = value
        }
        
        if let value = self.isSchedule as AnyObject? {
            dictionary["isSchedule"] = value
        }
        
        if let value = self.scheduleIDs as AnyObject? {
            dictionary["scheduleIDs"] = value
        }
        
        return dictionary
    }
    
    static func == (lhs: Activity, rhs: Activity) -> Bool {
        return lhs.activityID == rhs.activityID
    }
}

enum CustomType: String, Equatable, Hashable {
    case basic, complex, meal, workout, event, flight, transaction, financialAccount, transactionRule, sleep, work, mood, iOSCalendarEvent, mindfulness, calendar, googleCalendarEvent, investment
    
    var name: String {
        switch self {
        case .basic: return "Event"
        case .complex: return "Complex"
        case .meal: return "Meal"
        case .workout: return "Workout"
        case .event: return "Event"
        case .flight: return "Flight"
        case .transaction: return "Transaction"
        case .financialAccount: return "Account"
        case .transactionRule: return "Transaction Rule"
        case .sleep: return "Sleep"
        case .work: return "Work"
        case .mood: return "Mood"
        case .iOSCalendarEvent: return "Apple Calendar Event"
        case .googleCalendarEvent: return "Google Calendar Event"
        case .mindfulness: return "Mindfulness"
        case .calendar: return "Calendar"
        case .investment: return "Investment"
        }
    }
    
    var categoryText: String {
        switch self {
        case .basic: return "Build your own basic event"
        case .complex: return "Build your own complex event"
        case .meal: return "Build your own meal"
        case .workout: return "Build your own workout"
        case .event: return "Build your own event"
        case .flight: return "Look up your flight"
        case .transaction: return "Create a transaction"
        case .financialAccount: return "Create a financial account"
        case .transactionRule: return "Create a transaction rule"
        case .sleep: return "Bedtime"
        case .work: return "Start of Work"
        case .mood: return "Add a mood"
        case .iOSCalendarEvent: return "Apple Calendar Event"
        case .googleCalendarEvent: return "Google Calendar Event"
        case .mindfulness: return "Add mindfulness minutes"
        case .calendar: return "Add new calendar"
        case .investment: return "Add new investment"
        }
    }
    
    var subcategoryText: String {
        switch self {
        case .basic: return "Includes basic calendar event fields"
        case .complex: return "Includes basic event fields plus a schedule, a checklist and purchases fields"
        case .meal: return "Build a meal by looking up grocery products and/or restaurant menu items"
        case .workout: return "Build a workout by setting type, duration and intensity"
        case .event: return ""
        case .flight: return "Look up your flight details based on flight number, airline or airport"
        case .sleep: return "Wake Up"
        case .work: return "End of Work"
        case .transaction, .financialAccount, .transactionRule, .mood, .iOSCalendarEvent, .mindfulness, .calendar, .googleCalendarEvent, .investment: return ""
        }
    }
    
    var image: String {
        switch self {
        case .basic: return "activityLarge"
        case .complex: return "activityLarge"
        case .meal: return "food"
        case .workout: return "workout"
        case .event: return "event"
        case .flight: return "plane"
        case .transaction: return "transaction"
        case .financialAccount: return "financialAccount"
        case .transactionRule: return "transactionRule"
        case .sleep: return "sleep"
        case .work: return "work"
        case .mood: return "mood"
        case .iOSCalendarEvent: return ""
        case .googleCalendarEvent: return ""
        case .mindfulness: return "mindfulness"
        case .calendar: return "calendar"
        case .investment: return "investment"
        }
    }
}

func categorizeActivities(activities: [Activity], start: Date, end: Date, completion: @escaping ([String: Double], [String: [Activity]]) -> ()) {
    var categoryDict = [String: Double]()
    var activitiesDict = [String: [Activity]]()
    var totalValue: Double = end.timeIntervalSince(start)
    // create dateFormatter with UTC time format
    for activity in activities {
        guard let activityStartDate = activity.startDateTime.map({ Date(timeIntervalSince1970: $0.doubleValue) }),
              let activityEndDate = activity.endDateTime.map({ Date(timeIntervalSince1970: $0.doubleValue) }) else { return }
        
        // Skipping activities that are outside of the interest range.
        if activityStartDate > end || activityEndDate <= start {
            continue
        }
        
        let duration = activityEndDate.timeIntervalSince1970 - activityStartDate.timeIntervalSince1970
        if let type = activity.category {
            guard type != "Not Applicable" else { continue }
            totalValue -= duration
            if categoryDict[type] == nil {
                categoryDict[type] = duration
                activitiesDict[type] = [activity]
            } else {
                let double = categoryDict[type]
                categoryDict[type] = double! + duration
                
                var activities = activitiesDict[type]
                activities!.append(activity)
                activitiesDict[type] = activities
            }
        } else {
            totalValue -= duration
            let type = "No Category"
            if categoryDict[type] == nil {
                categoryDict[type] = duration
                activitiesDict[type] = [activity]
            } else {
                let double = categoryDict[type]
                categoryDict[type] = double! + duration
                
                var activities = activitiesDict[type]
                activities!.append(activity)
                activitiesDict[type] = activities
            }
        }
    }
    categoryDict["No Activities"] = totalValue
    
    completion(categoryDict, activitiesDict)
}

func activitiesOverTimeChartData(activities: [Activity], activityCategories: [String], start: Date, end: Date, segmentType: TimeSegmentType, completion: @escaping ([String: [Statistic]], [String: [Activity]]) -> ()) {
    var statistics = [String: [Statistic]]()
    var activityDict = [String: [Activity]]()
    let calendar = Calendar.current
    var date = start
    
    let component: Calendar.Component = {
        switch segmentType {
        case .day: return .hour
        case .week: return .day
        case .month: return .day
        case .year: return .month
        }
    }()
    
    var nextDate = calendar.date(byAdding: component, value: 1, to: date)!
    while date < end {
        for activityCategory in activityCategories {
            if activityCategory == "No Activities" {
                continue
            }
            activityListStats(activities: activities, activityCategory: activityCategory, chunkStart: date, chunkEnd: nextDate) { (stats, activities) in
                if statistics[activityCategory] != nil, activityDict[activityCategory] != nil {
                    var acStats = statistics[activityCategory]
                    var acActivityList = activityDict[activityCategory]
                    acStats!.append(contentsOf: stats)
                    acActivityList!.append(contentsOf: activities)
                    statistics[activityCategory] = acStats
                    activityDict[activityCategory] = acActivityList
                } else {
                    statistics[activityCategory] = stats
                    activityDict[activityCategory] = activities
                }
            }
        }
        
        // Advance by one day:
        date = nextDate
        nextDate = calendar.date(byAdding: component, value: 1, to: nextDate)!
    }
    
    completion(statistics, activityDict)
}

/// Categorize a list of activities, filtering down to a specific chunk [chunkStart, chunkEnd]
/// - Parameters:
///   - activities: A list of activities to analize.
///   - activityCategory: no idea what this is.
///   - chunkStart: Start date in which the activities are split and categorized.
///   - chunkEnd: Start date in which the activities are split and categorized.
///   - completion: list of statistical elements and activities.
func activityListStats(
    activities: [Activity],
    activityCategory: String,
    chunkStart: Date,
    chunkEnd: Date,
    completion: @escaping ([Statistic], [Activity]) -> ()
) {
    var statistics = [Statistic]()
    var activityList = [Activity]()
    for activity in activities {
        guard var activityStartDate = activity.startDateTime.map({ Date(timeIntervalSince1970: $0.doubleValue) }),
              var activityEndDate = activity.endDateTime.map({ Date(timeIntervalSince1970: $0.doubleValue) }) else { return }
        
        // Skipping activities that are outside of the interest range.
        if activityStartDate >= chunkEnd || activityEndDate <= chunkStart {
            continue
        }
        
        // Truncate events that out of the [chunkStart, chunkEnd] range.
        // Multi-day events, chunked into single day `Statistic`s are the best example.
        if activityStartDate < chunkStart {
            activityStartDate = chunkStart
        }
        if activityEndDate > chunkEnd {
            activityEndDate = chunkEnd
        }
        
        if let type = activity.category, type == activityCategory {
            var duration: Double = 0
            if activity.allDay ?? false {
                duration = 1440
            } else {
                duration = (activityEndDate.timeIntervalSince1970 - activityStartDate.timeIntervalSince1970) / 60
            }
            if statistics.isEmpty {
                let stat = Statistic(date: chunkStart, value: duration)
                statistics.append(stat)
                activityList.append(activity)
            } else {
                if let index = statistics.firstIndex(where: { $0.date == chunkEnd }) {
                    statistics[index].value += duration
                    activityList.append(activity)
                }
            }
        }
    }
    completion(statistics, activityList)
}


extension Activity {
    var startDate: Date? {
        guard let startDateTime = startDateTime?.doubleValue else {
            return nil
        }
        
        return Date(timeIntervalSince1970: startDateTime)
    }
    
    var endDate: Date? {
        guard let endDateTime = endDateTime?.doubleValue else {
            return nil
        }
        
        return Date(timeIntervalSince1970: endDateTime)
    }
}

extension Activity {
    var startDateWTZ: Date? {
        guard let startDateTime = startDateTime?.doubleValue else {
            return nil
        }
        let timezone = TimeZone(identifier: startTimeZone ?? "UTC")!
        let timezoneOffset =  timezone.secondsFromGMT()
        let epochDate = startDateTime
        let timezoneEpochOffset = (epochDate + Double(timezoneOffset))
        return Date(timeIntervalSince1970: timezoneEpochOffset)
    }
    
    var endDateWTZ: Date? {
        guard let endDateTime = endDateTime?.doubleValue else {
            return nil
        }
        let timezone = TimeZone(identifier: endTimeZone ?? "UTC")!
        let timezoneOffset =  timezone.secondsFromGMT()
        let epochDate = endDateTime
        let timezoneEpochOffset = (epochDate + Double(timezoneOffset))
        return Date(timeIntervalSince1970: timezoneEpochOffset)
    }
}

func dateToGLTRDate(date: Date, allDay: Bool, timeZone: TimeZone?) -> GTLRCalendar_EventDateTime? {
    guard let timeZone = timeZone else {
        return nil
    }
    let gDate = GTLRCalendar_EventDateTime()
    if allDay {
        gDate.date = GTLRDateTime(date: date)
        gDate.timeZone = timeZone.identifier
    } else {
        gDate.dateTime = GTLRDateTime(date: date)
        gDate.timeZone = timeZone.identifier
    }
    return gDate
}

extension GTLRCalendar_Event {
    var startDate: Date? {
        guard let start = self.start else {
            return nil
        }
        var date = Date()
        if let startDate = start.dateTime {
            date = startDate.date
        } else if let startDate = start.date {
            date = startDate.date
        }
        return date
    }
    
    var endDate: Date? {
        guard let end = self.end else {
            return nil
        }
        var date = Date()
        if let endDate = end.dateTime {
            date = endDate.date
        } else if let endDate = end.date {
            date = endDate.date
        }
        return date
    }
}
