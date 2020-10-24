//
//  ActivitiesFetcher.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 6/9/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage
import CodableFirebase

protocol ActivityUpdatesDelegate: class {
    func activities(didStartFetching: Bool)
    func activities(didStartUpdatingData: Bool)
    func activities(didFinishFetching: Bool, activities: [Activity])
    func activities(update activities: Activity, reloadNeeded: Bool)
    func activities(remove activity: Activity)
}

class ActivitiesFetcher: NSObject {
    
    weak var delegate: ActivityUpdatesDelegate?
    
    fileprivate var group: DispatchGroup!
    fileprivate var isGroupAlreadyFinished = false
    fileprivate var activities : [Activity] = []
    
    fileprivate var userReference: DatabaseReference!
    fileprivate var groupActivityReference: DatabaseReference!
    fileprivate var currentUserActivitiesReference: DatabaseReference!
    fileprivate var activityReference: DatabaseReference!
    
    fileprivate var inAppNotificationsObserverHandler: DatabaseHandle!
    fileprivate var currentUserActivitiesRemovingHandle = DatabaseHandle()
    fileprivate var currentUserActivitiesAddingHandle = DatabaseHandle()
    
    func fetchActivities() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        delegate?.activities(didStartFetching: true)
        currentUserActivitiesReference = Database.database().reference().child("user-activities").child(currentUserID)
        currentUserActivitiesReference.observeSingleEvent(of: .value) { (snapshot) in
            self.group = DispatchGroup()
            for _ in 0 ..< snapshot.childrenCount { self.group.enter() }
            
            self.group.notify(queue: .main, execute: {
                print("isGroupAlreadyFinished \(self.isGroupAlreadyFinished)")
                self.isGroupAlreadyFinished = true
                self.delegate?.activities(didFinishFetching: true, activities: self.activities)
            })
            
            if !snapshot.exists() {
                self.delegate?.activities(didFinishFetching: true, activities: self.activities)
                return
            }
        }
        
