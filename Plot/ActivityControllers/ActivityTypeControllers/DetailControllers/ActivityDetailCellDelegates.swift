//
//  ActivityDetailPlusButtonExtensions.swift
//  Plot
//
//  Created by Cory McHattie on 4/15/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase

extension MealDetailViewController: ActivityDetailCellDelegate {
    func plusButtonTapped(type: Any) {
        print("plusButtonTapped")
        
        if active, schedule, let activity = activity {
            let membersIDs = self.fetchMembersIDs()
            activity.participantsIDs = membersIDs.0
            
            self.delegate?.updateSchedule(schedule: activity)
            self.navigationController?.backToViewController(viewController: CreateActivityViewController.self)
                
        }
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if active, let activity = activity {
            alert.addAction(UIAlertAction(title: "Update Activity", style: .default, handler: { (_) in
                print("User click Approve button")
                                
                // update activity
                self.showActivityIndicator()
                let createActivity = ActivityActions(activity: activity, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                createActivity.createNewActivity()
                self.hideActivityIndicator()
                
                if self.conversation == nil {
                    self.navigationController?.backToViewController(viewController: ActivityViewController.self)
                } else {
                    self.navigationController?.backToViewController(viewController: ChatLogController.self)
                }
                
            }))
            
            if !self.schedule {
                alert.addAction(UIAlertAction(title: "Duplicate Activity", style: .default, handler: { (_) in
                    print("User click Approve button")
                    // create new activity with updated time
                    guard self.currentReachabilityStatus != .notReachable else {
                        basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
                        return
                    }
                    
                    let membersIDs = self.fetchMembersIDs()
                    activity.participantsIDs = membersIDs.0
                    
                    var newActivityID: String!
                    let newActivity = activity
                                
                    if let currentUserID = Auth.auth().currentUser?.uid {
                        newActivityID = Database.database().reference().child("user-activities").child(currentUserID).childByAutoId().key ?? ""
                        
                        let original = Date()
                        let rounded = Date(timeIntervalSinceReferenceDate:
                        (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                        let timezone = TimeZone.current
                        let seconds = TimeInterval(timezone.secondsFromGMT(for: Date()))
                        self.startDateTime = rounded.addingTimeInterval(seconds)
                        self.endDateTime = self.startDateTime!.addingTimeInterval(Double(self.recipe?.readyInMinutes ?? 0) * 60)
                        
                        newActivity.activityID = newActivityID
                        newActivity.startDateTime = NSNumber(value: Int((self.startDateTime!).timeIntervalSince1970))
                        newActivity.endDateTime = NSNumber(value: Int((self.endDateTime!).timeIntervalSince1970))
                        
                        self.showActivityIndicator()
                        let createActivity = ActivityActions(activity: newActivity, active: !self.active, selectedFalconUsers: self.selectedFalconUsers)
                        createActivity.createNewActivity()
                        self.hideActivityIndicator()
                        
                        if self.conversation == nil {
                            self.navigationController?.backToViewController(viewController: ActivityViewController.self)
                        } else {
                            self.navigationController?.backToViewController(viewController: ChatLogController.self)
                        }
                    }
                    

                }))
                
                alert.addAction(UIAlertAction(title: "Merge with Activity", style: .default, handler: { (_) in
                    print("User click Edit button")
                    
                    let membersIDs = self.fetchMembersIDs()
                    activity.participantsIDs = membersIDs.0
                    
                    // ChooseActivityTableViewController
                    let destination = ChooseActivityTableViewController()
                    let navController = UINavigationController(rootViewController: destination)
                    destination.delegate = self
                    destination.activity = activity
                    destination.activities = self.activities
                    destination.filteredActivities = self.activities
                    self.present(navController, animated: true, completion: nil)
                
                }))
                
                alert.addAction(UIAlertAction(title: "Duplicate & Merge with Activity", style: .default, handler: { (_) in
                    print("User click Edit button")
                    
                    if let currentUserID = Auth.auth().currentUser?.uid {
                        
                        let membersIDs = self.fetchMembersIDs()
                        activity.participantsIDs = membersIDs.0
                        
                        //duplicate activity
                        let newActivityID = Database.database().reference().child("user-activities").child(currentUserID).childByAutoId().key ?? ""
                        let newActivity = Activity(dictionary: ["activityID": newActivityID as AnyObject])
                        newActivity.name = activity.name
                        newActivity.activityType = activity.activityType
                        newActivity.recipeID = activity.recipeID
                        newActivity.startDateTime = activity.startDateTime
                        newActivity.endDateTime = activity.endDateTime
                        newActivity.allDay = activity.allDay
                        newActivity.participantsIDs = activity.participantsIDs
                        newActivity.locationName = activity.locationName
                        newActivity.locationAddress = activity.locationAddress
                        newActivity.reminder = activity.reminder
                        
                        self.showActivityIndicator()
                        let createActivity = ActivityActions(activity: newActivity, active: !self.active, selectedFalconUsers: self.selectedFalconUsers)
                        createActivity.createNewActivity()
                        self.hideActivityIndicator()
                        
                        // ChooseActivityTableViewController
                        let destination = ChooseActivityTableViewController()
                        let navController = UINavigationController(rootViewController: destination)
                        destination.delegate = self
                        destination.activity = activity
                        destination.activities = self.activities
                        destination.filteredActivities = self.activities
                        self.present(navController, animated: true, completion: nil)
                    }
                
                }))
            }
            
        } else if schedule, let _ = umbrellaActivity {
            alert.addAction(UIAlertAction(title: "Add to Schedule", style: .default, handler: { (_) in
                print("User click Approve button")
                if let activity = self.activity {
                    activity.name = self.recipe?.title
                    
                    let membersIDs = self.fetchMembersIDs()
                    self.activity.participantsIDs = membersIDs.0
                    
                    self.delegate?.updateSchedule(schedule: activity)
                    
                    self.navigationController?.backToViewController(viewController: CreateActivityViewController.self)
                }
            }))
            
        } else if !schedule {
            alert.addAction(UIAlertAction(title: "Create New Activity", style: .default, handler: { (_) in
                print("User click Approve button")
                // create new activity
                
                if let activity = self.activity {
                    activity.name = self.recipe?.title
                    
                    let membersIDs = self.fetchMembersIDs()
                    activity.participantsIDs = membersIDs.0
                    
                    self.showActivityIndicator()
                    let createActivity = ActivityActions(activity: activity, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    createActivity.createNewActivity()
                    self.hideActivityIndicator()
                                        
                    if self.conversation == nil {
                        self.navigationController?.backToViewController(viewController: ActivityViewController.self)
                    } else {
                        self.navigationController?.backToViewController(viewController: ChatLogController.self)
                    }
                }
                
            }))
            
            alert.addAction(UIAlertAction(title: "Merge with Existing Activity", style: .default, handler: { (_) in
                
                if let activity = self.activity {
                    activity.name = self.recipe?.title
                    
                    let membersIDs = self.fetchMembersIDs()
                    activity.participantsIDs = membersIDs.0
                    
                    // ChooseActivityTableViewController
                    let destination = ChooseActivityTableViewController()
                    let navController = UINavigationController(rootViewController: destination)
                    destination.delegate = self
                    destination.activity = activity
                    destination.activities = self.activities
                    destination.filteredActivities = self.activities
                    self.present(navController, animated: true, completion: nil)
                }
            
            }))

        }
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))

        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
    
    func shareButtonTapped(activityObject: ActivityObject) {
        
        if let activity = activity {
            activityObject.activityID = activity.activityID
        }
        
        let alert = UIAlertController(title: "Share Activity", message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Inside of Plot", style: .default, handler: { (_) in
            print("User click Approve button")
            let destination = ChooseChatTableViewController()
            let navController = UINavigationController(rootViewController: destination)
            destination.activityObject = activityObject
            destination.users = self.users
            destination.filteredUsers = self.filteredUsers
            destination.conversations = self.conversations
            destination.filteredConversations = self.conversations
            destination.filteredPinnedConversations = self.conversations
            self.present(navController, animated: true, completion: nil)
            
        }))

        alert.addAction(UIAlertAction(title: "Outside of Plot", style: .default, handler: { (_) in
            print("User click Edit button")
                // Fallback on earlier versions
            let shareText = "Hey! Download Plot on the App Store so I can share an activity with you."
            guard let url = URL(string: "https://apps.apple.com/us/app/plot-scheduling-app/id1473764067?ls=1")
                else { return }
            let shareContent: [Any] = [shareText, url]
            let activityController = UIActivityViewController(activityItems: shareContent,
                                                              applicationActivities: nil)
            self.present(activityController, animated: true, completion: nil)
            activityController.completionWithItemsHandler = { (activityType: UIActivity.ActivityType?, completed:
            Bool, arrayReturnedItems: [Any]?, error: Error?) in
                if completed {
                    print("share completed")
                    return
                } else {
                    print("cancel")
                }
                if let shareError = error {
                    print("error while sharing: \(shareError.localizedDescription)")
                }
            }
            
        }))
        

        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))

