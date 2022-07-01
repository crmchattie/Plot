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

let userActivityCategoriesEntity = "user-activities-categories"

class Activity: NSObject, NSCopying, Codable {
    var activityID: String?
    var name: String?
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
    var schedule: [Activity]?
    var purchases: [Purchase]?
    var checklist: [Checklist]?
    var packinglist: [Packinglist]?
    var grocerylist: Grocerylist?
    var checklistIDs: [String]?
    var activitylistIDs: [String]?
    var packinglistIDs: [String]?
    var transactionIDs: [String]?
    var grocerylistID: String?
    var isGroupActivity: Bool?
    var admin: String?
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?
    var conversationID: String?
    var calendarExport: Bool?
    var recipeID: String?
    var servings: Int?
    var workoutID: String?
    var eventID: String?
    var placeID: String?
    var attractionID: String?
    var showExtras: Bool?
    var hkSampleID: String?
    var completed: Bool?
    
    enum CodingKeys: String, CodingKey {
        case name
        case activityType
        case category
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
        case schedule
        case purchases
        case checklist
        case packinglist
        case grocerylist
        case checklistIDs
        case activitylistIDs
        case packinglistIDs
        case grocerylistID
        case transactionIDs
        case calendarExport
        case recipeID
        case servings
        case workoutID
        case eventID
        case attractionID
        case placeID
        case showExtras
        case completed
        case hkSampleID
    }
    
