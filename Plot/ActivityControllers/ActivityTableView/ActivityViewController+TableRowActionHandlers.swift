//
//  ActivityTableViewController+TableRowActionHandlers.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 4/27/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit
import Firebase

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}

private let pinErrorTitle = "Error pinning/unpinning"
private let pinErrorMessage = "Changes won't be saved across app restarts. Check your internet connection, re-launch the app, and try again."
private let muteErrorTitle = "Error muting/unmuting"
private let muteErrorMessage = "Check your internet connection and try again."

extension ActivityViewController {
    
    fileprivate func delayWithSeconds(_ seconds: Double, completion: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            completion()
        }
    }
    
    func setupMuteAction(at indexPath: IndexPath) -> UITableViewRowAction {
        let mute = UITableViewRowAction(style: .default, title: "Mute") { _, _ in
            if indexPath.section == 0 {
                if #available(iOS 11.0, *) {} else {
                    self.activityView.tableView.setEditing(false, animated: true)
                }
                self.delayWithSeconds(1, completion: {
                    self.handleMuteActivity(section: indexPath.section, for: self.filteredPinnedActivities[indexPath.row])
                })
            } else if indexPath.section == 1 {
                if #available(iOS 11.0, *) {} else {
                    self.activityView.tableView.setEditing(false, animated: true)
                }
                self.delayWithSeconds(1, completion: {
                    self.handleMuteActivity(section: indexPath.section, for: self.filteredActivities[indexPath.row])
                })
            }
        }
        
        if indexPath.section == 0 {
            let isPinnedActivityMuted = filteredPinnedActivities[indexPath.row].muted == true
            let muteTitle = isPinnedActivityMuted ? "Unmute" : "Mute"
            mute.title = muteTitle
        } else if indexPath.section == 1 {
            let isActivityMuted = filteredActivities[indexPath.row].muted == true
            let muteTitle = isActivityMuted ? "Unmute" : "Mute"
            mute.title = muteTitle
        }
        mute.backgroundColor = UIColor(red:0.56, green:0.64, blue:0.68, alpha:1.0)
        return mute
    }
    
    func setupPinAction(at indexPath: IndexPath) -> UITableViewRowAction {
        let pin = UITableViewRowAction(style: .default, title: "Pin") { _, _ in
            if indexPath.section == 0 {
                self.unpinActivity(at: indexPath)
            } else if indexPath.section == 1 {
                self.pinActivity(at: indexPath)
            }
        }
        
        let pinTitle = indexPath.section == 0 ? "Unpin" : "Pin"
        pin.title = pinTitle
        pin.backgroundColor = UIColor(red:0.96, green:0.49, blue:0.00, alpha:1.0)
        return pin
    }
    
    func setupDeleteAction(at indexPath: IndexPath) -> UITableViewRowAction {
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { action, index in
            if self.currentReachabilityStatus == .notReachable {
                basicErrorAlertWith(title: "Error deleting message", message: noInternetError, controller: self)
                return
            }
            if indexPath.section == 0 {
                self.deletePinnedActivity(at: indexPath)
            } else if indexPath.section == 1 {
                self.deleteUnPinnedActivity(at: indexPath)
            }
        }
        
        delete.backgroundColor = UIColor(red:0.90, green:0.22, blue:0.21, alpha:1.0)
        return delete
    }
    func unpinActivity(at indexPath: IndexPath) {
        let activity = filteredPinnedActivities[indexPath.row]
        guard let currentUserID = Auth.auth().currentUser?.uid, let activityID = activity.activityID else { return }
        
        guard let index = pinnedActivities.firstIndex(where: { (activity) -> Bool in
            return activity.activityID == filteredPinnedActivities[indexPath.row].activityID
        }) else { return }
        
        self.activityView.tableView.beginUpdates()
        let pinnedElement = filteredPinnedActivities[indexPath.row]
        
        let filteredIndexToInsert = filteredActivities.insertionIndex(of: pinnedElement, using: { (activity1, activity2) -> Bool in
            return activity1.startDateTime?.int32Value < activity2.startDateTime?.int32Value
        })
        
        let unfilteredIndexToInsert = activities.insertionIndex(of: pinnedElement, using: { (activity1, activity2) -> Bool in
            return activity1.startDateTime?.int32Value < activity2.startDateTime?.int32Value
        })
        
        filteredActivities.insert(pinnedElement, at: filteredIndexToInsert)
        activities.insert(pinnedElement, at: unfilteredIndexToInsert)
        filteredPinnedActivities.remove(at: indexPath.row)
        pinnedActivities.remove(at: index)
        let destinationIndexPath = IndexPath(row: filteredIndexToInsert, section: 1)
        
        activityView.tableView.deleteRows(at: [indexPath], with: .bottom)
        activityView.tableView.insertRows(at: [destinationIndexPath], with: .bottom)
        activityView.tableView.endUpdates()
        
        let metadataRef = Database.database().reference().child("user-activities").child(currentUserID).child(activityID).child(messageMetaDataFirebaseFolder)
        metadataRef.updateChildValues(["pinned": false], withCompletionBlock: { (error, reference) in
            if error != nil {
                basicErrorAlertWith(title: pinErrorTitle , message: pinErrorMessage, controller: self)
                return
            }
        })
    }
    
    func pinActivity(at indexPath: IndexPath) {
        
        let activity = self.filteredActivities[indexPath.row]
        guard let currentUserID = Auth.auth().currentUser?.uid, let activityID = activity.activityID else { return }
        
        guard let index = activities.firstIndex(where: { (activity) -> Bool in
            return activity.activityID == self.filteredActivities[indexPath.row].activityID
        }) else { return }
        
        self.activityView.tableView.beginUpdates()
        let elementToPin = filteredActivities[indexPath.row]
        
        let filteredIndexToInsert = filteredPinnedActivities.insertionIndex(of: elementToPin, using: { (activity1, activity2) -> Bool in
            return activity1.startDateTime?.int32Value < activity2.startDateTime?.int32Value
        })
        
        let unfilteredIndexToInsert = pinnedActivities.insertionIndex(of: elementToPin, using: { (activity1, activity2) -> Bool in
            return activity1.startDateTime?.int32Value < activity2.startDateTime?.int32Value
        })
        
        filteredPinnedActivities.insert(elementToPin, at: filteredIndexToInsert)
        pinnedActivities.insert(elementToPin, at: unfilteredIndexToInsert)
        filteredActivities.remove(at: indexPath.row)
        activities.remove(at: index)
        let destinationIndexPath = IndexPath(row: filteredIndexToInsert, section: 0)
        
        activityView.tableView.deleteRows(at: [indexPath], with: .top)
        activityView.tableView.insertRows(at: [destinationIndexPath], with: .top)
        activityView.tableView.endUpdates()
        
        let metadataReference = Database.database().reference().child("user-activities").child(currentUserID).child(activityID).child(messageMetaDataFirebaseFolder)
        metadataReference.updateChildValues(["pinned": true], withCompletionBlock: { (error, reference) in
            if error != nil {
                basicErrorAlertWith(title: pinErrorTitle, message: pinErrorMessage, controller: self)
                return
            }
        })
    }
    
    func deletePinnedActivity(at indexPath: IndexPath) {
        let activity = filteredPinnedActivities[indexPath.row]
        guard let currentUserID = Auth.auth().currentUser?.uid, let activityID = activity.activityID  else { return }
        
        guard let index = pinnedActivities.firstIndex(where: { (activity) -> Bool in
            return activity.activityID == self.filteredPinnedActivities[indexPath.row].activityID
        }) else { return }
        
        activityView.tableView.beginUpdates()
        filteredPinnedActivities.remove(at: indexPath.row)
        pinnedActivities.remove(at: index)
        
        if let invitation = invitations.removeValue(forKey: activityID) {
            InvitationsFetcher.remove(invitation: invitation)
        }
        
        activityView.tableView.deleteRows(at: [indexPath], with: .left)
        activityView.tableView.endUpdates()
        
    Database.database().reference().child("user-activities").child(currentUserID).child(activityID).child(messageMetaDataFirebaseFolder).removeAllObservers()
        Database.database().reference().child("user-activities").child(currentUserID).child(activityID).removeValue()
    
        let activityDataReference = Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder)
        activityDataReference.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionary = snapshot.value as? [String: AnyObject] else { return }
            if let membersIDs = dictionary["participantsIDs"] as? [String:AnyObject] {
                var varMemberIDs = membersIDs
                varMemberIDs[currentUserID] = nil
                activityDataReference.updateChildValues(["participantsIDs": varMemberIDs as AnyObject])
            }
        })
        
        configureTabBarBadge()
        if activities.count <= 0 && pinnedActivities.count <= 0 {
            DispatchQueue.main.async {
                self.checkIfThereAnyActivities(isEmpty: true)
            }
        }
    }
    
    func deleteUnPinnedActivity(at indexPath: IndexPath) {
        let activity = filteredActivities[indexPath.row]
        guard let currentUserID = Auth.auth().currentUser?.uid, let activityID = activity.activityID  else { return }
        
        guard let index = activities.firstIndex(where: { (activity) -> Bool in
            return activity.activityID == self.filteredActivities[indexPath.row].activityID
        }) else { return }
        
        activityView.tableView.beginUpdates()
        filteredActivities.remove(at: indexPath.row)
        activities.remove(at: index)
        
        if let invitation = invitations.removeValue(forKey: activityID) {
            InvitationsFetcher.remove(invitation: invitation)
        }
        
        activityView.tableView.deleteRows(at: [indexPath], with: .left)
        activityView.tableView.endUpdates()
    Database.database().reference().child("user-activities").child(currentUserID).child(activityID).child(messageMetaDataFirebaseFolder).removeAllObservers()
        Database.database().reference().child("user-activities").child(currentUserID).child(activityID).removeValue()
    
        let activityDataReference = Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder)
        activityDataReference.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionary = snapshot.value as? [String: AnyObject] else { return }
            if let membersIDs = dictionary["participantsIDs"] as? [String:AnyObject] {
                var varMemberIDs = membersIDs
                varMemberIDs[currentUserID] = nil
                activityDataReference.updateChildValues(["participantsIDs": varMemberIDs as AnyObject])
            }

        })
        
        configureTabBarBadge()
        if activities.count <= 0 && pinnedActivities.count <= 0 {
            DispatchQueue.main.async {
                self.checkIfThereAnyActivities(isEmpty: true)
            }
        }
    }
    
    fileprivate func updateMutedDatabaseValue(to state: Bool, currentUserID: String, activityID: String) {
        
        let metadataReference = Database.database().reference().child("user-activities").child(currentUserID).child(activityID).child(messageMetaDataFirebaseFolder)
        metadataReference.updateChildValues(["muted": state], withCompletionBlock: { (error, reference) in
            if error != nil {
                basicErrorAlertWith(title: muteErrorTitle, message: muteErrorMessage, controller: self)
            }
        })
    }
    
    func handleMuteActivity(section: Int, for activity: Activity) {
        
        guard let currentUserID = Auth.auth().currentUser?.uid, let activityID = activity.activityID else { return }
        
        if section == 0 {
            guard activity.muted != nil else {
                updateMutedDatabaseValue(to: true, currentUserID: currentUserID, activityID: activityID)
                return
            }
            guard activity.muted! else {
                updateMutedDatabaseValue(to: true, currentUserID: currentUserID, activityID: activityID)
                return
            }
            updateMutedDatabaseValue(to: false, currentUserID: currentUserID, activityID: activityID)
            
        } else if section == 1 {
            guard activity.muted != nil else {
                updateMutedDatabaseValue(to: true, currentUserID: currentUserID, activityID: activityID)
                return
            }
            guard activity.muted! else {
                updateMutedDatabaseValue(to: true, currentUserID: currentUserID, activityID: activityID)
                return
            }
            updateMutedDatabaseValue(to: false, currentUserID: currentUserID, activityID: activityID)
        }
    }
}
