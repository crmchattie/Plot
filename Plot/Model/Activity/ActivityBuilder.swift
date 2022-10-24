//
//  EventBuilder.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-12-30.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import Firebase
import RRuleSwift

class EventBuilder {
    class func createActivity(from workout: Workout) -> Activity? {
        guard let start = workout.startDateTime, let end = workout.endDateTime else {
            return nil
        }
        
        var activityID = UUID().uuidString
        if let currentUserID = Auth.auth().currentUser?.uid, let newId = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key {
            activityID = newId
        }

        let activity = Activity(dictionary: ["activityID": activityID as AnyObject])
        activity.category = ActivityCategory.health.rawValue
        activity.subcategory = ActivitySubcategory.workout.rawValue
        activity.isEvent = true
        activity.name = workout.name
        activity.startTimeZone = TimeZone.current.identifier
        activity.endTimeZone = TimeZone.current.identifier
        activity.startDateTime = NSNumber(value: Int(start.timeIntervalSince1970))
        activity.endDateTime = NSNumber(value: Int(end.timeIntervalSince1970))
        activity.allDay = false
        activity.participantsIDs = workout.participantsIDs
        activity.containerID = workout.containerID
        activity.createdDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        activity.lastModifiedDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        return activity
    }
    
    class func createActivity(from mindfulness: Mindfulness) -> Activity? {
        guard let start = mindfulness.startDateTime, let end = mindfulness.endDateTime else {
            return nil
        }
        
        var activityID = UUID().uuidString
        if let currentUserID = Auth.auth().currentUser?.uid, let newId = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key {
            activityID = newId
        }

        let activity = Activity(dictionary: ["activityID": activityID as AnyObject])
        activity.category = ActivityCategory.health.rawValue
        activity.subcategory = ActivitySubcategory.mindfulness.rawValue
        activity.isEvent = true
        activity.name = mindfulness.name
        activity.startTimeZone = TimeZone.current.identifier
        activity.endTimeZone = TimeZone.current.identifier
        activity.startDateTime = NSNumber(value: Int(start.timeIntervalSince1970))
        activity.endDateTime = NSNumber(value: Int(end.timeIntervalSince1970))
        activity.allDay = false
        activity.participantsIDs = mindfulness.participantsIDs
        activity.containerID = mindfulness.containerID
        activity.createdDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        activity.lastModifiedDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        return activity
    }
    
    class func createActivity(from meal: Meal) -> Activity? {
        guard let start = meal.startDateTime, let end = meal.endDateTime else {
            return nil
        }
        
        var activityID = UUID().uuidString
        if let currentUserID = Auth.auth().currentUser?.uid, let newId = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key {
            activityID = newId
        }

        let activity = Activity(dictionary: ["activityID": activityID as AnyObject])
        activity.category = ActivityCategory.meal.rawValue
        activity.subcategory = ActivitySubcategory.meal.rawValue
        activity.isEvent = true
        activity.name = meal.name
        activity.startTimeZone = TimeZone.current.identifier
        activity.endTimeZone = TimeZone.current.identifier
        activity.startDateTime = NSNumber(value: Int(start.timeIntervalSince1970))
        activity.endDateTime = NSNumber(value: Int(end.timeIntervalSince1970))
        activity.allDay = false
        activity.participantsIDs = meal.participantsIDs
        activity.containerID = meal.containerID
        activity.createdDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        activity.lastModifiedDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        return activity
    }
    
    class func createActivity(from transaction: Transaction) -> Activity? {
        let isodateFormatter = ISO8601DateFormatter()
        var start = Date()
        var end = Date()
        
        if let date = isodateFormatter.date(from: transaction.transacted_at) {
            start = date.UTCTime
            end = date.UTCTime
        }
        
        var activityID = UUID().uuidString
        if let currentUserID = Auth.auth().currentUser?.uid, let newId = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key {
            activityID = newId
        }

