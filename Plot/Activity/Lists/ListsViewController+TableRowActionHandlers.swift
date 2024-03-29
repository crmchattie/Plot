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

extension ListsViewController {
    
//    fileprivate func delayWithSeconds(_ seconds: Double, completion: @escaping () -> ()) {
//        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
//            completion()
//        }
//    }

//    func setupMuteAction(at indexPath: IndexPath) -> UITableViewRowAction {
//        let mute = UITableViewRowAction(style: .default, title: "Mute") { _, _ in
//            if #available(iOS 11.0, *) {} else {
//                self.tableView.setEditing(false, animated: true)
//            }
//            self.delayWithSeconds(1, completion: {
//                self.handleMute(section: indexPath.section, for: self.lists[indexPath.row])
//            })
//        }
//
//        let isMuted = lists[indexPath.row].muted == true
//        let muteTitle = isMuted ? "Unmute" : "Mute"
//        mute.title = muteTitle
//        mute.backgroundColor = UIColor(red:0.56, green:0.64, blue:0.68, alpha:1.0)
//        return mute
//    }
//
//    func setupDeleteAction(at indexPath: IndexPath) -> UITableViewRowAction {
//
//        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { action, index in
//            if self.currentReachabilityStatus == .notReachable {
//                basicErrorAlertWithClose(title: "Error deleting message", message: noInternetError, controller: self)
//                return
//            }
//            if indexPath.section == 0 {
//                self.deleteList(at: indexPath)
//            }
//        }
//
//        delete.backgroundColor = UIColor(red:0.90, green:0.22, blue:0.21, alpha:1.0)
//        return delete
//    }
//
//    func deleteList(at indexPath: IndexPath) {
//        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
//        let list = lists[indexPath.row]
//
//
////        configureTabBarBadge()
//        if lists.count <= 0 {
//            DispatchQueue.main.async {
//                self.checkIfThereAreAnyResults(isEmpty: true)
//            }
//        }
//    }

//    fileprivate func updateMutedDatabaseValue(to state: Bool, currentUserID: String, list: ListType) {
//
//    }
//
//    func handleMute(section: Int, for list: ListType) {
//        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
//
//        if section == 0 {
//            guard list.muted ?? false else {
//                updateMutedDatabaseValue(to: true, currentUserID: currentUserID, list: list)
//                return
//            }
//            updateMutedDatabaseValue(to: false, currentUserID: currentUserID, list: list)
//
//        }
//    }
}
