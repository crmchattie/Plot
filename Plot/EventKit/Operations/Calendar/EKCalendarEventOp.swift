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
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            self.finish()
            return
        }
        let reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserID).child(calendarEventsKey).child(event.calendarItemExternalIdentifierClean.removeCharacters())
        reference.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            if snapshot.exists(), let value = snapshot.value as? [String : String], let activityID = value["activityID"] {
                let activityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
                activityReference.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
                    guard snapshot.exists(), let activitySnapshotValue = snapshot.value, let activity = try? FirebaseDecoder().decode(Activity.self, from: activitySnapshotValue) else {
                        self?.finish()
                        return
                    }
                    self?.update(activity: activity) { activity in
                        activityReference.updateChildValues(activity.toAnyObject(), withCompletionBlock: { [weak self] (error, reference) in
                            let userActivityReference = Database.database().reference().child(userActivitiesEntity).child(currentUserID).child(activityID).child(messageMetaDataFirebaseFolder)
                            var values: [String : Any] = ["calendarExport": true,
                                                          "calendarSource": CalendarSourceOptions.apple.name as Any,
                                                          "externalActivityID": self?.event.calendarItemExternalIdentifierClean.removeCharacters() as Any,
                                                          "startDateTime": activity.startDateTime as Any,
                                                          "endDateTime": activity.endDateTime as Any,
                                                          "recurrences": activity.recurrences as Any,
                                                          "isTask": activity.isTask as Any,
                                                          "completedDate": activity.completedDate as Any]
                            if let calendar = self?.event.calendar {
                                values["calendarID"] = calendar.calendarIdentifier as Any
                                values["calendarName"] = calendar.title as Any
                                if let CGColor = calendar.cgColor {
                                    values["calendarColor"] = CIColor(cgColor: CGColor).stringRepresentation as Any
                                }
                            }
                            userActivityReference.updateChildValues(values, withCompletionBlock: { [weak self] (error, reference) in
                                self?.finish()
                            })
                        })
                    }
                })
            }
            else if !snapshot.exists(), let weakSelf = self {
                let otherReference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserID).child(calendarEventsKey).child(weakSelf.event.calendarItemIdentifier)
                otherReference.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
                    if snapshot.exists(), let value = snapshot.value as? [String : String], let activityID = value["activityID"], !weakSelf.event.isDetached {
                        let calendarEventActivityValue: [String : Any] = ["activityID": activityID as AnyObject]
                        reference.updateChildValues(calendarEventActivityValue)
                        
                        let activityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
                        activityReference.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
                            guard snapshot.exists(), let activitySnapshotValue = snapshot.value, let activity = try? FirebaseDecoder().decode(Activity.self, from: activitySnapshotValue) else {
                                self?.finish()
                                return
                            }
                            self?.update(activity: activity) { activity in
                                activityReference.updateChildValues(activity.toAnyObject(), withCompletionBlock: { [weak self] (error, reference) in
                                    let userActivityReference = Database.database().reference().child(userActivitiesEntity).child(currentUserID).child(activityID).child(messageMetaDataFirebaseFolder)
                                    var values: [String : Any] = ["calendarExport": true,
                                                                  "calendarSource": CalendarSourceOptions.apple.name as Any,
                                                                  "externalActivityID": self?.event.calendarItemExternalIdentifierClean.removeCharacters() as Any,
                                                                  "startDateTime": activity.startDateTime as Any,
                                                                  "endDateTime": activity.endDateTime as Any,
                                                                  "recurrences": activity.recurrences as Any,
                                                                  "isTask": activity.isTask as Any,
                                                                  "completedDate": activity.completedDate as Any]
                                    if let calendar = self?.event.calendar {
                                        values["calendarID"] = calendar.calendarIdentifier as Any
                                        values["calendarName"] = calendar.title as Any
                                        if let CGColor = calendar.cgColor {
                                            values["calendarColor"] = CIColor(cgColor: CGColor).stringRepresentation as Any
                                        }
                                    }
                                    userActivityReference.updateChildValues(values, withCompletionBlock: { [weak self] (error, reference) in
                                        self?.finish()
                                    })
                                })
                            }
                        })
                    }
                    else if !snapshot.exists() {
                        guard let activityID = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key else {
                            self?.finish()
                            return
                        }
                        let calendarEventActivityValue: [String : Any] = ["activityID": activityID as AnyObject]
                        reference.updateChildValues(calendarEventActivityValue) { (_, _) in
                            weakSelf.createActivity(for: activityID) { activity in
                                let activityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
                                activityReference.updateChildValues(activity.toAnyObject(), withCompletionBlock: { [weak self] (error, reference) in
                                    let userActivityReference = Database.database().reference().child(userActivitiesEntity).child(currentUserID).child(activityID).child(messageMetaDataFirebaseFolder)
                                    var values: [String : Any] = ["calendarExport": true,
                                                                  "calendarSource": CalendarSourceOptions.apple.name as Any,
                                                                  "externalActivityID": self?.event.calendarItemIdentifier as Any,
                                                                  "startDateTime": activity.startDateTime as Any,
                                                                  "endDateTime": activity.endDateTime as Any,
                                                                  "recurrences": activity.recurrences as Any,
                                                                  "isTask": activity.isTask as Any,
                                                                  "completedDate": activity.completedDate as Any]
                                    if let calendar = self?.event.calendar {
                                        values["calendarID"] = calendar.calendarIdentifier as Any
                                        values["calendarName"] = calendar.title as Any
                                        if let CGColor = calendar.cgColor {
                                            values["calendarColor"] = CIColor(cgColor: CGColor).stringRepresentation as Any
                                        }
                                    }
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
        })
    }
    
    private func createActivity(for activityID: String, completion: @escaping (Activity) -> Void) {
        let activity = Activity(dictionary: ["activityID": activityID as AnyObject])
        update(activity: activity) { activity in
            activity.admin = Auth.auth().currentUser?.uid
            activity.participantsIDs = [Auth.auth().currentUser?.uid ?? ""]
            activity.activityType = CustomType.iOSCalendarEvent.categoryText
            if (self.event.calendar.title.lowercased().contains("holiday") || self.event.calendar.title.lowercased().contains("birthday")) {
                activity.category = ActivityCategory.notApplicable.rawValue
                activity.subcategory = ActivityCategory.notApplicable.rawValue
            } else {
                activity.category = ActivityCategory.categorize(activity).rawValue
                activity.subcategory = ActivitySubcategory.categorize(activity).rawValue
            }
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
            activity.recurrences = event.recurrenceRules?.map { $0.iCalRuleString() }
            activity.allDay = event.isAllDay
            activity.startDateTime = NSNumber(value: Int(event.startDate.timeIntervalSince1970))
            activity.endDateTime = NSNumber(value: Int(event.endDate.timeIntervalSince1970))
            activity.startTimeZone = event.timeZone?.identifier
            activity.endTimeZone = event.timeZone?.identifier
            if let date = event.creationDate {
                activity.createdDate = NSNumber(value: Int(date.timeIntervalSince1970))
            }
            if let date = event.lastModifiedDate {
                activity.lastModifiedDate = NSNumber(value: Int(date.timeIntervalSince1970))
            }
            if let structuredLocation = event.structuredLocation, let geoLocation = structuredLocation.geoLocation, let location = event.location {
                let coordinates = geoLocation.coordinate
                let latitude = coordinates.latitude
                let longitude = coordinates.longitude
                activity.locationName = location.removeCharacters()
                activity.locationAddress = [location.removeCharacters(): [latitude, longitude]]
                completion(activity)
            } else if let location = event.location {
                lookupLocation(for: location) { coordinates in
                    if let coordinates = coordinates {
                        let latitude = coordinates.latitude
                        let longitude = coordinates.longitude
                        activity.locationName = location.removeCharacters()
                        activity.locationAddress = [location.removeCharacters(): [latitude, longitude]]
                        completion(activity)
                    } else {
                        completion(activity)
                    }
                }
            } else {
                activity.locationName = nil
                activity.locationAddress = nil
                completion(activity)
            }
        } else if let originalOccurrenceDate = event.originalOccurrenceDate {
            activity.instanceID = event.calendarItemIdentifier
            
            var instanceIDs = activity.instanceIDs ?? []
            if !instanceIDs.contains(event.calendarItemIdentifier) {
                instanceIDs.append(event.calendarItemIdentifier)
            }
            activity.instanceIDs = instanceIDs
            
            var values:[String : Any] = [:]
            values["allDay"] = event.isAllDay as Any
            values["startDateTime"] = NSNumber(value: Int(event.startDate.timeIntervalSince1970)) as Any
            values["startTimeZone"] = event.timeZone?.identifier as Any
            
            values["endDateTime"] = NSNumber(value: Int(event.endDate.timeIntervalSince1970)) as Any
            values["endTimeZone"] = event.timeZone?.identifier as Any

            values["instanceOriginalStartDateTime"] = NSNumber(value: Int(originalOccurrenceDate.timeIntervalSince1970)) as Any
                        
            if event.title != activity.name {
                values["name"] = event.title as Any
            }
            if event.notes != activity.activityDescription {
                values["activityDescription"] = event.notes as Any
            }
            if let structuredLocation = event.structuredLocation, let geoLocation = structuredLocation.geoLocation, let location = event.location, activity.locationName != location.removeCharacters() {
                let coordinates = geoLocation.coordinate
                let latitude = coordinates.latitude
                let longitude = coordinates.longitude
                values["locationName"] = location.removeCharacters() as Any
                values["locationAddress"] = [location.removeCharacters(): [latitude, longitude]] as Any
                
                values["externalActivityID"] = event.calendarItemIdentifier as Any
                let activityAction = ActivityActions(activity: activity, active: true, selectedFalconUsers: [])
                activityAction.updateInstance(instanceValues: values, updateExternal: false)
                activity.instanceID = nil
                completion(activity)
                
            } else if let location = event.location, activity.locationName != location.removeCharacters() {
                lookupLocation(for: location) { coordinates in
                    if let coordinates = coordinates {
                        let latitude = coordinates.latitude
                        let longitude = coordinates.longitude
                        activity.locationName = location.removeCharacters()
                        activity.locationAddress = [location.removeCharacters(): [latitude, longitude]]
                        values["externalActivityID"] = self.event.calendarItemIdentifier as Any
                        let activityAction = ActivityActions(activity: activity, active: true, selectedFalconUsers: [])
                        activityAction.updateInstance(instanceValues: values, updateExternal: false)
                        activity.instanceID = nil
                        completion(activity)
                    } else {
                        values["externalActivityID"] = self.event.calendarItemIdentifier as Any
                        let activityAction = ActivityActions(activity: activity, active: true, selectedFalconUsers: [])
                        activityAction.updateInstance(instanceValues: values, updateExternal: false)
                        activity.instanceID = nil
                        completion(activity)
                    }
                }
            } else {
                values["externalActivityID"] = event.calendarItemIdentifier as Any
                let activityAction = ActivityActions(activity: activity, active: true, selectedFalconUsers: [])
                activityAction.updateInstance(instanceValues: values, updateExternal: false)
                activity.instanceID = nil
                completion(activity)
            }
        } else {
            completion(activity)
        }
    }
}
