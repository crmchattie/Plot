//
//  GListActivityOp.swift
//  Plot
//
//  Created by Cory McHattie on 2/3/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import Firebase
import CodableFirebase

class GListTaskOp: AsyncOperation {
    private var list: GTLRTasks_TaskList
    private var task: GTLRTasks_Task
    
    init(list: GTLRTasks_TaskList,task: GTLRTasks_Task) {
        self.list = list
        self.task = task
    }
    
    override func main() {
        startRequest()
    }
    
    private func startRequest() {
        guard let currentUserId = Auth.auth().currentUser?.uid, let id = list.identifier else {
            self.finish()
            return
        }
        let reference = Database.database().reference().child(userReminderTasksEntity).child(currentUserId).child(reminderTasksKey).child(id)
        reference.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            if snapshot.exists(), let value = snapshot.value as? [String : String], let activityID = value["activityID"] {
                let activityDataReference = Database.database().reference().child(activitiesEntity).child(activityID)
                activityDataReference.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
                    guard snapshot.exists(), let activitySnapshotValue = snapshot.value, let activity = try? FirebaseDecoder().decode(Activity.self, from: activitySnapshotValue) else {
                        self?.finish()
                        return
                    }
                    self?.update(activity: activity, completion: { activity in
                        let activityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
                        activityReference.updateChildValues(activity.toAnyObject(), withCompletionBlock: { [weak self] (error, reference) in
                            let userActivityReference = Database.database().reference().child(userActivitiesEntity).child(currentUserId).child(activityID).child(messageMetaDataFirebaseFolder)
                            let values: [String : Any] = ["listExport": true,
                                                          "listID": self?.list.identifier as Any,
                                                          "listName": self?.list.title as Any,
                                                          "listSource": ListSourceOptions.google.name as Any,
                                                          "listColor": CIColor(color: UIColor("#007AFF")).stringRepresentation as Any,
                                                          "externalActivityID": self?.task.identifier as Any,
                                                          "showExtras": activity.showExtras as Any]
                            userActivityReference.updateChildValues(values, withCompletionBlock: { [weak self] (error, reference) in
                                self?.finish()
                            })
                        })
                    })
                })
            }
            else if !snapshot.exists() {
                guard let activityID = Database.database().reference().child(userActivitiesEntity).child(currentUserId).childByAutoId().key, let weakSelf = self else {
                    self?.finish()
                    return
                }
                
                let listTaskActivityValue: [String : Any] = ["activityID": activityID as AnyObject]
                reference.updateChildValues(listTaskActivityValue) { (_, _) in
                    weakSelf.createActivity(for: activityID) { activity in
                        let activityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
                        activityReference.updateChildValues(activity.toAnyObject(), withCompletionBlock: { [weak self] (error, reference) in
                            let userActivityReference = Database.database().reference().child(userActivitiesEntity).child(currentUserId).child(activityID).child(messageMetaDataFirebaseFolder)
                            let values: [String : Any] = ["isGroupActivity": false,
                                                          "badge": 0,
                                                          "listExport": true,
                                                          "listID": self?.list.identifier as Any,
                                                          "listName": self?.list.title as Any,
                                                          "listSource": ListSourceOptions.google.name as Any,
                                                          "listColor": CIColor(color: UIColor("#007AFF")).stringRepresentation as Any,
                                                          "externalActivityID": self?.task.identifier as Any,
                                                          "showExtras": activity.showExtras as Any]
                            userActivityReference.updateChildValues(values, withCompletionBlock: { [weak self] (error, reference) in
                                self?.finish()
                            })
                        })
                    }
                }
            }
            else {
                self?.finish()
            }
        })
    }
    
    private func createActivity(for activityID: String, completion: @escaping (Activity) -> Void) {
        let activity = Activity(dictionary: ["activityID": activityID as AnyObject])
        update(activity: activity) { activity in
            activity.category = ActivityCategory.categorize(activity).rawValue
            activity.activityType = CustomType.googleCalendarEvent.categoryText
            activity.admin = Auth.auth().currentUser?.uid
            activity.participantsIDs = [Auth.auth().currentUser?.uid ?? ""]
            completion(activity)
        }
    }
    
    private func update(activity: Activity, completion: @escaping (Activity) -> Void) {
        activity.name = task.title
        activity.isTask = true
        if let notes = task.notes {
            activity.activityDescription = notes
        }
        let isodateFormatter = ISO8601DateFormatter()
        if let due = task.due, let date = isodateFormatter.date(from: due) {
            activity.endDateTime = NSNumber(value: date.timeIntervalSince1970)
            activity.hasDeadlineTime = true
        } else {
            activity.endDateTime = nil
            activity.hasDeadlineTime = false
        }
        if let completed = task.completed, let date = isodateFormatter.date(from: completed) {
            activity.completedDate = NSNumber(value: date.timeIntervalSince1970)
            activity.isCompleted = true
        } else {
            activity.completedDate = nil
            activity.isCompleted = false
        }
        completion(activity)
    }
    
    private func deleteActivity() {
        guard let currentUserId = Auth.auth().currentUser?.uid, let id = task.identifier else {
            self.finish()
            return
        }
        
        let reference = Database.database().reference().child(userReminderTasksEntity).child(currentUserId).child(reminderTasksKey).child(id)
        reference.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            guard snapshot.exists(), let value = snapshot.value as? [String : String], let activityID = value["activityID"] else {
                self?.finish()
                return
            }
            
            let activityReference = Database.database().reference().child(activitiesEntity).child(activityID)
            let userActivityReference = Database.database().reference().child(userActivitiesEntity).child(currentUserId).child(activityID)
            activityReference.removeValue { (_, _) in
                userActivityReference.removeValue { (_, _) in
                    reference.removeValue { (_, _) in
                        self?.finish()
                    }
                }
            }
        })
    }
}