        let activity = Activity(dictionary: ["activityID": activityID as AnyObject])
        activity.name = transaction.description
        activity.isEvent = true
        activity.category = ActivityCategory.categorize(transaction).rawValue
        activity.subcategory = ActivitySubcategory.categorize(transaction).rawValue
        activity.startTimeZone = TimeZone.current.identifier
        activity.endTimeZone = TimeZone.current.identifier
        activity.startDateTime = NSNumber(value: Int(start.timeIntervalSince1970))
        activity.endDateTime = NSNumber(value: Int(end.timeIntervalSince1970))
        activity.allDay = false
        activity.participantsIDs = transaction.participantsIDs
        activity.containerID = transaction.containerID
        activity.createdDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        activity.lastModifiedDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        return activity
    }
    
    class func createActivity(task: Activity) -> Activity? {
        let original = Date()
        let rounded = Date(timeIntervalSinceReferenceDate:
                            (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
        
        var activityID = UUID().uuidString
        if let currentUserID = Auth.auth().currentUser?.uid, let newId = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key {
            activityID = newId
        }

        let activity = Activity(dictionary: ["activityID": activityID as AnyObject])
        activity.name = task.name
        activity.category = task.category
        activity.subcategory = task.subcategory
        activity.isEvent = true
        activity.startTimeZone = TimeZone.current.identifier
        activity.endTimeZone = TimeZone.current.identifier
        activity.startDateTime = NSNumber(value: Int(rounded.timeIntervalSince1970))
        activity.endDateTime = NSNumber(value: Int(rounded.timeIntervalSince1970))
        activity.allDay = false
        activity.participantsIDs = task.participantsIDs
        activity.containerID = task.containerID
        activity.createdDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        activity.lastModifiedDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        return activity
    }
    
    class func createActivity(template: Template) -> (Activity?, [Activity]?)? {
        var activityID = UUID().uuidString
        if let currentUserID = Auth.auth().currentUser?.uid, let newId = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key {
            activityID = newId
        }

        let activity = Activity(dictionary: ["activityID": activityID as AnyObject])
        activity.name = template.name
        activity.isEvent = true
        activity.category = template.category.rawValue
        activity.subcategory = template.subcategory.rawValue
        activity.activityDescription = template.description
        
        if let startDate = template.getStartDate(), let endDate = template.getEndDate() {
            activity.startDateTime = NSNumber(value: Int(startDate.timeIntervalSince1970))
            activity.endDateTime = NSNumber(value: Int(endDate.timeIntervalSince1970))
            if let frequency = template.frequency, let recurrenceFrequency = frequency.recurrenceFrequency {
                var recurrenceRule = RecurrenceRule(frequency: recurrenceFrequency)
                recurrenceRule.startDate = startDate
                recurrenceRule.interval = template.interval ?? 1
                activity.recurrences = [recurrenceRule.toRRuleString()]
                print(recurrenceRule.toRRuleString())
            }
        }
        
        activity.startTimeZone = TimeZone.current.identifier
        activity.endTimeZone = TimeZone.current.identifier
        activity.allDay = false
        activity.createdDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        activity.lastModifiedDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        var schedule = [Activity]()
        for subtemplate in template.subtemplates ?? [] {
            let scheduleItem = createSchedule(subtemplate: subtemplate)
            schedule.append(scheduleItem)
        }
        return (activity, schedule)
    }
    
    class func createSchedule(subtemplate: Template) -> Activity {
        var activityID = UUID().uuidString
        if let currentUserID = Auth.auth().currentUser?.uid, let newId = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key {
            activityID = newId
        }
        let activity = Activity(dictionary: ["activityID": activityID as AnyObject])
        activity.name = subtemplate.name
        activity.isSchedule = true
        activity.category = subtemplate.category.rawValue
        activity.subcategory = subtemplate.subcategory.rawValue
        activity.activityDescription = subtemplate.description
        activity.startTimeZone = TimeZone.current.identifier
        activity.endTimeZone = TimeZone.current.identifier
        if let startDate = subtemplate.getStartDate(), let endDate = subtemplate.getEndDate() {
            activity.startDateTime = NSNumber(value: Int(startDate.timeIntervalSince1970))
            activity.endDateTime = NSNumber(value: Int(endDate.timeIntervalSince1970))
        }
        activity.allDay = false
        activity.createdDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        activity.lastModifiedDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        return activity
    }
}

class TaskBuilder {
    class func createActivity(from workout: Workout) -> Activity? {
        guard let end = workout.endDateTime else {
            return nil
        }
        
