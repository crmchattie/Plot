//
//  CalendarActivityOp.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-11-24.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import EventKit
import Firebase
import CodableFirebase

class EKCalendarEventOp: AsyncOperation {
    private var event: EKEvent
    
    init(event: EKEvent) {
        self.event = event
    }
    
    override func main() {
        startRequest()
    }
    
    private func startRequest() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            self.finish()
            return
        }
        let reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserId).child(calendarEventsKey).child(event.calendarItemExternalIdentifierClean)
        reference.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            if snapshot.exists(), let value = snapshot.value as? [String : String], let activityID = value["activityID"] {
                let activityDataReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
                activityDataReference.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
                    guard snapshot.exists(), let activitySnapshotValue = snapshot.value, let activity = try? FirebaseDecoder().decode(Activity.self, from: activitySnapshotValue) else {
                        self?.finish()
                        return
                    }
                    self?.update(activity: activity) { activity in
                        let activityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
                        activityReference.updateChildValues(activity.toAnyObject(), withCompletionBlock: { [weak self] (error, reference) in
                            if !self!.event.isDetached {
                                let userActivityReference = Database.database().reference().child(userActivitiesEntity).child(currentUserId).child(activityID).child(messageMetaDataFirebaseFolder)
                                var values: [String : Any] = ["calendarExport": true,
                                                              "calendarSource": CalendarSourceOptions.apple.name as Any,
                                                              "externalActivityID": self?.event.calendarItemIdentifier as Any]
                                if let calendar = self?.event.calendar {
                                    values["calendarID"] = calendar.calendarIdentifier as Any
                                    values["calendarName"] = calendar.title as Any
                                }
                                if let CGColor = self?.event.calendar.cgColor {
                                    values["calendarColor"] = CIColor(cgColor: CGColor).stringRepresentation as Any
                                }
                                userActivityReference.updateChildValues(values, withCompletionBlock: { [weak self] (error, reference) in
                                    self?.finish()
                                })
                            } else {
                                self?.finish()
                            }
                        })
                    }
                })
            }
            else if !snapshot.exists(), let weakSelf = self {
                let newReference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserId).child(calendarEventsKey).child(weakSelf.event.calendarItemIdentifier)
                newReference.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
                    if snapshot.exists(), let value = snapshot.value as? [String : String], let activityID = value["activityID"] {
                        
                        let calendarEventActivityValue: [String : Any] = ["activityID": activityID as AnyObject]
                        reference.updateChildValues(calendarEventActivityValue)
                        
                        let activityDataReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
                        activityDataReference.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
                            guard snapshot.exists(), let activitySnapshotValue = snapshot.value, let activity = try? FirebaseDecoder().decode(Activity.self, from: activitySnapshotValue) else {
                                self?.finish()
                                return
                            }
                            self?.update(activity: activity) { activity in
                                let activityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
                                activityReference.updateChildValues(activity.toAnyObject(), withCompletionBlock: { [weak self] (error, reference) in
                                    if !self!.event.isDetached {
                                        let userActivityReference = Database.database().reference().child(userActivitiesEntity).child(currentUserId).child(activityID).child(messageMetaDataFirebaseFolder)
                                        var values: [String : Any] = ["calendarExport": true,
                                                                      "calendarSource": CalendarSourceOptions.apple.name as Any,
                                                                      "externalActivityID": self?.event.calendarItemIdentifier as Any]
                                        if let calendar = self?.event.calendar {
                                            values["calendarID"] = calendar.calendarIdentifier as Any
                                            values["calendarName"] = calendar.title as Any
                                        }
                                        if let CGColor = self?.event.calendar.cgColor {
                                            values["calendarColor"] = CIColor(cgColor: CGColor).stringRepresentation as Any
                                        }
                                        userActivityReference.updateChildValues(values, withCompletionBlock: { [weak self] (error, reference) in
                                            self?.finish()
                                        })
                                    } else {
                                        self?.finish()
                                    }
                                })
                            }
                        })
                    }
                    else if !snapshot.exists() {
                        guard let activityID = Database.database().reference().child(userActivitiesEntity).child(currentUserId).childByAutoId().key else {
                            self?.finish()
                            return
                        }
                        let calendarEventActivityValue: [String : Any] = ["activityID": activityID as AnyObject]
                        reference.updateChildValues(calendarEventActivityValue) { (_, _) in
                            weakSelf.createActivity(for: activityID) { activity in
                                let activityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
                                activityReference.updateChildValues(activity.toAnyObject(), withCompletionBlock: { [weak self] (error, reference) in
                                    if !self!.event.isDetached {
                                        let userActivityReference = Database.database().reference().child(userActivitiesEntity).child(currentUserId).child(activityID).child(messageMetaDataFirebaseFolder)
                                        var values: [String : Any] = ["calendarExport": true,
                                                                      "calendarSource": CalendarSourceOptions.apple.name as Any,
                                                                      "externalActivityID": self?.event.calendarItemIdentifier as Any]
                                        if let calendar = self?.event.calendar {
                                            values["calendarID"] = calendar.calendarIdentifier as Any
                                            values["calendarName"] = calendar.title as Any
                                        }
                                        if let CGColor = self?.event.calendar.cgColor {
                                            values["calendarColor"] = CIColor(cgColor: CGColor).stringRepresentation as Any
                                        }
                                        userActivityReference.updateChildValues(values, withCompletionBlock: { [weak self] (error, reference) in
                                            self?.finish()
                                        })
                                    } else {
                                        self?.finish()
                                    }
                                })
                            }
                        }
                    }
                    else {
                        self?.finish()
                    }
                })
            }
        })
    }
    
    private func createActivity(for activityID: String, completion: @escaping (Activity) -> Void) {
        let activity = Activity(dictionary: ["activityID": activityID as AnyObject])
        update(activity: activity) { activity in
            activity.admin = Auth.auth().currentUser?.uid
            activity.participantsIDs = [Auth.auth().currentUser?.uid ?? ""]
            activity.activityType = CustomType.iOSCalendarEvent.categoryText
            activity.category = ActivityCategory.categorize(activity).rawValue
            activity.showExtras = false
            completion(activity)
        }
    }
    
    private func update(activity: Activity, completion: @escaping (Activity) -> Void) {
        if !event.isDetached {
            activity.isEvent = true
            activity.name = event.title
            if let notes = event.notes {
                activity.activityDescription = notes
            }
            if let structuredLocation = event.structuredLocation, let geoLocation = structuredLocation.geoLocation, let location = event.location {
                let coordinates = geoLocation.coordinate
                let latitude = coordinates.latitude
                let longitude = coordinates.longitude
                activity.locationName = location.removeCharacters()
                activity.locationAddress = [location.removeCharacters(): [latitude, longitude]]
            } else {
                activity.locationName = nil
                activity.locationAddress = nil
            }
            activity.allDay = event.isAllDay
            activity.startTimeZone = event.timeZone?.identifier
            activity.endTimeZone = event.timeZone?.identifier
            activity.recurrences = event.recurrenceRules?.map { $0.iCalRuleString() }
            activity.startDateTime = NSNumber(value: event.startDate.timeIntervalSince1970)
            activity.endDateTime = NSNumber(value: event.endDate.timeIntervalSince1970)
            if let date = event.creationDate {
                activity.createdDate = NSNumber(value: Int(date.timeIntervalSince1970))
            }
            if let date = event.lastModifiedDate {
                activity.lastModifiedDate = NSNumber(value: Int(date.timeIntervalSince1970))
            }
            completion(activity)
            
        } else if let originalOccurrenceDate = event.originalOccurrenceDate {
            activity.instanceID = event.calendarItemIdentifier
            
            var instanceIDs = activity.instanceIDs ?? []
            instanceIDs.append(event.calendarItemIdentifier)
            activity.instanceIDs = instanceIDs
            
            var values:[String : Any] = [:]
            values["instanceOriginalStartDateTime"] = NSNumber(value: Int(originalOccurrenceDate.timeIntervalSince1970)) as Any
            values["instanceOriginalAllDay"] = event.isAllDay as Any
            values["instanceOriginalStartTimeZone"] = event.timeZone?.identifier as Any
            
            if event.title != activity.name {
                values["name"] = event.title as Any
            } else if event.notes != activity.activityDescription {
                values["activityDescription"] = event.notes as Any
            } else {
                if let structuredLocation = event.structuredLocation, let geoLocation = structuredLocation.geoLocation, let location = event.location, activity.locationName != location.removeCharacters() {
                    let coordinates = geoLocation.coordinate
                    let latitude = coordinates.latitude
                    let longitude = coordinates.longitude
                    values["locationName"] = location.removeCharacters() as Any
                    values["locationAddress"] = [location.removeCharacters(): [latitude, longitude]] as Any
                }
            }
            
            let activityAction = ActivityActions(activity: activity, active: true, selectedFalconUsers: [])
            activityAction.updateInstance(instanceValues: values, updateExternal: false)
            
            activity.instanceID = nil
            completion(activity)
        } else {
            completion(activity)
        }
    }
    
    private func deleteActivity() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            self.finish()
            return
        }
        
        let reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserId).child(calendarEventsKey).child(event.calendarItemIdentifier)
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