        self.present(alert, animated: true, completion: {
            print("completion block")
        })
        print("shareButtonTapped")
    }
    
    func heartButtonTapped(type: Any) {
        print("heartButtonTapped")
        if let currentUserID = Auth.auth().currentUser?.uid {
            let databaseReference = Database.database().reference().child("user-fav-activities").child(currentUserID)
            if let recipe = type as? Recipe {
                print(recipe.title)
                databaseReference.child("recipes").observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists() {
                        var value = snapshot.value as! [String]
                        if value.contains("\(recipe.id)") {
                            if let index = value.firstIndex(of: "\(recipe.id)") {
                                value.remove(at: index)
                            }
                            databaseReference.updateChildValues(["recipes": value as NSArray])
                        } else {
                            value.append("\(recipe.id)")
                            databaseReference.updateChildValues(["recipes": value as NSArray])
                        }
                        self.favAct["recipes"] = value
                    } else {
                        self.favAct["recipes"] = ["\(recipe.id)"]
                        databaseReference.updateChildValues(["recipes": ["\(recipe.id)"]])
                    }
                })
            }
        }
        
    }
    
    func dotsButtonTapped() {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            if activity.conversationID == nil {
                alert.addAction(UIAlertAction(title: "Connect Activity to a Chat", style: .default, handler: { (_) in
                    print("User click Approve button")
                    self.goToChat()

                }))
            } else {
                alert.addAction(UIAlertAction(title: "Go to Chat", style: .default, handler: { (_) in
                    print("User click Approve button")
                    self.goToChat()

                }))
            }
                
            if let localName = activity.locationName, localName != "locationName", let localAddress = activity.locationAddress {
                alert.addAction(UIAlertAction(title: "Go to Map", style: .default, handler: { (_) in
                    print("User click Edit button")
                    self.goToMap(locationAddress: localAddress)
                }))
            }
               

           alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { (_) in
               print("User click Dismiss button")
           }))

           self.present(alert, animated: true, completion: {
               print("completion block")
           })
            print("shareButtonTapped")
            
        }

}