        var activityID = UUID().uuidString
        if let currentUserID = Auth.auth().currentUser?.uid, let newId = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key {
            activityID = newId
        }

        let activity = Activity(dictionary: ["activityID": activityID as AnyObject])
        activity.category = ActivityCategory.health.rawValue
        activity.subcategory = ActivitySubcategory.workout.rawValue
        activity.isTask = true
        activity.name = workout.name
        activity.endDateTime = NSNumber(value: Int(end.timeIntervalSince1970))
        activity.hasDeadlineTime = true
        activity.participantsIDs = workout.participantsIDs
        activity.containerID = workout.containerID
        if end.timeIntervalSinceNow.sign == .minus {
            activity.isCompleted = true
            activity.completedDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        }
        activity.createdDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        activity.lastModifiedDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        return activity
    }
    
    class func createActivity(from mindfulness: Mindfulness) -> Activity? {
        guard let end = mindfulness.endDateTime else {
            return nil
        }
        
        var activityID = UUID().uuidString
        if let currentUserID = Auth.auth().currentUser?.uid, let newId = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key {
            activityID = newId
        }

        let activity = Activity(dictionary: ["activityID": activityID as AnyObject])
        activity.category = ActivityCategory.health.rawValue
        activity.subcategory = ActivitySubcategory.mindfulness.rawValue
        activity.isTask = true
        activity.name = mindfulness.name
        activity.endDateTime = NSNumber(value: Int(end.timeIntervalSince1970))
        activity.hasDeadlineTime = true
        activity.participantsIDs = mindfulness.participantsIDs
        activity.containerID = mindfulness.containerID
        if end.timeIntervalSinceNow.sign == .minus {
            activity.isCompleted = true
            activity.completedDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        }
        activity.createdDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        activity.lastModifiedDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        return activity
    }
    
    class func createActivity(from meal: Meal) -> Activity? {
        guard let end = meal.endDateTime else {
            return nil
        }
        
        var activityID = UUID().uuidString
        if let currentUserID = Auth.auth().currentUser?.uid, let newId = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key {
            activityID = newId
        }

        let activity = Activity(dictionary: ["activityID": activityID as AnyObject])
        activity.category = ActivityCategory.meal.rawValue
        activity.subcategory = ActivitySubcategory.meal.rawValue
        activity.isTask = true
        activity.name = meal.name
        activity.endDateTime = NSNumber(value: Int(end.timeIntervalSince1970))
        activity.hasDeadlineTime = true
        activity.participantsIDs = meal.participantsIDs
        activity.containerID = meal.containerID
        if end.timeIntervalSinceNow.sign == .minus {
            activity.isCompleted = true
            activity.completedDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        }
        activity.createdDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        activity.lastModifiedDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        return activity
    }
    
    class func createActivity(from transaction: Transaction) -> Activity? {
        let isodateFormatter = ISO8601DateFormatter()
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.maximumFractionDigits = 0
        
        var end = Date()
        
        if let date = isodateFormatter.date(from: transaction.transacted_at) {
            end = date.UTCTime
        }
        
        var activityID = UUID().uuidString
        if let currentUserID = Auth.auth().currentUser?.uid, let newId = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key {
            activityID = newId
        }