    init(dictionary: [String: AnyObject]?) {
        super.init()
        
        activityID = dictionary?["activityID"] as? String
        name = dictionary?["name"] as? String
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
        
        if let scheduleFirebaseList = dictionary?["schedule"] as? [AnyObject] {
            var scheduleList = [Activity]()
            for schedule in scheduleFirebaseList {
                let sche = Activity(dictionary: schedule as? [String : AnyObject])
                if sche.name == "nothing" { continue }
                scheduleList.append(sche)
            }
            schedule = scheduleList
        }
        
        if let purchasesFirebaseList = dictionary?["purchases"] as? [AnyObject] {
            var purchasesList = [Purchase]()
            for purchase in purchasesFirebaseList {
                let purch = Purchase(dictionary: purchase as? [String : AnyObject])
                if purch.name == "nothing" { continue }
                purchasesList.append(purch)
            }
            purchases = purchasesList
        }
        
        if let checklistFirebaseList = dictionary?["checklist"] as? [Any] {
            var checklistList = [Checklist]()
            for checklist in checklistFirebaseList {
                if let check = try? FirebaseDecoder().decode(Checklist.self, from: checklist) {
                    if check.name == "nothing" { continue }
                    checklistList.append(check)
                }
            }
            checklist = checklistList
        } else if let items = dictionary?["checklist"] as? [String : [String : Bool]] {
            let check = Checklist(dictionary: ["name": "Checklist" as AnyObject])
            var checklistItems = [String: Bool]()
            for item in items.values {
                checklistItems[item.keys.first!] = item.values.first
            }
            check.items = checklistItems
            checklist = [check]
        }
        
        if let packinglistFirebaseList = dictionary?["packinglist"] as? [Any] {
            var packinglistList = [Packinglist]()
            for packinglist in packinglistFirebaseList {
                if let pack = try? FirebaseDecoder().decode(Packinglist.self, from: packinglist) {
                    if pack.name == "nothing" { continue }
                    packinglistList.append(pack)
                }
            }
            packinglist = packinglistList
        }
        
        if let grocerylist = try? FirebaseDecoder().decode(Grocerylist.self, from: dictionary?["grocerylist"] as Any) {
            self.grocerylist = grocerylist
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
        transactionIDs = dictionary?["transactionIDs"] as? [String]
        calendarExport = dictionary?["calendarExport"] as? Bool
        recipeID = dictionary?["recipeID"] as? String
        servings = dictionary?["servings"] as? Int
        workoutID = dictionary?["workoutID"] as? String
        eventID = dictionary?["eventID"] as? String
        attractionID = dictionary?["attractionID"] as? String
        placeID = dictionary?["placeID"] as? String
        showExtras = dictionary?["showExtras"] as? Bool
        completed = dictionary?["completed"] as? Bool
        hkSampleID = dictionary?["hkSampleID"] as? String
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
        
        if let value = self.name as AnyObject? {
            dictionary["name"] = value
        }
        
        if let value = self.admin as AnyObject? {
            dictionary["admin"] = value
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
        
        if let value = self.schedule {
            var firebaseScheduleList = [[String: AnyObject?]]()
            for schedule in value {
                let firebaseSchedule = schedule.scheduleToAnyObject()
                firebaseScheduleList.append(firebaseSchedule)
            }
            dictionary["schedule"] = firebaseScheduleList as AnyObject
        }
        
        if let value = self.purchases {
            var firebasePurchasesList = [[String: AnyObject?]]()
            for purchase in value {
                let firebasePurchases = purchase.toAnyObject()
                firebasePurchasesList.append(firebasePurchases)
            }
            dictionary["purchases"] = firebasePurchasesList as AnyObject
        }
        
        if let value = self.checklist {
            var firebaseChecklistList = [[String: AnyObject?]]()
            for checklist in value {
                let firebaseChecklist = checklist.toAnyObject()
                firebaseChecklistList.append(firebaseChecklist)
            }
            dictionary["checklist"] = firebaseChecklistList as AnyObject
        }
        
        if let value = self.packinglist {
            var firebasePackinglistList = [[String: AnyObject?]]()
            for packinglist in value {
                let firebasePackinglist = packinglist.toAnyObject()
                firebasePackinglistList.append(firebasePackinglist)
            }
            dictionary["packinglist"] = firebasePackinglistList as AnyObject
        }
        
        if let value = self.grocerylist {
            let firebase = value.toAnyObject()
            dictionary["grocerylist"] = firebase as AnyObject
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
        
        if let value = self.transactionIDs as AnyObject? {
            dictionary["transactionIDs"] = value
        }
        
        if let value = self.recipeID as AnyObject? {
            dictionary["recipeID"] = value
        }
        
        if let value = self.servings as AnyObject? {
            dictionary["servings"] = value
        }
        
        if let value = self.workoutID as AnyObject? {
            dictionary["workoutID"] = value
        }
        
        if let value = self.eventID as AnyObject? {
            dictionary["eventID"] = value
        }
        
        if let value = self.attractionID as AnyObject? {
            dictionary["attractionID"] = value
        }
        
        if let value = self.placeID as AnyObject? {
            dictionary["placeID"] = value
        }
        
        if let value = self.showExtras as AnyObject? {
            dictionary["showExtras"] = value
        }
        
        if let value = self.completed as AnyObject? {
            dictionary["completed"] = value
        }
        
        if let value = self.hkSampleID as AnyObject? {
            dictionary["hkSampleID"] = value
        }
        
        return dictionary
    }
    
    func scheduleToAnyObject() -> [String: AnyObject] {
        var dictionary = [String: AnyObject]()
        
        if let value = self.name as AnyObject? {
            dictionary["name"] = value
        }
        
        if let value = self.activityID as AnyObject? {
            dictionary["activityID"] = value
        }
        
        if let value = self.activityType as AnyObject? {
            dictionary["activityType"] = value
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
        
        if let value = self.endTimeZone as AnyObject? {
            dictionary["endTimeZone"] = value
        }
        
        if let value = self.recurrences as AnyObject? {
            dictionary["recurrences"] = value
        }
        
        if let value = self.reminder as AnyObject? {
            dictionary["reminder"] = value
        }
        
        if let value = self.checklist {
            var firebaseChecklistList = [[String: AnyObject?]]()
            for checklist in value {
                let firebaseChecklist = checklist.toAnyObject()
                firebaseChecklistList.append(firebaseChecklist)
            }
            dictionary["checklist"] = firebaseChecklistList as AnyObject
        }
        
        if let value = self.recipeID as AnyObject? {
            dictionary["recipeID"] = value
        }
        
        if let value = self.servings as AnyObject? {
            dictionary["servings"] = value
        }
        
        if let value = self.workoutID as AnyObject? {
            dictionary["workoutID"] = value
        }
        
        if let value = self.eventID as AnyObject? {
            dictionary["eventID"] = value
        }
        
        if let value = self.placeID as AnyObject? {
            dictionary["placeID"] = value
        }
        
        return dictionary
    }
}

enum CustomType: String, Equatable, Hashable {
    case basic, complex, meal, workout, event, flight, transaction, financialAccount, transactionRule, sleep, work, mood, iOSCalendarEvent, mindfulness, calendar, googleCalendarEvent
    
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
        case .transaction, .financialAccount, .transactionRule, .mood, .iOSCalendarEvent, .mindfulness, .calendar, .googleCalendarEvent: return ""
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