extension MealDetailViewController: ChooseActivityDelegate {
    func chosenActivity(mergeActivity: Activity) {
        if let activity = activity {
            if mergeActivity.recipeID != nil || mergeActivity.workoutID != nil || mergeActivity.eventID != nil {
                if let currentUserID = Auth.auth().currentUser?.uid {
                    let newActivityID = Database.database().reference().child("user-activities").child(currentUserID).childByAutoId().key ?? ""
                    let newActivity = Activity(dictionary: ["activityID": newActivityID as AnyObject])
                    newActivity.name = mergeActivity.name
                    newActivity.startDateTime = mergeActivity.startDateTime
                    newActivity.endDateTime = mergeActivity.endDateTime
                    newActivity.allDay = mergeActivity.allDay
                    newActivity.participantsIDs = mergeActivity.participantsIDs
                    newActivity.locationName = mergeActivity.locationName
                    newActivity.locationAddress = mergeActivity.locationAddress
                    newActivity.reminder = mergeActivity.reminder
                    
                    if let oldParticipantsIDs = activity.participantsIDs {
                        if let newParticipantsIDs = newActivity.participantsIDs {
                            for id in oldParticipantsIDs {
                                if !newParticipantsIDs.contains(id) {
                                    newActivity.participantsIDs!.append(id)
                                }
                            }
                        } else {
                            newActivity.participantsIDs = activity.participantsIDs
                        }
                    }
                    mergeActivity.participantsIDs = newActivity.participantsIDs
                    activity.participantsIDs = newActivity.participantsIDs
                    
                    let scheduleList = [mergeActivity, activity]
                    newActivity.schedule = scheduleList
                                       
                    self.showActivityIndicator()
                    
                    // need to delete current activity and merge activity
                    if active {
                        self.getSelectedFalconUsers(forActivity: mergeActivity) { (participants) in
                            let deleteFirstActivity = ActivityActions(activity: mergeActivity, active: true, selectedFalconUsers: participants)
                            deleteFirstActivity.deleteActivity()
                        }
                        self.getSelectedFalconUsers(forActivity: activity) { (participants) in
                            let deleteSecondActivity = ActivityActions(activity: activity, active: true, selectedFalconUsers: participants)
                            deleteSecondActivity.deleteActivity()
                        }
                        
                    // need to delete merge activity
                    } else {
                        self.getSelectedFalconUsers(forActivity: mergeActivity) { (participants) in
                            let deleteActivity = ActivityActions(activity: mergeActivity, active: true, selectedFalconUsers: participants)
                            deleteActivity.deleteActivity()
                        }
                    }
                    
                    self.getSelectedFalconUsers(forActivity: newActivity) { (participants) in
                        let createActivity = ActivityActions(activity: newActivity, active: false, selectedFalconUsers: participants)
                        createActivity.createNewActivity()
                    }
                    
                    self.hideActivityIndicator()
                }
            } else {
                if mergeActivity.schedule != nil {
                    var scheduleList = mergeActivity.schedule!
                    scheduleList.append(activity)
                    mergeActivity.schedule = scheduleList
                } else {
                    let scheduleList = [activity]
                    mergeActivity.schedule = scheduleList
                }
                
                self.showActivityIndicator()
                
                // need to delete current activity
                if active {
                    self.getSelectedFalconUsers(forActivity: activity) { (participants) in
                        let deleteActivity = ActivityActions(activity: activity, active: true, selectedFalconUsers: participants)
                        deleteActivity.deleteActivity()
                    }
                }
                
                self.getSelectedFalconUsers(forActivity: mergeActivity) { (participants) in
                    let createActivity = ActivityActions(activity: mergeActivity, active: false, selectedFalconUsers: participants)
                    createActivity.createNewActivity()
                }
                
                self.hideActivityIndicator()
                
            
            }
            
            if self.conversation == nil {
                self.navigationController?.backToViewController(viewController: ActivityViewController.self)
            } else {
                self.navigationController?.backToViewController(viewController: ChatLogController.self)
            }
        }
    }
}