        let activity = Activity(dictionary: ["activityID": activityID as AnyObject])
        if transaction.category == "Paycheck" {
            activity.name = "Paycheck"
            activity.category = ActivityCategory.finances.rawValue
            activity.subcategory = ActivitySubcategory.finances.rawValue
        } else {
            activity.name = transaction.description + " Bill"
            activity.category = ActivityCategory.finances.rawValue
            activity.subcategory = ActivitySubcategory.bills.rawValue
        }
        if let amount = numberFormatter.string(from: transaction.amount as NSNumber) {
            activity.activityDescription = String("Amount: \(amount)")
        }
        activity.isTask = true
        activity.endDateTime = NSNumber(value: Int(end.timeIntervalSince1970))
        activity.hasDeadlineTime = false
        activity.participantsIDs = transaction.participantsIDs
        activity.containerID = transaction.containerID
        if end.timeIntervalSinceNow.sign == .minus {
            activity.isCompleted = true
            activity.completedDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        }
        activity.createdDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        activity.lastModifiedDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        return activity
    }
    
    class func createActivity(from account: MXAccount) -> Activity? {
        let isodateFormatter = ISO8601DateFormatter()
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.maximumFractionDigits = 0

        if let payment_due_at = account.payment_due_at, let date = isodateFormatter.date(from: payment_due_at) {
            var activityID = UUID().uuidString
            if let currentUserID = Auth.auth().currentUser?.uid, let newId = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key {
                activityID = newId
            }

            let activity = Activity(dictionary: ["activityID": activityID as AnyObject])
            activity.name = account.name + " Payment Due"
            if let minimum_payment = account.minimum_payment, let amount = numberFormatter.string(from: minimum_payment as NSNumber) {
                activity.activityDescription = String("Minimum payment due: \(amount)")
            }
            activity.isTask = true
            activity.category = ActivityCategory.finances.rawValue
            activity.subcategory = ActivitySubcategory.bills.rawValue
            activity.endDateTime = NSNumber(value: date.UTCTime.timeIntervalSince1970)
            activity.hasDeadlineTime = false
            activity.participantsIDs = account.participantsIDs
            activity.createdDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
            activity.lastModifiedDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
            return activity
        }
        return nil
    }
    
    class func createActivity(event: Activity) -> Activity? {
        var activityID = UUID().uuidString
        if let currentUserID = Auth.auth().currentUser?.uid, let newId = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key {
            activityID = newId
        }

        let activity = Activity(dictionary: ["activityID": activityID as AnyObject])
        activity.name = event.name
        activity.category = event.category
        activity.subcategory = event.subcategory
        activity.isTask = true
        activity.endTimeZone = TimeZone.current.identifier
        activity.endDateTime = event.endDateTime
        if event.allDay ?? false {
            activity.hasDeadlineTime = false
        } else {
            activity.hasDeadlineTime = true
        }
        activity.participantsIDs = event.participantsIDs
        activity.containerID = event.containerID
        if let endDate = event.endDate, endDate.timeIntervalSinceNow.sign == .minus {
            activity.isCompleted = true
            activity.completedDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        }
        activity.createdDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        activity.lastModifiedDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        return activity
    }
    
    class func createActivity(template: Template) -> (Activity?, [Activity]?)? {
        var activityID = UUID().uuidString
        if let currentUserID = Auth.auth().currentUser?.uid, let newId = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key {
            activityID = newId
        }

        let activity = Activity(dictionary: ["activityID": activityID as AnyObject])
        activity.name = template.name
        activity.isTask = true
        activity.category = template.category.rawValue
        activity.subcategory = template.subcategory.rawValue
        activity.activityDescription = template.description
        
        if let endDate = template.getEndDate() {
            activity.endDateTime = NSNumber(value: Int(endDate.timeIntervalSince1970))
            if let frequency = template.frequency, let recurrenceFrequency = frequency.recurrenceFrequency {
                var recurrenceRule = RecurrenceRule(frequency: recurrenceFrequency)
                recurrenceRule.startDate = endDate
                recurrenceRule.interval = template.interval ?? 1
                activity.recurrences = [recurrenceRule.toRRuleString()]
            }
        }
        