        observeActivityRemoved()
        observeActivityAdded()
    }
    
    func observeActivityRemoved() {
        currentUserActivitiesRemovingHandle = currentUserActivitiesReference.observe(.childRemoved) { (snapshot) in
            let activityID = snapshot.key
            if self.groupActivityReference != nil {
                guard let index = self.activitiesChangesHandle.firstIndex(where: { (element) -> Bool in
                    return element.activityID == activityID
                }) else { return }
                self.groupActivityReference = Database.database().reference().child("activities").child(self.activitiesChangesHandle[index].activityID).child(messageMetaDataFirebaseFolder)
                self.groupActivityReference.removeObserver(withHandle: self.activitiesChangesHandle[index].handle)
                self.activitiesChangesHandle.remove(at: index)
            }
            guard let activity = self.activities.first(where: {$0.activityID == activityID}) else { return }
            if let index = self.activities.firstIndex(of: activity) {
                self.activities.remove(at: index)
                self.delegate?.activities(remove: activity)
            }
        }
    }
    
    func observeActivityAdded() {
        currentUserActivitiesAddingHandle = currentUserActivitiesReference.observe(.childAdded, with: { (snapshot) in
            let activityID = snapshot.key
            self.observeAdditionsForActivity(with: activityID)
            self.observeRemovalsForActivity(with: activityID)
            self.observeChangesForActivity(with: activityID)
            self.loadActivity(for: activityID)
        })
    }

    
    fileprivate var activityReferenceHandle = [(handle: DatabaseHandle, currentUserID: String, activityID: String)]()
    
    fileprivate func loadActivity(for activityID: String) {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        activityReference = Database.database().reference().child("user-activities").child(currentUserID).child(activityID).child(messageMetaDataFirebaseFolder)
        let element = (handle: DatabaseHandle(), currentUserID: currentUserID, activityID: activityID)
        activityReferenceHandle.insert(element, at: 0)
        activityReference.keepSynced(true)
        activityReferenceHandle[0].handle = activityReference.observe( .value, with: { (snapshot) in
            
            guard var dictionary = snapshot.value as? [String: AnyObject], snapshot.exists() else { return }
            
            dictionary.updateValue(activityID as AnyObject, forKey: "activityID")
            
            self.delegate?.activities(didStartUpdatingData: true)
            let activity = Activity(dictionary: dictionary)
            
            self.loadAdditionalMetadata(for: activity)
            

        })
    }
    
    fileprivate func loadAdditionalMetadata(for activity: Activity) {
        
        guard let activityID = activity.activityID, let currentUserID = Auth.auth().currentUser?.uid else { return }
                
        let activityDataReference = Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder)
        activityDataReference.observeSingleEvent(of: .value, with: { (snapshot) in
            guard var dictionary = snapshot.value as? [String: AnyObject] else {
                Database.database().reference().child("user-activities").child(currentUserID).child(activityID).child(messageMetaDataFirebaseFolder).removeAllObservers()
                Database.database().reference().child("user-activities").child(currentUserID).child(activityID).removeValue()
                return
                
            }
            
            dictionary.updateValue(activityID as AnyObject, forKey: "activityID")
            
            if let membersIDs = dictionary["participantsIDs"] as? [String:AnyObject] {
                dictionary.updateValue(Array(membersIDs.values) as AnyObject, forKey: "participantsIDs")
            }
            
            let metaInfo = Activity(dictionary: dictionary)
            activity.name = metaInfo.name
            activity.activityType = metaInfo.activityType
            activity.activityDescription = metaInfo.activityDescription
            activity.locationName = metaInfo.locationName
            activity.locationAddress = metaInfo.locationAddress
            activity.activityOriginalPhotoURL = metaInfo.activityOriginalPhotoURL
            activity.activityThumbnailPhotoURL = metaInfo.activityThumbnailPhotoURL
            activity.activityPhotos = metaInfo.activityPhotos
            activity.activityFiles = metaInfo.activityFiles
            activity.activityFiles = metaInfo.activityFiles
            activity.participantsIDs =  metaInfo.participantsIDs
            activity.transportation =  metaInfo.transportation
            activity.allDay =  metaInfo.allDay
            activity.startDateTime =  metaInfo.startDateTime
            activity.endDateTime =  metaInfo.endDateTime
            activity.notes =  metaInfo.notes
            activity.checklist =  metaInfo.checklist
            activity.activityID = metaInfo.activityID
            activity.conversationID = metaInfo.conversationID
            activity.checklistIDs = metaInfo.checklistIDs
            activity.activitylistIDs = metaInfo.activitylistIDs
            activity.grocerylistID = metaInfo.grocerylistID
            activity.packinglistIDs = metaInfo.packinglistIDs
            activity.transactionIDs = metaInfo.transactionIDs
            activity.admin = metaInfo.admin
            activity.schedule = metaInfo.schedule
            activity.purchases = metaInfo.purchases
            activity.recipeID = metaInfo.recipeID
            activity.servings = metaInfo.servings
            activity.workoutID = metaInfo.workoutID
            activity.eventID = metaInfo.eventID
            activity.placeID = metaInfo.placeID
                        
            self.prefetchThumbnail(from: activity.activityOriginalPhotoURL)
            
            self.updateActivityArrays(with: activity)
            
            if self.activityReferenceHandle.count > 0 {
                self.activityReference.removeObserver(withHandle: self.activityReferenceHandle[0].handle)
                self.activityReferenceHandle.remove(at: 0)
            }
        })
        
    }
    
    fileprivate func prefetchThumbnail(from urlString: String?) {
        if let thumbnail = urlString, let url = URL(string: thumbnail) {
            SDWebImagePrefetcher.shared.prefetchURLs([url])
        }
    }
    
    fileprivate func updateActivityArrays(with activity: Activity) {
        guard let activityID = activity.activityID else { return }
        if let index = activities.firstIndex(where: { (activity) -> Bool in
            return activity.activityID == activityID
        }) {
            update(activity: activity, at: index)
        } else {
            activities.append(activity)
            handleGroupOrReloadTable()
        }
    }
    
    func update(activity: Activity, at index: Int) {
        guard isGroupAlreadyFinished, (activities[index].muted != activity.muted) else {
            if isGroupAlreadyFinished && activities[index].pinned != activity.pinned {
                activities[index] = activity
                delegate?.activities(update: activities[index], reloadNeeded: false)
                return
            }
            
            activities[index] = activity
            // I don't think we need this?
            handleGroupOrReloadTable()
            delegate?.activities(update: activities[index], reloadNeeded: true)
            return
        }
        activities[index] = activity
        delegate?.activities(update: activities[index], reloadNeeded: true)
    }
    
    fileprivate func handleGroupOrReloadTable() {
        guard isGroupAlreadyFinished else {
            guard group != nil else {
                delegate?.activities(didFinishFetching: true, activities: activities)
                return
            }
            group.leave()
            return
        }
        delegate?.activities(didFinishFetching: true, activities: activities)
    }
    
    var activitiesChangesHandle = [(handle: DatabaseHandle, activityID: String)]()
    var groupConversationsChangesHandle = [(handle: DatabaseHandle, activityID: String)]()
    
    fileprivate func observeChangesForActivity(with activityID: String) {
        groupActivityReference = Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder)
        
        let handle = DatabaseHandle()
        let element = (handle: handle, activityID: activityID)
        activitiesChangesHandle.insert(element, at: 0)
        activitiesChangesHandle[0].handle = groupActivityReference.observe(.childChanged, with: { (snapshot) in
            
            self.handleActivityChanges(from: snapshot,
                                       activityID: activityID,
                                       nameKey: "name",
                                       typeKey: "activityType",
                                       descriptionKey: "activityDescription",
                                       locationNameKey: "locationName",
                                       locationAddressKey: "locationAddress",
                                       membersIDsKey: "participantsIDs",
                                       membersNamesKey: "participantsNames",
                                       transportationKey: "transportation",
                                       originalPhotoKey: "activityOriginalPhotoURL",
                                       thumbnailPhotoKey: "activityThumbnailPhotoURL",
                                       activityPhotosKey: "activityPhotos",
                                       activityFilesKey: "activityFiles",
                                       allDayKey: "allDay",
                                       startDateTimeKey: "startDateTime",
                                       endDateTimeKey: "endDateTime",
                                       notesKey: "notes",
                                       scheduleKey: "schedule",
                                       purchasesKey: "purchases",
                                       checklistKey: "checklist",
                                       grocerylistKey: "grocerylist",
                                       conversationKey: "conversationID",
                                       recipeKey: "recipeID",
                                       servingsKey: "servings",
                                       workoutKey: "workoutID",
                                       eventKey: "eventID",
                                       placeKey: "placeID",
                                       checklistIDsKey: "checklistIDs",
                                       activitylistIDsKey: "activitylistIDs",
                                       grocerylistIDKey: "grocerylistID",
                                       packinglistIDsKey: "packinglistIDs",
                                       transactionIDsKey: "transactionsIDKey")
        })
    }
    
    fileprivate func observeAdditionsForActivity(with activityID: String) {
        groupActivityReference = Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder)
        
        let handle = DatabaseHandle()
        let element = (handle: handle, activityID: activityID)
        activitiesChangesHandle.insert(element, at: 0)
        activitiesChangesHandle[0].handle = groupActivityReference.observe(.childAdded, with: { (snapshot) in
            
            guard self.isGroupAlreadyFinished else { return }
            
            self.handleActivityChanges(from: snapshot,
                                       activityID: activityID,
                                       nameKey: "name",
                                       typeKey: "activityType",
                                       descriptionKey: "activityDescription",
                                       locationNameKey: "locationName",
                                       locationAddressKey: "locationAddress",
                                       membersIDsKey: "participantsIDs",
                                       membersNamesKey: "participantsNames",
                                       transportationKey: "transportation",
                                       originalPhotoKey: "activityOriginalPhotoURL",
                                       thumbnailPhotoKey: "activityThumbnailPhotoURL",
                                       activityPhotosKey: "activityPhotos",
                                       activityFilesKey: "activityFiles",
                                       allDayKey: "allDay",
                                       startDateTimeKey: "startDateTime",
                                       endDateTimeKey: "endDateTime",
                                       notesKey: "notes",
                                       scheduleKey: "schedule",
                                       purchasesKey: "purchases",
                                       checklistKey: "checklist",
                                       grocerylistKey: "grocerylist",
                                       conversationKey: "conversationID",
                                       recipeKey: "recipeID",
                                       servingsKey: "servings",
                                       workoutKey: "workoutID",
                                       eventKey: "eventID",
                                       placeKey: "placeID",
                                       checklistIDsKey: "checklistIDs",
                                       activitylistIDsKey: "activitylistIDs",
                                       grocerylistIDKey: "grocerylistID",
                                       packinglistIDsKey: "packinglistIDs",
                                       transactionIDsKey: "transactionsIDKey")
        })
    }
    
    fileprivate func observeRemovalsForActivity(with activityID: String) {
        groupActivityReference = Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder)
        
        let handle = DatabaseHandle()
        let element = (handle: handle, activityID: activityID)
        activitiesChangesHandle.insert(element, at: 0)
        activitiesChangesHandle[0].handle = groupActivityReference.observe(.childRemoved, with: { (snapshot) in
            
            guard self.isGroupAlreadyFinished else { return }
            
            self.handleActivityRemovals(from: snapshot,
                                       activityID: activityID,
                                       nameKey: "name",
                                       typeKey: "activityType",
                                       descriptionKey: "activityDescription",
                                       locationNameKey: "locationName",
                                       locationAddressKey: "locationAddress",
                                       membersIDsKey: "participantsIDs",
                                       membersNamesKey: "participantsNames",
                                       transportationKey: "transportation",
                                       originalPhotoKey: "activityOriginalPhotoURL",
                                       thumbnailPhotoKey: "activityThumbnailPhotoURL",
                                       activityPhotosKey: "activityPhotos",
                                       activityFilesKey: "activityFiles",
                                       allDayKey: "allDay",
                                       startDateTimeKey: "startDateTime",
                                       endDateTimeKey: "endDateTime",
                                       notesKey: "notes",
                                       scheduleKey: "schedule",
                                       purchasesKey: "purchases",
                                       checklistKey: "checklist",
                                       grocerylistKey: "grocerylist",
                                       conversationKey: "conversationID",
                                       recipeKey: "recipeID",
                                       servingsKey: "servings",
                                       workoutKey: "workoutID",
                                       eventKey: "eventID",
                                       placeKey: "placeID",
                                       checklistIDsKey: "checklistIDs",
                                       activitylistIDsKey: "activitylistIDs",
                                       grocerylistIDKey: "grocerylistID",
                                       packinglistIDsKey: "packinglistIDs",
                                       transactionIDsKey: "transactionsIDKey")
        })
    }
    
    fileprivate func handleActivityChanges(from snapshot: DataSnapshot,
                                           activityID: String,
                                           nameKey: String,
                                           typeKey: String,
                                           descriptionKey: String,
                                           locationNameKey: String,
                                           locationAddressKey: String,
                                           membersIDsKey: String,
                                           membersNamesKey: String,
                                           transportationKey: String,
                                           originalPhotoKey: String,
                                           thumbnailPhotoKey: String,
                                           activityPhotosKey: String,
                                           activityFilesKey: String,
                                           allDayKey: String,
                                           startDateTimeKey: String,
                                           endDateTimeKey: String,
                                           notesKey: String,
                                           scheduleKey: String,
                                           purchasesKey: String,
                                           checklistKey: String,
                                           grocerylistKey: String,
                                           conversationKey: String,
                                           recipeKey: String,
                                           servingsKey: String,
                                           workoutKey: String,
                                           eventKey: String,
                                           placeKey: String,
                                           checklistIDsKey: String,
                                           activitylistIDsKey: String,
                                           grocerylistIDKey: String,
                                           packinglistIDsKey: String,
                                           transactionIDsKey: String) {
        
        guard let index = activities.firstIndex(where: { (activity) -> Bool in
            return activity.activityID == activityID
        }) else { return }
                
        if snapshot.key == nameKey {
            activities[index].name = snapshot.value as? String
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == typeKey {
            activities[index].activityType = snapshot.value as? String
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == descriptionKey {
            activities[index].activityDescription = snapshot.value as? String
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == locationNameKey {
            activities[index].locationName = snapshot.value as? String
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == locationAddressKey {
            activities[index].locationAddress = snapshot.value as? [String : [Double]]
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == membersIDsKey {
            guard let dictionary = snapshot.value as? [String: AnyObject] else { return }
            activities[index].participantsIDs = Array(dictionary.keys)
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == originalPhotoKey {
            activities[index].activityOriginalPhotoURL = snapshot.value as? String
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == thumbnailPhotoKey {
            activities[index].activityThumbnailPhotoURL = snapshot.value as? String
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == activityPhotosKey {
            activities[index].activityPhotos = snapshot.value as? [String]
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == activityFilesKey {
            activities[index].activityFiles = snapshot.value as? [String]
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == transportationKey {
            activities[index].transportation = snapshot.value as? String
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == allDayKey {
            activities[index].allDay = snapshot.value as? Bool
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == startDateTimeKey {
            activities[index].startDateTime = snapshot.value as? NSNumber
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == endDateTimeKey {
            activities[index].endDateTime = snapshot.value as? NSNumber
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == notesKey {
            activities[index].notes = snapshot.value as? String
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == scheduleKey {
            guard let scheduleFirebaseList = snapshot.value as? [AnyObject] else { return }
            var scheduleList = [Activity]()
            for schedule in scheduleFirebaseList {
                let sche = Activity(dictionary: schedule as? [String : AnyObject])
                if sche.name == "nothing" { continue }
                scheduleList.append(sche)
            }
            activities[index].schedule = scheduleList
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == purchasesKey {
            guard let purchasesFirebaseList = snapshot.value as? [AnyObject] else { return }
            var purchasesList = [Purchase]()
            for purchase in purchasesFirebaseList {
                let purch = Purchase(dictionary: purchase as? [String : AnyObject])
                if purch.name == "nothing" { continue }
                purchasesList.append(purch)
            }
            activities[index].purchases = purchasesList
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == checklistKey {
            guard let checklistFirebaseList = snapshot.value as? [Any] else { return }
            var checklistList = [Checklist]()
            for checklist in checklistFirebaseList {
                if let check = try? FirebaseDecoder().decode(Checklist.self, from: checklist) {
                    if check.name == "nothing" { continue }
                    checklistList.append(check)
                }
            }
            activities[index].checklist = checklistList
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == grocerylistKey {
            if let grocerylist = try? FirebaseDecoder().decode(Grocerylist.self, from: snapshot.value as Any) {
                activities[index].grocerylist = grocerylist
                delegate?.activities(update: activities[index], reloadNeeded: true)
            }
        }
        
        if snapshot.key == conversationKey {
            activities[index].conversationID = snapshot.value as? String
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == recipeKey {
            activities[index].recipeID = snapshot.value as? String
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == servingsKey {
            activities[index].servings = snapshot.value as? Int
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == workoutKey {
            activities[index].workoutID = snapshot.value as? String
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == eventKey {
            activities[index].eventID = snapshot.value as? String
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == placeKey {
            activities[index].placeID = snapshot.value as? String
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == checklistIDsKey {
            activities[index].checklistIDs = snapshot.value as? [String]
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == activitylistIDsKey {
            activities[index].activitylistIDs = snapshot.value as? [String]
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == grocerylistIDKey {
            activities[index].grocerylistID = snapshot.value as? String
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == packinglistIDsKey {
            activities[index].packinglistIDs = snapshot.value as? [String]
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == transactionIDsKey {
            activities[index].transactionIDs = snapshot.value as? [String]
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
    }
    
    fileprivate func handleActivityRemovals(from snapshot: DataSnapshot,
                                           activityID: String,
                                           nameKey: String,
                                           typeKey: String,
                                           descriptionKey: String,
                                           locationNameKey: String,
                                           locationAddressKey: String,
                                           membersIDsKey: String,
                                           membersNamesKey: String,
                                           transportationKey: String,
                                           originalPhotoKey: String,
                                           thumbnailPhotoKey: String,
                                           activityPhotosKey: String,
                                           activityFilesKey: String,
                                           allDayKey: String,
                                           startDateTimeKey: String,
                                           endDateTimeKey: String,
                                           notesKey: String,
                                           scheduleKey: String,
                                           purchasesKey: String,
                                           checklistKey: String,
                                           grocerylistKey: String,
                                           conversationKey: String,
                                           recipeKey: String,
                                           servingsKey: String,
                                           workoutKey: String,
                                           eventKey: String,
                                           placeKey: String,
                                           checklistIDsKey: String,
                                           activitylistIDsKey: String,
                                           grocerylistIDKey: String,
                                           packinglistIDsKey: String,
                                           transactionIDsKey: String) {
        
        guard let index = activities.firstIndex(where: { (activity) -> Bool in
            return activity.activityID == activityID
        }) else { return }
        
        if snapshot.key == nameKey {
            activities[index].name = String()
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == typeKey {
            activities[index].activityType = String()
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == descriptionKey {
            activities[index].activityDescription = String()
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == locationNameKey {
            activities[index].locationName = String()
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == locationAddressKey {
            activities[index].locationAddress = [String : [Double]]()
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == originalPhotoKey {
            activities[index].activityOriginalPhotoURL = String()
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == thumbnailPhotoKey {
            activities[index].activityThumbnailPhotoURL = String()
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == activityPhotosKey {
            activities[index].activityPhotos = [String]()
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == activityFilesKey {
            activities[index].activityFiles = [String]()
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == transportationKey {
            activities[index].transportation = String()
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == notesKey {
            activities[index].notes = String()
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
                
        if snapshot.key == scheduleKey {
            activities[index].schedule = [Activity]()
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == purchasesKey {
            activities[index].purchases = [Purchase]()
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == checklistKey {
            activities[index].checklist = [Checklist]()
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == grocerylistKey {
            activities[index].grocerylist = nil
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == conversationKey {
            activities[index].conversationID = String()
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == recipeKey {
            activities[index].recipeID = String()
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == servingsKey {
            activities[index].servings = Int()
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == workoutKey {
            activities[index].workoutID = String()
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == eventKey {
            activities[index].eventID = String()
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == placeKey {
            activities[index].placeID = String()
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == checklistIDsKey {
            activities[index].checklistIDs = [String]()
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == activitylistIDsKey {
            activities[index].activitylistIDs = [String]()
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == grocerylistIDKey {
            activities[index].grocerylistID = String()
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == packinglistIDsKey {
            activities[index].packinglistIDs = [String]()
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
        
        if snapshot.key == transactionIDsKey {
            activities[index].transactionIDs = [String]()
            delegate?.activities(update: activities[index], reloadNeeded: true)
        }
    }
}
