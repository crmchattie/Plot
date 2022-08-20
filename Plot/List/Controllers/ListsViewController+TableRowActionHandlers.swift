//
//  ListViewControllerwActionHandlers.swift
//  Plot
//
//  Created by Cory McHattie on 5/26/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
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

extension ListViewController {
    
    fileprivate func delayWithSeconds(_ seconds: Double, completion: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            completion()
        }
    }

    func setupMuteAction(at indexPath: IndexPath) -> UITableViewRowAction {
        let mute = UITableViewRowAction(style: .default, title: "Mute") { _, _ in
            if #available(iOS 11.0, *) {} else {
                self.tableView.setEditing(false, animated: true)
            }
            self.delayWithSeconds(1, completion: {
                self.handleMute(section: indexPath.section, for: self.listList[indexPath.row])
            })
        }

        let isMuted = listList[indexPath.row].muted == true
        let muteTitle = isMuted ? "Unmute" : "Mute"
        mute.title = muteTitle
        mute.backgroundColor = UIColor(red:0.56, green:0.64, blue:0.68, alpha:1.0)
        return mute
    }

    func setupDeleteAction(at indexPath: IndexPath) -> UITableViewRowAction {

        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { action, index in
            if self.currentReachabilityStatus == .notReachable {
                basicErrorAlertWith(title: "Error deleting message", message: noInternetError, controller: self)
                return
            }
            if indexPath.section == 0 {
                self.deleteList(at: indexPath)
            }
        }

        delete.backgroundColor = UIColor(red:0.90, green:0.22, blue:0.21, alpha:1.0)
        return delete
    }

    func deleteList(at indexPath: IndexPath) {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        let list = listList[indexPath.row]
        if list.type == "grocerylist" {
            if let index = self.grocerylists.firstIndex(where: {$0 == list.grocerylist}) {
                tableView.beginUpdates()
                listList.remove(at: indexPath.row)
                grocerylists.remove(at: index)

                tableView.deleteRows(at: [indexPath], with: .left)
                tableView.endUpdates()
            Database.database().reference().child(userGrocerylistsEntity).child(currentUserID).child(list.ID).removeAllObservers()
            Database.database().reference().child(userGrocerylistsEntity).child(currentUserID).child(list.ID).removeValue()

                let dataReference = Database.database().reference().child(grocerylistsEntity).child(list.ID)
                dataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    guard let dictionary = snapshot.value as? [String: AnyObject] else { return }
                    if let membersIDs = dictionary["participantsIDs"] as? [String:AnyObject] {
                        var varMemberIDs = membersIDs
                        varMemberIDs[currentUserID] = nil
                        dataReference.updateChildValues(["participantsIDs": varMemberIDs as AnyObject])
                    }
                })
            }
        } else if list.type == "checklist" {
            if let index = self.checklists.firstIndex(where: {$0 == list.checklist}) {
                tableView.beginUpdates()
                listList.remove(at: indexPath.row)
                checklists.remove(at: index)

                tableView.deleteRows(at: [indexPath], with: .left)
                tableView.endUpdates()
                Database.database().reference().child(userChecklistsEntity).child(currentUserID).child(list.ID).removeAllObservers()
                Database.database().reference().child(userChecklistsEntity).child(currentUserID).child(list.ID).removeValue()

                let dataReference = Database.database().reference().child(checklistsEntity).child(list.ID)
                dataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    guard let dictionary = snapshot.value as? [String: AnyObject] else { return }
                    if let membersIDs = dictionary["participantsIDs"] as? [String:AnyObject] {
                        var varMemberIDs = membersIDs
                        varMemberIDs[currentUserID] = nil
                        dataReference.updateChildValues(["participantsIDs": varMemberIDs as AnyObject])
                    }
                })
            }
        } else if list.type == "activitylist" {
            if let index = self.activitylists.firstIndex(where: {$0 == list.activitylist}) {
                tableView.beginUpdates()
                listList.remove(at: indexPath.row)
                activitylists.remove(at: index)

                tableView.deleteRows(at: [indexPath], with: .left)
                tableView.endUpdates()
                Database.database().reference().child(userActivitylistsEntity).child(currentUserID).child(list.ID).removeAllObservers()
                Database.database().reference().child(userActivitylistsEntity).child(currentUserID).child(list.ID).removeValue()

                let dataReference = Database.database().reference().child(activitylistsEntity).child(list.ID)
                dataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    guard let dictionary = snapshot.value as? [String: AnyObject] else { return }
                    if let membersIDs = dictionary["participantsIDs"] as? [String:AnyObject] {
                        var varMemberIDs = membersIDs
                        varMemberIDs[currentUserID] = nil
                        dataReference.updateChildValues(["participantsIDs": varMemberIDs as AnyObject])
                    }
                })
            }
        }

//        configureTabBarBadge()
        if listList.count <= 0 {
            DispatchQueue.main.async {
                self.checkIfThereAreAnyResults(isEmpty: true)
            }
        }
    }

    fileprivate func updateMutedDatabaseValue(to state: Bool, currentUserID: String, list: ListContainer) {
        if list.type == "grocerylist" {
            let metadataReference = Database.database().reference().child(userGrocerylistsEntity).child(currentUserID).child(list.ID).child(messageMetaDataFirebaseFolder)
            metadataReference.updateChildValues(["muted": state], withCompletionBlock: { (error, reference) in
                if error != nil {
                    basicErrorAlertWith(title: muteErrorTitle, message: muteErrorMessage, controller: self)
                }
            })
        } else if list.type == "checklist" {
            let metadataReference = Database.database().reference().child(userChecklistsEntity).child(currentUserID).child(list.ID).child(messageMetaDataFirebaseFolder)
            metadataReference.updateChildValues(["muted": state], withCompletionBlock: { (error, reference) in
                if error != nil {
                    basicErrorAlertWith(title: muteErrorTitle, message: muteErrorMessage, controller: self)
                }
            })
        } else if list.type == "activitylist" {
            let metadataReference = Database.database().reference().child(userActivitylistsEntity).child(currentUserID).child(list.ID).child(messageMetaDataFirebaseFolder)
            metadataReference.updateChildValues(["muted": state], withCompletionBlock: { (error, reference) in
                if error != nil {
                    basicErrorAlertWith(title: muteErrorTitle, message: muteErrorMessage, controller: self)
                }
            })
        } else if list.type == "packinglist" {
            let metadataReference = Database.database().reference().child(userPackinglistsEntity).child(currentUserID).child(list.ID).child(messageMetaDataFirebaseFolder)
            metadataReference.updateChildValues(["muted": state], withCompletionBlock: { (error, reference) in
                if error != nil {
                    basicErrorAlertWith(title: muteErrorTitle, message: muteErrorMessage, controller: self)
                }
            })
        }
    }

    func handleMute(section: Int, for list: ListContainer) {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        if section == 0 {
            guard list.muted else {
                updateMutedDatabaseValue(to: true, currentUserID: currentUserID, list: list)
                return
            }
            updateMutedDatabaseValue(to: false, currentUserID: currentUserID, list: list)

        }
    }
}