        activity.createdDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        activity.lastModifiedDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        var subtasks = [Activity]()
        for subtemplate in template.subtemplates ?? [] {
            let subtask = createSubTask(subtemplate: subtemplate)
            subtasks.append(subtask)
        }
        return (activity, subtasks)
    }
    
    class func createSubTask(subtemplate: Template) -> Activity {
        var activityID = UUID().uuidString
        if let currentUserID = Auth.auth().currentUser?.uid, let newId = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key {
            activityID = newId
        }

        let activity = Activity(dictionary: ["activityID": activityID as AnyObject])
        activity.name = subtemplate.name
        activity.category = subtemplate.category.rawValue
        activity.subcategory = subtemplate.subcategory.rawValue
        activity.activityDescription = subtemplate.description
        if let endDate = subtemplate.getEndDate() {
            activity.endDateTime = NSNumber(value: Int(endDate.timeIntervalSince1970))
        }
        activity.createdDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        activity.lastModifiedDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
        activity.isSubtask = true
        return activity
    }
    
    class func createActivityWithList(from workout: Workout, completion: @escaping (Activity?) -> Void) {
            guard let currentUserID = Auth.auth().currentUser?.uid, let end = workout.endDateTime else {
                completion(nil)
                return
            }
            
            var activityID = UUID().uuidString
            if let newId = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key {
                activityID = newId
            }
            
            ListFetcher.fetchListsForUser(id: currentUserID) { lists in
                if let list = lists.first(where: { $0.healthList ?? false }) {
                    let activity = Activity(dictionary: ["activityID": activityID as AnyObject])
                    activity.listID = list.id
                    activity.listName = list.name
                    activity.listSource = list.source
                    activity.listColor = list.color
                    activity.category = ActivityCategory.health.rawValue
                    activity.subcategory = ActivitySubcategory.workout.rawValue
                    activity.isTask = true
                    activity.name = workout.name
                    activity.endDateTime = NSNumber(value: Int(end.timeIntervalSince1970))
                    activity.hasDeadlineTime = true
                    activity.participantsIDs = workout.participantsIDs
                    activity.containerID = workout.containerID
                    if end.timeIntervalSinceNow.sign == .minus {
                        activity.isCompleted = true
                        activity.completedDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
                    }
                    activity.createdDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
                    activity.lastModifiedDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
                    completion(activity)
                } else {
                    completion(nil)
                }
            }
        }
        
        class func createActivityWithList(from mindfulness: Mindfulness, completion: @escaping (Activity?) -> Void) {
            guard let currentUserID = Auth.auth().currentUser?.uid, let end = mindfulness.endDateTime else {
                completion(nil)
                return
            }
            
            var activityID = UUID().uuidString
            if let newId = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key {
                activityID = newId
            }

            ListFetcher.fetchListsForUser(id: currentUserID) { lists in
                if let list = lists.first(where: { $0.healthList ?? false }) {
                    let activity = Activity(dictionary: ["activityID": activityID as AnyObject])
                    activity.listID = list.id
                    activity.listName = list.name
                    activity.listSource = list.source
                    activity.listColor = list.color
                    activity.category = ActivityCategory.health.rawValue
                    activity.subcategory = ActivitySubcategory.mindfulness.rawValue
                    activity.isTask = true
                    activity.name = mindfulness.name
                    activity.endDateTime = NSNumber(value: Int(end.timeIntervalSince1970))
                    activity.hasDeadlineTime = true
                    activity.participantsIDs = mindfulness.participantsIDs
                    activity.containerID = mindfulness.containerID
                    if end.timeIntervalSinceNow.sign == .minus {
                        activity.isCompleted = true
                        activity.completedDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
                    }
                    activity.createdDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
                    activity.lastModifiedDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
                    completion(activity)
                } else {
                    completion(nil)
                }
            }
        }
        
        class func createActivityWithList(from meal: Meal, completion: @escaping (Activity?) -> Void) {
            guard let currentUserID = Auth.auth().currentUser?.uid, let end = meal.endDateTime else {
                completion(nil)
                return
            }
            
            var activityID = UUID().uuidString
            if let newId = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key {
                activityID = newId
            }

