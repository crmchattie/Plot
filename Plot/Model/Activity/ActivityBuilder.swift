//
//  ActivityBuilder.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-12-30.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import Firebase

class ActivityBuilder {
    class func createActivity(from workout: Workout) -> Activity? {
        guard let start = workout.startDateTime, let end = workout.endDateTime else {
            return nil
        }
        
        var activityID = UUID().uuidString
        if let currentUserID = Auth.auth().currentUser?.uid, let newId = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key {
            activityID = newId
        }

        let activity = Activity(dictionary: ["activityID": activityID as AnyObject])
        activity.activityType = "Workout"
        activity.category = "Workout"
        activity.name = workout.name
        if let totalEnergyBurned = workout.totalEnergyBurned, let type = workout.type {
            activity.activityDescription = "\(String(describing: type)) - \(totalEnergyBurned.clean) calories"
        }
        activity.startTimeZone = TimeZone.current.identifier
        activity.endTimeZone = TimeZone.current.identifier
        activity.startDateTime = NSNumber(value: start.timeIntervalSince1970)
        activity.endDateTime = NSNumber(value: end.timeIntervalSince1970)
        activity.allDay = false
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
        activity.activityType = "Mindfulness"
        activity.category = "Mindfulness"
        activity.name = mindfulness.name
        activity.startTimeZone = TimeZone.current.identifier
        activity.endTimeZone = TimeZone.current.identifier
        activity.startDateTime = NSNumber(value: start.timeIntervalSince1970)
        activity.endDateTime = NSNumber(value: end.timeIntervalSince1970)
        activity.allDay = false
        
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
        activity.activityType = "Meal"
        activity.category = "Meal"
        activity.name = meal.name
        activity.mealIDs = [meal.id]
        activity.startTimeZone = TimeZone.current.identifier
        activity.endTimeZone = TimeZone.current.identifier
        activity.startDateTime = NSNumber(value: start.timeIntervalSince1970)
        activity.endDateTime = NSNumber(value: end.timeIntervalSince1970)
        activity.allDay = false
        
        return activity
    }
    
    class func createActivity(from transaction: Transaction) -> Activity? {
        let isodateFormatter = ISO8601DateFormatter()
        let numberFormatter = NumberFormatter()
        numberFormatter.currencyCode = transaction.currency_code
        var start = Date()
        var end = Date()
        
        if let reportDate = transaction.date_for_reports, reportDate != "", let date = isodateFormatter.date(from: reportDate) {
            start = date
            end = date
        } else if let date = isodateFormatter.date(from: transaction.transacted_at) {
            start = date
            end = date
        } else {
            return nil
        }
        
        var activityID = UUID().uuidString
        if let currentUserID = Auth.auth().currentUser?.uid, let newId = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key {
            activityID = newId
        }

        let activity = Activity(dictionary: ["activityID": activityID as AnyObject])
        activity.activityType = "Transaction"
        activity.category = "Transaction"
        activity.name = transaction.description
        activity.activityDescription = "\(String(describing: numberFormatter.string(for: transaction.amount)))"
        activity.transactionIDs = [transaction.guid]
        activity.startTimeZone = TimeZone.current.identifier
        activity.endTimeZone = TimeZone.current.identifier
        activity.startDateTime = NSNumber(value: start.timeIntervalSince1970)
        activity.endDateTime = NSNumber(value: end.timeIntervalSince1970)
        activity.allDay = false
        return activity
    }
}