            ListFetcher.fetchListsForUser(id: currentUserID) { lists in
                if let list = lists.first(where: { $0.healthList ?? false }) {
                    let activity = Activity(dictionary: ["activityID": activityID as AnyObject])
                    activity.listID = list.id
                    activity.listName = list.name
                    activity.listSource = list.source
                    activity.listColor = list.color
                    activity.category = ActivityCategory.meal.rawValue
                    activity.subcategory = ActivitySubcategory.meal.rawValue
                    activity.isTask = true
                    activity.name = meal.name
                    activity.endDateTime = NSNumber(value: Int(end.timeIntervalSince1970))
                    activity.hasDeadlineTime = true
                    activity.participantsIDs = meal.participantsIDs
                    activity.containerID = meal.containerID
                    if end.timeIntervalSinceNow.sign == .minus {
                        activity.isCompleted = true
                        activity.completedDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
                    }
                    activity.createdDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
                    activity.lastModifiedDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
                    completion(activity)
                } else {
                    completion(nil)
                }
            }
        }
        
        class func createActivityWithList(from transaction: Transaction, completion: @escaping (Activity?) -> Void) {
            let isodateFormatter = ISO8601DateFormatter()
            guard let currentUserID = Auth.auth().currentUser?.uid, let date = isodateFormatter.date(from: transaction.transacted_at) else {
                completion(nil)
                return
            }
            
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .currency
            numberFormatter.maximumFractionDigits = 0
            
            let end = date.UTCTime
            
            var activityID = UUID().uuidString
            if let newId = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key {
                activityID = newId
            }

            ListFetcher.fetchListsForUser(id: currentUserID) { lists in
                if let list = lists.first(where: { $0.financeList ?? false }) {
                    let activity = Activity(dictionary: ["activityID": activityID as AnyObject])
                    activity.listID = list.id
                    activity.listName = list.name
                    activity.listSource = list.source
                    activity.listColor = list.color
                    if transaction.category == "Paycheck" {
                        activity.name = "Paycheck"
                        activity.category = ActivityCategory.finances.rawValue
                        activity.subcategory = ActivitySubcategory.finances.rawValue
                    } else {
                        activity.name = transaction.description + " Bill"
                        activity.category = ActivityCategory.finances.rawValue
                        activity.subcategory = ActivitySubcategory.bills.rawValue
                    }
                    if let amount = numberFormatter.string(from: transaction.amount as NSNumber) {
                        activity.activityDescription = String("Amount: \(amount)")
                    }
                    activity.isTask = true
                    activity.endDateTime = NSNumber(value: Int(end.timeIntervalSince1970))
                    activity.hasDeadlineTime = false
                    activity.participantsIDs = transaction.participantsIDs
                    activity.containerID = transaction.containerID
                    if end.timeIntervalSinceNow.sign == .minus {
                        activity.isCompleted = true
                        activity.completedDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
                    }
                    activity.createdDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
                    activity.lastModifiedDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
                    completion(activity)
                } else {
                    completion(nil)
                }
            }
        }
        
        class func createActivityWithList(from account: MXAccount, completion: @escaping (Activity?) -> Void) {
            let isodateFormatter = ISO8601DateFormatter()
            
            guard let currentUserID = Auth.auth().currentUser?.uid, let payment_due_at = account.payment_due_at, let date = isodateFormatter.date(from: payment_due_at) else {
                completion(nil)
                return
            }
            
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .currency
            numberFormatter.maximumFractionDigits = 0

            var activityID = UUID().uuidString
            if let newId = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key {
                activityID = newId
            }

            ListFetcher.fetchListsForUser(id: currentUserID) { lists in
                if let list = lists.first(where: { $0.financeList ?? false }) {
                    let activity = Activity(dictionary: ["activityID": activityID as AnyObject])
                    activity.listID = list.id
                    activity.listName = list.name
                    activity.listSource = list.source
                    activity.listColor = list.color
                    activity.name = account.name + " Payment Due"
                    if let minimum_payment = account.minimum_payment, let amount = numberFormatter.string(from: minimum_payment as NSNumber) {
                        activity.activityDescription = String("Minimum payment due: \(amount)")
                    }
                    activity.isTask = true
                    activity.category = ActivityCategory.finances.rawValue
                    activity.subcategory = ActivitySubcategory.bills.rawValue
                    activity.endDateTime = NSNumber(value: date.UTCTime.timeIntervalSince1970)
                    activity.hasDeadlineTime = false
                    activity.participantsIDs = account.participantsIDs
                    activity.createdDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
                    activity.lastModifiedDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
                    completion(activity)
                } else {
                    completion(nil)
                }
            }
        }
        
        class func createActivityWithList(event: Activity, completion: @escaping (Activity?) -> Void) {
            guard let currentUserID = Auth.auth().currentUser?.uid else {
                completion(nil)
                return
            }
            
            var activityID = UUID().uuidString
            if let newId = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key {
                activityID = newId
            }

            ListFetcher.fetchListsForUser(id: currentUserID) { lists in
                if let list = lists.first(where: { $0.defaultList ?? false }) {
                    let activity = Activity(dictionary: ["activityID": activityID as AnyObject])
                    activity.listID = list.id
                    activity.listName = list.name
                    activity.listSource = list.source
                    activity.listColor = list.color
                    activity.name = event.name
                    activity.category = event.category
                    activity.subcategory = event.subcategory
                    activity.isTask = true
                    activity.endTimeZone = TimeZone.current.identifier
                    activity.endDateTime = event.endDateTime
                    if event.allDay ?? false {
                        activity.hasDeadlineTime = false
                    } else {
                        activity.hasDeadlineTime = true
                    }
                    activity.participantsIDs = event.participantsIDs
                    activity.containerID = event.containerID
                    if let endDate = event.endDate, endDate.timeIntervalSinceNow.sign == .minus {
                        activity.isCompleted = true
                        activity.completedDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
                    }
                    activity.createdDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
                    activity.lastModifiedDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
                    completion(activity)
                } else {
                    completion(nil)
                }
            }
        }
        
        class func createActivityWithList(template: Template, completion: @escaping (Activity?, [Activity]?) -> Void) {
            guard let currentUserID = Auth.auth().currentUser?.uid else {
                completion(nil, nil)
                return
            }
            
            var activityID = UUID().uuidString
            if let newId = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key {
                activityID = newId
            }

            ListFetcher.fetchListsForUser(id: currentUserID) { lists in
                if let list = lists.first(where: { $0.defaultList ?? false }) {
                    let activity = Activity(dictionary: ["activityID": activityID as AnyObject])
                    activity.listID = list.id
                    activity.listName = list.name
                    activity.listSource = list.source
                    activity.listColor = list.color
                    activity.name = template.name
                    activity.isTask = true
                    activity.category = template.category.rawValue
                    activity.subcategory = template.subcategory.rawValue
                    activity.activityDescription = template.description
                    
                    if let endDate = template.getEndDate() {
                        activity.endDateTime = NSNumber(value: Int(endDate.timeIntervalSince1970))
                        if let frequency = template.frequency, let recurrenceFrequency = frequency.recurrenceFrequency {
                            var recurrenceRule = RecurrenceRule(frequency: recurrenceFrequency)
                            recurrenceRule.startDate = endDate
                            recurrenceRule.interval = template.interval ?? 1
                            activity.recurrences = [recurrenceRule.toRRuleString()]
                        }
                    }
                    
                    activity.createdDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
                    activity.lastModifiedDate = NSNumber(value: Int((Date()).timeIntervalSince1970))
                    var subtasks = [Activity]()
                    for subtemplate in template.subtemplates ?? [] {
                        let subtask = createSubTask(subtemplate: subtemplate)
                        subtasks.append(subtask)
                    }
                    completion(activity, subtasks)
                } else {
                    completion(nil, nil)
                }
            }
        }
}
