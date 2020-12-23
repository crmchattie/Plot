//
//  ActivityDetailPlusButtonExtensions.swift
//  Plot
//
//  Created by Cory McHattie on 4/15/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase

extension RecipeDetailViewController: ActivityDetailCellDelegate {
    func segmentSwitched(segment: Int) {
        self.segment = segment
        self.collectionView.reloadData()
    }
    
    func plusButtonTapped() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if activeList, let object = detailedRecipe {
            var updatedObject = object
            updatedObject.title = updatedObject.title.removeCharacters()
            if !active {
                if listType == "grocery" {
                    self.listDelegate!.updateRecipe(recipe: updatedObject)
                    self.recAddAlert()
                    self.dismiss(animated: true, completion: nil)
                } else {
                    self.listDelegate!.updateList(recipe: updatedObject, workout: nil, event: nil, place: nil, activityType: activityType)
                    self.actAddAlert()
                    self.dismiss(animated: true, completion: nil)
                }
            } else if let activity = self.activity {
                activity.name = updatedObject.title
                activity.activityType = activityType
                activity.recipeID = "\(updatedObject.id)"
                
                let original = Date()
                let rounded = Date(timeIntervalSinceReferenceDate:
                (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                let timezone = TimeZone.current
                let seconds = TimeInterval(timezone.secondsFromGMT(for: Date()))
                startDateTime = rounded.addingTimeInterval(seconds)
                endDateTime = startDateTime!.addingTimeInterval(Double(updatedObject.readyInMinutes ?? 0) * 60)
                
                activity.allDay = false
                activity.startDateTime = NSNumber(value: Int((startDateTime!).timeIntervalSince1970))
                activity.endDateTime = NSNumber(value: Int((endDateTime!).timeIntervalSince1970))
                
                if self.listType == "grocery" {
                    alert.addAction(UIAlertAction(title: "Update Recipe", style: .default, handler: { (_) in
                        
                        self.listDelegate!.updateRecipe(recipe: updatedObject)
                        self.navigationController?.backToViewController(viewController: GrocerylistViewController.self)
                    }))
                }
            
                alert.addAction(UIAlertAction(title: "Create New Activity", style: .default, handler: { (_) in
                    print("User click Approve button")
                    // create new activity
                    self.showActivityIndicator()
                    let createActivity = ActivityActions(activity: activity, active: false, selectedFalconUsers: self.selectedFalconUsers)
                    createActivity.createNewActivity()
                    self.hideActivityIndicator()
                    
                    self.activityCreatedAlert()
                    self.dismiss(animated: true, completion: nil)
                    
                }))
                
                alert.addAction(UIAlertAction(title: "Add to Existing Activity", style: .default, handler: { (_) in
                    
                    // ChooseActivityTableViewController
                    let destination = ChooseActivityTableViewController()
                    let navController = UINavigationController(rootViewController: destination)
                    destination.delegate = self
                    destination.activity = activity
                    destination.activities = self.activities
                    destination.filteredActivities = self.activities
                    self.present(navController, animated: true, completion: nil)
                
                }))
            }
            
        } else if active, !schedule, let activity = activity {
            alert.addAction(UIAlertAction(title: "Update Activity", style: .default, handler: { (_) in
                print("User click Approve button")
                                
                // update activity
                self.showActivityIndicator()
                let createActivity = ActivityActions(activity: activity, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                createActivity.createNewActivity()
                self.hideActivityIndicator()
                
                self.navigationController?.backToViewController(viewController: MasterActivityContainerController.self)
                
            }))
            
            alert.addAction(UIAlertAction(title: "Duplicate Activity", style: .default, handler: { (_) in
                print("User click Approve button")
                // create new activity with updated time
                guard self.currentReachabilityStatus != .notReachable else {
                    basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
                    return
                }
                            
                if let currentUserID = Auth.auth().currentUser?.uid {
                    //duplicate activity
                    let newActivityID = Database.database().reference().child("user-activities").child(currentUserID).childByAutoId().key ?? ""
                    let newActivity = activity.copy() as! Activity
                    newActivity.activityID = newActivityID
                    newActivity.admin = currentUserID
                    newActivity.participantsIDs = nil
                    newActivity.activityPhotos = nil
                    newActivity.activityFiles = nil
                    newActivity.activityOriginalPhotoURL = nil
                    newActivity.activityThumbnailPhotoURL = nil
                    newActivity.conversationID = nil
                    
                    if let scheduleList = newActivity.schedule {
                        for schedule in scheduleList {
                            schedule.participantsIDs = nil
                        }
                    }
                    
                    self.showActivityIndicator()
                    let createActivity = ActivityActions(activity: newActivity, active: false, selectedFalconUsers: [])
                    createActivity.createNewActivity()
                    self.hideActivityIndicator()
                    
                    self.navigationController?.backToViewController(viewController: MasterActivityContainerController.self)
                }
                

            }))
            
            alert.addAction(UIAlertAction(title: "Merge with Activity", style: .default, handler: { (_) in
                print("User click Edit button")
                                    
                // ChooseActivityTableViewController
                let destination = ChooseActivityTableViewController()
                let navController = UINavigationController(rootViewController: destination)
                destination.delegate = self
                destination.activity = activity
                destination.activities = self.activities
                destination.filteredActivities = self.activities
                self.present(navController, animated: true, completion: nil)
            
            }))
            
            alert.addAction(UIAlertAction(title: "Duplicate & Add to Activity", style: .default, handler: { (_) in
                print("User click Edit button")
                
                if let currentUserID = Auth.auth().currentUser?.uid {
                                            
                    //duplicate activity as if it never was deleted aka leave admin and participants intact
                    let newActivityID = Database.database().reference().child("user-activities").child(currentUserID).childByAutoId().key ?? ""
                    let newActivity = activity.copy() as! Activity
                    newActivity.activityID = newActivityID
                    
                    
                    self.showActivityIndicator()
                    let createActivity = ActivityActions(activity: newActivity, active: false, selectedFalconUsers: self.selectedFalconUsers)
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
            
            alert.addAction(UIAlertAction(title: "Add to List", style: .default, handler: { (_) in
                
                // ChooseActivityTableViewController
                let destination = ChooseListTableViewController()
                let navController = UINavigationController(rootViewController: destination)
                destination.lists = self.listList
                destination.filteredLists = self.listList
                destination.recipe = self.detailedRecipe
                destination.activityType = self.activityType
                self.present(navController, animated: true, completion: nil)
                
            }))
            
        } else if active, schedule, let activity = activity {
            
            alert.addAction(UIAlertAction(title: "Update Activity", style: .default, handler: { (_) in
            
                let membersIDs = self.fetchMembersIDs()
                activity.participantsIDs = membersIDs.0
                
                self.delegate?.updateSchedule(schedule: activity)
                if let recipe = self.detailedRecipe {
                    self.delegate?.updateIngredients(recipe: recipe, recipeID: nil)
                    self.navigationController?.backToViewController(viewController: CreateActivityViewController.self)
                    
                }
            }))
            
            alert.addAction(UIAlertAction(title: "Add to List", style: .default, handler: { (_) in
                
                // ChooseActivityTableViewController
                let destination = ChooseListTableViewController()
                let navController = UINavigationController(rootViewController: destination)
                destination.lists = self.listList
                destination.filteredLists = self.listList
                destination.recipe = self.detailedRecipe
                destination.activityType = self.activityType
                self.present(navController, animated: true, completion: nil)
                
            }))
            
        } else if schedule, let _ = umbrellaActivity {
            alert.addAction(UIAlertAction(title: "Add to Schedule", style: .default, handler: { (_) in
                print("User click Approve button")
                if let activity = self.activity {
                    let membersIDs = self.fetchMembersIDs()
                    activity.participantsIDs = membersIDs.0
                    
                    self.delegate?.updateSchedule(schedule: activity)
                    if let recipe = self.detailedRecipe {
                        self.delegate?.updateIngredients(recipe: recipe, recipeID: nil)
                    }
                    self.actAddAlert()
                    self.dismiss(animated: true, completion: nil)
                }
            }))
            
        } else if !schedule {
            alert.addAction(UIAlertAction(title: "Create New Activity", style: .default, handler: { (_) in
                print("User click Approve button")
                // create new activity
                
                if let activity = self.activity {
                    self.showActivityIndicator()
                    let createActivity = ActivityActions(activity: activity, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    createActivity.createNewActivity()
                    self.hideActivityIndicator()
                                        
//                    let nav = self.tabBarController!.viewControllers![1] as! UINavigationController
//                    if nav.topViewController is MasterActivityContainerController {
//                        let homeTab = nav.topViewController as! MasterActivityContainerController
//                        homeTab.customSegmented.setIndex(index: 1)
//                        homeTab.changeToIndex(index: 1)
//                    }
                    self.tabBarController?.selectedIndex = 1
                    if #available(iOS 13.0, *) {
                        self.navigationController?.backToViewController(viewController: DiscoverViewController.self)
                    } else {
                        // Fallback on earlier versions
                    }
                }
                
            }))
            
            alert.addAction(UIAlertAction(title: "Add to Existing Activity", style: .default, handler: { (_) in
                
                if let activity = self.activity {
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
            
            alert.addAction(UIAlertAction(title: "Add to List", style: .default, handler: { (_) in
                
                // ChooseActivityTableViewController
                let destination = ChooseListTableViewController()
                let navController = UINavigationController(rootViewController: destination)
                destination.lists = self.listList
                destination.filteredLists = self.listList
                destination.recipe = self.detailedRecipe
                destination.activityType = self.activityType
                self.present(navController, animated: true, completion: nil)
                
            }))

        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))

        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
    
    func shareButtonTapped() {
        if let recipe = recipe {
            var activityObject: ActivityObject
            if let activityType = activityType, let image = UIImage(named: activityType), let category = recipe.readyInMinutes, let subcategory = recipe.servings {
                print("categoryObject \(category)")
                let data = compressImage(image: image)
                let activity = ["activityType": "recipe",
                            "activityName": "\(recipe.title)",
                            "activityTypeID": "\(recipe.id)",
                            "activityImageURL": activityType,
                            "activityCategory": "Preparation time: \(category) mins",
                            "activitySubcategory": "\(subcategory)",
                            "object": data] as [String: AnyObject]
                activityObject = ActivityObject(dictionary: activity)
            } else if let category = recipe.readyInMinutes, let subcategory = recipe.servings {
                let activity = ["activityType": "recipe",
                            "activityName": "\(recipe.title)",
                            "activityCategory": "Preparation time: \(category) mins",
                            "activitySubcategory": "\(subcategory)",
                            "activityTypeID": "\(recipe.id)"] as [String: AnyObject]
                activityObject = ActivityObject(dictionary: activity)
            } else {
                return
            }
            
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
            

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                print("User click Dismiss button")
            }))

            self.present(alert, animated: true, completion: {
                print("completion block")
            })
            print("shareButtonTapped")
        }
    }
    
    func bookmarkButtonTapped() {
        print("bookmarkButtonTapped")
        if let currentUserID = Auth.auth().currentUser?.uid {
            let databaseReference = Database.database().reference().child("user-fav-activities").child(currentUserID)
            if let recipe = recipe {
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
            
        if !schedule {
            if active, activity.conversationID == nil {
                alert.addAction(UIAlertAction(title: "Connect Activity to a Chat", style: .default, handler: { (_) in
                    print("User click Approve button")
                    self.goToChat()

                }))
            } else if active {
                alert.addAction(UIAlertAction(title: "Go to Chat", style: .default, handler: { (_) in
                    print("User click Approve button")
                    self.goToChat()

                }))
            }
        }
                
        if let localName = activity.locationName, localName != "locationName", let _ = activity.locationAddress {
            alert.addAction(UIAlertAction(title: "Go to Map", style: .default, handler: { (_) in
                print("User click Edit button")
                self.goToMap(activity: self.activity)
            }))
        }
           

       alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
           print("User click Dismiss button")
       }))

       self.present(alert, animated: true, completion: {
           print("completion block")
       })
        print("shareButtonTapped")
        
    }

}

extension RecipeDetailViewController: ChooseActivityDelegate {
    func chosenList(finished: Bool) {
        
    }
    
    func chosenActivity(mergeActivity: Activity) {
        if let activity = activity {
            let dispatchGroup = DispatchGroup()
            if mergeActivity.recipeID != nil || mergeActivity.workoutID != nil || mergeActivity.eventID != nil || mergeActivity.placeID != nil {
                if let currentUserID = Auth.auth().currentUser?.uid {
                    let newActivityID = Database.database().reference().child("user-activities").child(currentUserID).childByAutoId().key ?? ""
                    let newActivity = mergeActivity.copy() as! Activity
                    newActivity.activityID = newActivityID
                    newActivity.recipeID = nil
                    newActivity.workoutID = nil
                    newActivity.eventID = nil
                    newActivity.placeID = nil
                    
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
                    if active && !activeList {
                        dispatchGroup.enter()
                        self.getSelectedFalconUsers(forActivity: mergeActivity) { (participants) in
                            let deleteFirstActivity = ActivityActions(activity: mergeActivity, active: true, selectedFalconUsers: participants)
                            deleteFirstActivity.deleteActivity()
                            dispatchGroup.leave()
                        }
                        dispatchGroup.enter()
                        self.getSelectedFalconUsers(forActivity: activity) { (participants) in
                            let deleteSecondActivity = ActivityActions(activity: activity, active: true, selectedFalconUsers: participants)
                            deleteSecondActivity.deleteActivity()
                            dispatchGroup.leave()
                        }
                        
                    // need to delete merge activity
                    } else {
                        dispatchGroup.enter()
                        self.getSelectedFalconUsers(forActivity: mergeActivity) { (participants) in
                            let deleteActivity = ActivityActions(activity: mergeActivity, active: true, selectedFalconUsers: participants)
                            deleteActivity.deleteActivity()
                            dispatchGroup.leave()
                        }
                    }
                    
                    dispatchGroup.enter()
                    self.getSelectedFalconUsers(forActivity: newActivity) { (participants) in
                        let createActivity = ActivityActions(activity: newActivity, active: false, selectedFalconUsers: participants)
                        createActivity.createNewActivity()
                        dispatchGroup.leave()
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
                
                if let oldParticipantsIDs = activity.participantsIDs {
                    if let newParticipantsIDs = mergeActivity.participantsIDs {
                        for id in oldParticipantsIDs {
                            if !newParticipantsIDs.contains(id) {
                                mergeActivity.participantsIDs!.append(id)
                            }
                        }
                    } else {
                        mergeActivity.participantsIDs = activity.participantsIDs
                    }
                }
                
                self.showActivityIndicator()
                
                // need to delete current activity
                if active && !activeList {
                    dispatchGroup.enter()
                    self.getSelectedFalconUsers(forActivity: activity) { (participants) in
                        let deleteActivity = ActivityActions(activity: activity, active: true, selectedFalconUsers: participants)
                        deleteActivity.deleteActivity()
                        dispatchGroup.leave()
                    }
                }
                
                dispatchGroup.enter()
                self.getSelectedFalconUsers(forActivity: mergeActivity) { (participants) in
                    let createActivity = ActivityActions(activity: mergeActivity, active: true, selectedFalconUsers: participants)
                    createActivity.createNewActivity()
                    dispatchGroup.leave()
                    self.hideActivityIndicator()
                }
            
            }
            
            dispatchGroup.notify(queue: .main) {
               self.actAddAlert()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                    self.removeActAddAlert()
                })
            }
        }
    }
}

extension WorkoutDetailViewController: ActivityDetailCellDelegate {
    func segmentSwitched(segment: Int) {
        self.segment = segment
        self.collectionView.reloadData()
    }
    
    func plusButtonTapped() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if activeList, let object = workout {
            var updatedObject = object
            updatedObject.title = updatedObject.title.removeCharacters()
            if !active {
                self.listDelegate!.updateList(recipe: nil, workout: updatedObject, event: nil, place: nil, activityType: activityType)
                self.actAddAlert()
                self.removeActAddAlert()
            } else if let activity = self.activity {
                activity.name = updatedObject.title
                activity.activityType = activityType
                activity.workoutID = "\(updatedObject.identifier)"
                
                let original = Date()
                let rounded = Date(timeIntervalSinceReferenceDate:
                (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                let timezone = TimeZone.current
                let seconds = TimeInterval(timezone.secondsFromGMT(for: Date()))
                startDateTime = rounded.addingTimeInterval(seconds)
                if let workoutDuration = updatedObject.workoutDuration, let duration = Double(workoutDuration) {
                    endDateTime = startDateTime!.addingTimeInterval(duration * 60)
                } else {
                    endDateTime = startDateTime!
                }
                activity.allDay = false
                activity.startDateTime = NSNumber(value: Int((startDateTime!).timeIntervalSince1970))
                activity.endDateTime = NSNumber(value: Int((endDateTime!).timeIntervalSince1970))
                            
            
                alert.addAction(UIAlertAction(title: "Create New Activity", style: .default, handler: { (_) in
                    print("User click Approve button")
                    // create new activity
                    self.showActivityIndicator()
                    let createActivity = ActivityActions(activity: activity, active: false, selectedFalconUsers: self.selectedFalconUsers)
                    createActivity.createNewActivity()
                    self.hideActivityIndicator()
                    
                    self.activityCreatedAlert()
                    self.dismiss(animated: true, completion: nil)
                    
                }))
                
                alert.addAction(UIAlertAction(title: "Add to Existing Activity", style: .default, handler: { (_) in
                    
                    // ChooseActivityTableViewController
                    let destination = ChooseActivityTableViewController()
                    let navController = UINavigationController(rootViewController: destination)
                    destination.delegate = self
                    destination.activity = activity
                    destination.activities = self.activities
                    destination.filteredActivities = self.activities
                    self.present(navController, animated: true, completion: nil)
                
                }))
            }
            
        } else if active, !schedule, let activity = activity {
            alert.addAction(UIAlertAction(title: "Update Activity", style: .default, handler: { (_) in
                print("User click Approve button")
                                
                // update activity
                self.showActivityIndicator()
                let createActivity = ActivityActions(activity: activity, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                createActivity.createNewActivity()
                self.hideActivityIndicator()
                
                self.navigationController?.backToViewController(viewController: MasterActivityContainerController.self)
                
            }))
            
            alert.addAction(UIAlertAction(title: "Duplicate Activity", style: .default, handler: { (_) in
                print("User click Approve button")
                // create new activity with updated time
                guard self.currentReachabilityStatus != .notReachable else {
                    basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
                    return
                }
                            
                if let currentUserID = Auth.auth().currentUser?.uid {
                    //duplicate activity
                    let newActivityID = Database.database().reference().child("user-activities").child(currentUserID).childByAutoId().key ?? ""
                    let newActivity = activity.copy() as! Activity
                    newActivity.activityID = newActivityID
                    newActivity.admin = currentUserID
                    newActivity.participantsIDs = nil
                    newActivity.activityPhotos = nil
                    newActivity.activityFiles = nil
                    newActivity.activityOriginalPhotoURL = nil
                    newActivity.activityThumbnailPhotoURL = nil
                    newActivity.conversationID = nil
                    
                    if let scheduleList = newActivity.schedule {
                        for schedule in scheduleList {
                            schedule.participantsIDs = nil
                        }
                    }
                    
                    self.showActivityIndicator()
                    let createActivity = ActivityActions(activity: newActivity, active: false, selectedFalconUsers: [])
                    createActivity.createNewActivity()
                    self.hideActivityIndicator()
                    
                    self.navigationController?.backToViewController(viewController: MasterActivityContainerController.self)
                    
                }
                

            }))
            
            alert.addAction(UIAlertAction(title: "Merge with Activity", style: .default, handler: { (_) in
                print("User click Edit button")
                                    
                // ChooseActivityTableViewController
                let destination = ChooseActivityTableViewController()
                let navController = UINavigationController(rootViewController: destination)
                destination.delegate = self
                destination.activity = activity
                destination.activities = self.activities
                destination.filteredActivities = self.activities
                self.present(navController, animated: true, completion: nil)
            
            }))
            
            alert.addAction(UIAlertAction(title: "Duplicate & Add to Activity", style: .default, handler: { (_) in
                print("User click Edit button")
                
                if let currentUserID = Auth.auth().currentUser?.uid {
                                            
                    //duplicate activity as if it never was deleted aka leave admin and participants intact
                    let newActivityID = Database.database().reference().child("user-activities").child(currentUserID).childByAutoId().key ?? ""
                    let newActivity = activity.copy() as! Activity
                    newActivity.activityID = newActivityID
                    
                    
                    self.showActivityIndicator()
                    let createActivity = ActivityActions(activity: newActivity, active: false, selectedFalconUsers: self.selectedFalconUsers)
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
            
            alert.addAction(UIAlertAction(title: "Add to List", style: .default, handler: { (_) in
                
                // ChooseActivityTableViewController
                let destination = ChooseListTableViewController()
                let navController = UINavigationController(rootViewController: destination)
                destination.lists = self.listList
                destination.filteredLists = self.listList
                destination.workout = self.workout
                destination.activityType = self.activityType
                self.present(navController, animated: true, completion: nil)
                
            }))
            
        } else if active, schedule, let activity = activity {
            
            alert.addAction(UIAlertAction(title: "Update Activity", style: .default, handler: { (_) in
            
                let membersIDs = self.fetchMembersIDs()
                activity.participantsIDs = membersIDs.0
                
                self.delegate?.updateSchedule(schedule: activity)
                self.navigationController?.backToViewController(viewController: CreateActivityViewController.self)
                
            }))
            
            alert.addAction(UIAlertAction(title: "Add to List", style: .default, handler: { (_) in
                
                // ChooseActivityTableViewController
                let destination = ChooseListTableViewController()
                let navController = UINavigationController(rootViewController: destination)
                destination.lists = self.listList
                destination.filteredLists = self.listList
                destination.workout = self.workout
                destination.activityType = self.activityType
                self.present(navController, animated: true, completion: nil)
                
            }))
                        
        } else if schedule, let _ = umbrellaActivity {
            alert.addAction(UIAlertAction(title: "Add to Schedule", style: .default, handler: { (_) in
                print("User click Approve button")
                if let activity = self.activity {
                    let membersIDs = self.fetchMembersIDs()
                    activity.participantsIDs = membersIDs.0
                    
                    self.delegate?.updateSchedule(schedule: activity)
                    self.actAddAlert()
                    self.dismiss(animated: true, completion: nil)
                    
                }
            }))
            
        } else if !schedule {
            alert.addAction(UIAlertAction(title: "Create New Activity", style: .default, handler: { (_) in
                print("User click Approve button")
                // create new activity
                
                if let activity = self.activity {
                    self.showActivityIndicator()
                    let createActivity = ActivityActions(activity: activity, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    createActivity.createNewActivity()
                    self.hideActivityIndicator()
                    
//                    let nav = self.tabBarController!.viewControllers![1] as! UINavigationController
//                    if nav.topViewController is MasterActivityContainerController {
//                        let homeTab = nav.topViewController as! MasterActivityContainerController
//                        homeTab.customSegmented.setIndex(index: 1)
//                        homeTab.changeToIndex(index: 1)
//                    }
                    self.tabBarController?.selectedIndex = 1
                    if #available(iOS 13.0, *) {
                        self.navigationController?.backToViewController(viewController: DiscoverViewController.self)
                    } else {
                        // Fallback on earlier versions
                    }
                }
                
            }))
            
            alert.addAction(UIAlertAction(title: "Add to Existing Activity", style: .default, handler: { (_) in
                
                if let activity = self.activity {
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
            
            alert.addAction(UIAlertAction(title: "Add to List", style: .default, handler: { (_) in
                
                // ChooseActivityTableViewController
                let destination = ChooseListTableViewController()
                let navController = UINavigationController(rootViewController: destination)
                destination.lists = self.listList
                destination.filteredLists = self.listList
                destination.workout = self.workout
                destination.activityType = self.activityType
                self.present(navController, animated: true, completion: nil)
                
            }))

        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))

        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
    
    func shareButtonTapped() {
        if let workout = workout {
            var activityObject: ActivityObject
            if let activityType = activityType, let image = UIImage(named: activityType), let category = workout.tagsStr, let subcategory = workout.exercises?.count {
                print("categoryObject \(category)")
                let data = compressImage(image: image)
                let activity = ["activityType": "workout",
                            "activityName": "\(workout.title)",
                            "activityTypeID": "\(workout.identifier)",
                            "activityImageURL": activityType,
                            "activityCategory": "\(category)",
                            "activitySubcategory": "Number of exercises: \(subcategory)",
                            "object": data] as [String: AnyObject]
                activityObject = ActivityObject(dictionary: activity)
            } else if let category = workout.tagsStr, let subcategory = workout.exercises?.count {
                let activity = ["activityType": "workout",
                            "activityName": "\(workout.title)",
                            "activityCategory": "\(category)",
                            "activitySubcategory": "Number of exercises: \(subcategory)",
                            "activityTypeID": "\(workout.identifier)"] as [String: AnyObject]
                activityObject = ActivityObject(dictionary: activity)
            } else {
                return
            }
            
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
            

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                print("User click Dismiss button")
            }))

            self.present(alert, animated: true, completion: {
                print("completion block")
            })
            print("shareButtonTapped")
        }
    }
    
    func bookmarkButtonTapped() {
        print("bookmarkButtonTapped")
        if let currentUserID = Auth.auth().currentUser?.uid {
            let databaseReference = Database.database().reference().child("user-fav-activities").child(currentUserID)
            if let workout = workout {
                print(workout.title)
                databaseReference.child("workouts").observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists() {
                        var value = snapshot.value as! [String]
                        if value.contains("\(workout.identifier)") {
                            if let index = value.firstIndex(of: "\(workout.identifier)") {
                                value.remove(at: index)
                            }
                            databaseReference.updateChildValues(["workouts": value as NSArray])
                        } else {
                            value.append("\(workout.identifier)")
                            databaseReference.updateChildValues(["workouts": value as NSArray])
                        }
                        self.favAct["workouts"] = value
                    } else {
                        self.favAct["workouts"] = ["\(workout.identifier)"]
                        databaseReference.updateChildValues(["workouts": ["\(workout.identifier)"]])
                    }
                })
            }
        }
        
    }
    
    func dotsButtonTapped() {
    
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if !schedule {
            if active, activity.conversationID == nil {
                alert.addAction(UIAlertAction(title: "Connect Activity to a Chat", style: .default, handler: { (_) in
                    print("User click Approve button")
                    self.goToChat()

                }))
            } else if active {
                alert.addAction(UIAlertAction(title: "Go to Chat", style: .default, handler: { (_) in
                    print("User click Approve button")
                    self.goToChat()

                }))
            }
        }
            
        if let localName = activity.locationName, localName != "locationName", let _ = activity.locationAddress {
            alert.addAction(UIAlertAction(title: "Go to Map", style: .default, handler: { (_) in
                print("User click Edit button")
                self.goToMap(activity: self.activity)
            }))
        }
           

       alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
           print("User click Dismiss button")
       }))

       self.present(alert, animated: true, completion: {
           print("completion block")
       })
        print("shareButtonTapped")
        
    }

}

extension WorkoutDetailViewController: ChooseActivityDelegate {
    func chosenList(finished: Bool) {
        
    }
    
    func chosenActivity(mergeActivity: Activity) {
        if let activity = activity {
            let dispatchGroup = DispatchGroup()
            if mergeActivity.recipeID != nil || mergeActivity.workoutID != nil || mergeActivity.eventID != nil || mergeActivity.placeID != nil {
                if let currentUserID = Auth.auth().currentUser?.uid {
                    
                    let newActivityID = Database.database().reference().child("user-activities").child(currentUserID).childByAutoId().key ?? ""
                    let newActivity = mergeActivity.copy() as! Activity
                    newActivity.activityID = newActivityID
                    newActivity.recipeID = nil
                    newActivity.workoutID = nil
                    newActivity.eventID = nil
                    newActivity.placeID = nil
                    
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
                    if active && !activeList {
                        dispatchGroup.enter()
                        self.getSelectedFalconUsers(forActivity: mergeActivity) { (participants) in
                            let deleteFirstActivity = ActivityActions(activity: mergeActivity, active: true, selectedFalconUsers: participants)
                            deleteFirstActivity.deleteActivity()
                            dispatchGroup.leave()
                        }
                        dispatchGroup.enter()
                        self.getSelectedFalconUsers(forActivity: activity) { (participants) in
                            let deleteSecondActivity = ActivityActions(activity: activity, active: true, selectedFalconUsers: participants)
                            deleteSecondActivity.deleteActivity()
                            dispatchGroup.leave()
                        }
                        
                    // need to delete merge activity
                    } else {
                        dispatchGroup.enter()
                        self.getSelectedFalconUsers(forActivity: mergeActivity) { (participants) in
                            let deleteActivity = ActivityActions(activity: mergeActivity, active: true, selectedFalconUsers: participants)
                            deleteActivity.deleteActivity()
                            dispatchGroup.leave()
                        }
                    }
                    
                    dispatchGroup.enter()
                    self.getSelectedFalconUsers(forActivity: newActivity) { (participants) in
                        let createActivity = ActivityActions(activity: newActivity, active: false, selectedFalconUsers: participants)
                        createActivity.createNewActivity()
                        dispatchGroup.leave()
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
                
                if let oldParticipantsIDs = activity.participantsIDs {
                    if let newParticipantsIDs = mergeActivity.participantsIDs {
                        for id in oldParticipantsIDs {
                            if !newParticipantsIDs.contains(id) {
                                mergeActivity.participantsIDs!.append(id)
                            }
                        }
                    } else {
                        mergeActivity.participantsIDs = activity.participantsIDs
                    }
                }
                
                self.showActivityIndicator()
                
                // need to delete current activity
                if active && !activeList {
                    dispatchGroup.enter()
                    self.getSelectedFalconUsers(forActivity: activity) { (participants) in
                        let deleteActivity = ActivityActions(activity: activity, active: true, selectedFalconUsers: participants)
                        deleteActivity.deleteActivity()
                        dispatchGroup.leave()
                    }
                }
                
                dispatchGroup.enter()
                self.getSelectedFalconUsers(forActivity: mergeActivity) { (participants) in
                    let createActivity = ActivityActions(activity: mergeActivity, active: true, selectedFalconUsers: participants)
                    createActivity.createNewActivity()
                    dispatchGroup.leave()
                    self.hideActivityIndicator()
                }
            
            }
            
            dispatchGroup.notify(queue: .main) {
               self.actAddAlert()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                    self.removeActAddAlert()
                })
            }
        }
    }
}

extension EventDetailViewController: ActivityDetailCellDelegate {
    func segmentSwitched(segment: Int) {
        self.segment = segment
        self.collectionView.reloadData()
    }
    func plusButtonTapped() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if activeList, let object = event {
            var updatedObject = object
            updatedObject.name = updatedObject.name.removeCharacters()
            if !active {
                self.listDelegate!.updateList(recipe: nil, workout: nil, event: updatedObject, place: nil, activityType: activityType)
                self.actAddAlert()
                self.removeActAddAlert()
            } else if let activity = self.activity {
                activity.name = updatedObject.name
                activity.activityType = activityType
                activity.eventID = "\(updatedObject.id)"
                
                if let startDate = updatedObject.dates?.start?.dateTime, let date = startDate.toDate() {
                    startDateTime = date
                    endDateTime = date
                } else {
                    let original = Date()
                    let rounded = Date(timeIntervalSinceReferenceDate:
                    (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    let timezone = TimeZone.current
                    let seconds = TimeInterval(timezone.secondsFromGMT(for: Date()))
                    startDateTime = rounded.addingTimeInterval(seconds)
                    endDateTime = startDateTime
                }
                activity.allDay = false
                activity.startDateTime = NSNumber(value: Int((startDateTime!).timeIntervalSince1970))
                activity.endDateTime = NSNumber(value: Int((endDateTime!).timeIntervalSince1970))

                if locationName == "Location", let locationName = updatedObject.embedded?.venues?[0].address?.line1, let latitude = updatedObject.embedded?.venues?[0].location?.latitude, let longitude = updatedObject.embedded?.venues?[0].location?.longitude {
                    let newLocationName = locationName.removeCharacters()
                    activity.locationName = newLocationName
                    activity.locationAddress = [newLocationName: [Double(latitude)!, Double(longitude)!]]
                }
            
                alert.addAction(UIAlertAction(title: "Create New Activity", style: .default, handler: { (_) in
                    print("User click Approve button")
                    // create new activity
                    self.showActivityIndicator()
                    let createActivity = ActivityActions(activity: activity, active: false, selectedFalconUsers: self.selectedFalconUsers)
                    createActivity.createNewActivity()
                    self.hideActivityIndicator()
                    
                    self.activityCreatedAlert()
                    self.dismiss(animated: true, completion: nil)
                    
                }))
                
                alert.addAction(UIAlertAction(title: "Add to Existing Activity", style: .default, handler: { (_) in
                    
                    // ChooseActivityTableViewController
                    let destination = ChooseActivityTableViewController()
                    let navController = UINavigationController(rootViewController: destination)
                    destination.delegate = self
                    destination.activity = activity
                    destination.activities = self.activities
                    destination.filteredActivities = self.activities
                    self.present(navController, animated: true, completion: nil)
                
                }))
            }
            
        } else if active, !schedule, let activity = activity {
            alert.addAction(UIAlertAction(title: "Update Activity", style: .default, handler: { (_) in
                print("User click Approve button")
                                
                // update activity
                self.showActivityIndicator()
                let createActivity = ActivityActions(activity: activity, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                createActivity.createNewActivity()
                self.hideActivityIndicator()
                
                self.navigationController?.backToViewController(viewController: MasterActivityContainerController.self)
                
            }))
            
            alert.addAction(UIAlertAction(title: "Duplicate Activity", style: .default, handler: { (_) in
                print("User click Approve button")
                // create new activity with updated time
                guard self.currentReachabilityStatus != .notReachable else {
                    basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
                    return
                }
                            
                if let currentUserID = Auth.auth().currentUser?.uid {
                    //duplicate activity
                    let newActivityID = Database.database().reference().child("user-activities").child(currentUserID).childByAutoId().key ?? ""
                    let newActivity = activity.copy() as! Activity
                    newActivity.activityID = newActivityID
                    newActivity.admin = currentUserID
                    newActivity.participantsIDs = nil
                    newActivity.activityPhotos = nil
                    newActivity.activityFiles = nil
                    newActivity.activityOriginalPhotoURL = nil
                    newActivity.activityThumbnailPhotoURL = nil
                    newActivity.conversationID = nil
                    
                    if let scheduleList = newActivity.schedule {
                        for schedule in scheduleList {
                            schedule.participantsIDs = nil
                        }
                    }
                    
                    self.showActivityIndicator()
                    let createActivity = ActivityActions(activity: newActivity, active: false, selectedFalconUsers: [])
                    createActivity.createNewActivity()
                    self.hideActivityIndicator()
                    
                    self.navigationController?.backToViewController(viewController: MasterActivityContainerController.self)

                }
                

            }))
            
            alert.addAction(UIAlertAction(title: "Merge with Activity", style: .default, handler: { (_) in
                print("User click Edit button")
                                    
                // ChooseActivityTableViewController
                let destination = ChooseActivityTableViewController()
                let navController = UINavigationController(rootViewController: destination)
                destination.delegate = self
                destination.activity = activity
                destination.activities = self.activities
                destination.filteredActivities = self.activities
                self.present(navController, animated: true, completion: nil)
            
            }))
            
            alert.addAction(UIAlertAction(title: "Duplicate & Add to Activity", style: .default, handler: { (_) in
                print("User click Edit button")
                
                if let currentUserID = Auth.auth().currentUser?.uid {
                                            
                    //duplicate activity as if it never was deleted aka leave admin and participants intact
                    let newActivityID = Database.database().reference().child("user-activities").child(currentUserID).childByAutoId().key ?? ""
                    let newActivity = activity.copy() as! Activity
                    newActivity.activityID = newActivityID
                    
                    
                    self.showActivityIndicator()
                    let createActivity = ActivityActions(activity: newActivity, active: false, selectedFalconUsers: self.selectedFalconUsers)
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
            
            alert.addAction(UIAlertAction(title: "Add to List", style: .default, handler: { (_) in
                
                // ChooseActivityTableViewController
                let destination = ChooseListTableViewController()
                let navController = UINavigationController(rootViewController: destination)
                destination.lists = self.listList
                destination.filteredLists = self.listList
                destination.event = self.event
                destination.activityType = self.activityType
                self.present(navController, animated: true, completion: nil)
                
            }))
            
        } else if active, schedule, let activity = activity {
            
            alert.addAction(UIAlertAction(title: "Update Activity", style: .default, handler: { (_) in
            
                let membersIDs = self.fetchMembersIDs()
                activity.participantsIDs = membersIDs.0
                
                self.delegate?.updateSchedule(schedule: activity)
                self.navigationController?.backToViewController(viewController: CreateActivityViewController.self)
                
            }))
            
            alert.addAction(UIAlertAction(title: "Add to List", style: .default, handler: { (_) in
                
                // ChooseActivityTableViewController
                let destination = ChooseListTableViewController()
                let navController = UINavigationController(rootViewController: destination)
                destination.lists = self.listList
                destination.filteredLists = self.listList
                destination.event = self.event
                destination.activityType = self.activityType
                self.present(navController, animated: true, completion: nil)
                
            }))
                        
        } else if schedule, let _ = umbrellaActivity {
            alert.addAction(UIAlertAction(title: "Add to Schedule", style: .default, handler: { (_) in
                print("User click Approve button")
                if let activity = self.activity {
                    let membersIDs = self.fetchMembersIDs()
                    activity.participantsIDs = membersIDs.0
                    
                    self.delegate?.updateSchedule(schedule: activity)
                    self.actAddAlert()
                    self.dismiss(animated: true, completion: nil)
                    
                }
            }))
            
        } else if !schedule {
            alert.addAction(UIAlertAction(title: "Create New Activity", style: .default, handler: { (_) in
                print("User click Approve button")
                // create new activity
                
                if let activity = self.activity {
                    self.showActivityIndicator()
                    let createActivity = ActivityActions(activity: activity, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    createActivity.createNewActivity()
                    self.hideActivityIndicator()
                                        
//                    let nav = self.tabBarController!.viewControllers![1] as! UINavigationController
//                    if nav.topViewController is MasterActivityContainerController {
//                        let homeTab = nav.topViewController as! MasterActivityContainerController
//                        homeTab.customSegmented.setIndex(index: 1)
//                        homeTab.changeToIndex(index: 1)
//                    }
                    self.tabBarController?.selectedIndex = 1
                    if #available(iOS 13.0, *) {
                        self.navigationController?.backToViewController(viewController: DiscoverViewController.self)
                    } else {
                        // Fallback on earlier versions
                    }
                }
                
            }))
            
            alert.addAction(UIAlertAction(title: "Add to Existing Activity", style: .default, handler: { (_) in
                
                if let activity = self.activity {
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
            
            alert.addAction(UIAlertAction(title: "Add to List", style: .default, handler: { (_) in
                
                // ChooseActivityTableViewController
                let destination = ChooseListTableViewController()
                let navController = UINavigationController(rootViewController: destination)
                destination.lists = self.listList
                destination.filteredLists = self.listList
                destination.event = self.event
                destination.activityType = self.activityType
                self.present(navController, animated: true, completion: nil)
                
            }))

        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))

        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
    
    func shareButtonTapped() {
        if let event = event {
            var subcategory = ""
            if let minPrice = event.priceRanges?[0].min, let maxPrice = event.priceRanges?[0].max {
                let formatter = CurrencyFormatter()
                formatter.locale = .current
                formatter.numberStyle = .currency
                let minPriceString = formatter.string(for: minPrice)!
                let maxPriceString = formatter.string(for: maxPrice)!
                subcategory = "Price range: \(minPriceString) to \(maxPriceString)"
            } else {
                subcategory = ""
            }
            var activityObject: ActivityObject
            if let activityType = activityType, let image = UIImage(named: activityType) {
                let data = compressImage(image: image)
                let activity = ["activityType": "event",
                            "activityName": "\(event.name)",
                            "activityTypeID": "\(event.id)",
                            "activityImageURL": activityType,
                            "activityCategory": "\(event.embedded?.venues?[0].name?.capitalized ?? "")",
                            "activitySubcategory": "Number of exercises: \(subcategory)",
                            "object": data] as [String: AnyObject]
                activityObject = ActivityObject(dictionary: activity)
            } else {
                let activity = ["activityType": "event",
                            "activityName": "\(event.name)",
                            "activityCategory": "\(event.embedded?.venues?[0].name?.capitalized ?? "")",
                            "activitySubcategory": "Number of exercises: \(subcategory)",
                            "activityTypeID": "\(event.id)"] as [String: AnyObject]
                activityObject = ActivityObject(dictionary: activity)
            }
            
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
            

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                print("User click Dismiss button")
            }))

            self.present(alert, animated: true, completion: {
                print("completion block")
            })
            print("shareButtonTapped")
        }
    }
    
    func bookmarkButtonTapped() {
        print("bookmarkButtonTapped")
        if let currentUserID = Auth.auth().currentUser?.uid {
            let databaseReference = Database.database().reference().child("user-fav-activities").child(currentUserID)
            if let event = event {
                print(event.name)
                databaseReference.child("events").observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists() {
                        var value = snapshot.value as! [String]
                        if value.contains("\(event.id)") {
                            if let index = value.firstIndex(of: "\(event.id)") {
                                value.remove(at: index)
                            }
                            databaseReference.updateChildValues(["events": value as NSArray])
                        } else {
                            value.append("\(event.id)")
                            databaseReference.updateChildValues(["events": value as NSArray])
                        }
                        self.favAct["events"] = value
                    } else {
                        self.favAct["events"] = ["\(event.id)"]
                        databaseReference.updateChildValues(["events": ["\(event.id)"]])
                    }
                })
            }
        }
        
    }
    
    func dotsButtonTapped() {
    
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if !schedule {
            if active, activity.conversationID == nil {
                alert.addAction(UIAlertAction(title: "Connect Activity to a Chat", style: .default, handler: { (_) in
                    print("User click Approve button")
                    self.goToChat()

                }))
            } else if active {
                alert.addAction(UIAlertAction(title: "Go to Chat", style: .default, handler: { (_) in
                    print("User click Approve button")
                    self.goToChat()

                }))
            }
        }
            
        if let localName = activity.locationName, localName != "locationName", let _ = activity.locationAddress {
            alert.addAction(UIAlertAction(title: "Go to Map", style: .default, handler: { (_) in
                print("User click Edit button")
                self.goToMap(activity: self.activity)
            }))
        }
           

       alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
           print("User click Dismiss button")
       }))

       self.present(alert, animated: true, completion: {
           print("completion block")
       })
        print("shareButtonTapped")
        
    }

}

extension EventDetailViewController: ChooseActivityDelegate {
    func chosenList(finished: Bool) {
        
    }
    
    func chosenActivity(mergeActivity: Activity) {
        if let activity = activity {
            let dispatchGroup = DispatchGroup()
            if mergeActivity.recipeID != nil || mergeActivity.workoutID != nil || mergeActivity.eventID != nil || mergeActivity.placeID != nil {
                if let currentUserID = Auth.auth().currentUser?.uid {
                    let newActivityID = Database.database().reference().child("user-activities").child(currentUserID).childByAutoId().key ?? ""
                    let newActivity = mergeActivity.copy() as! Activity
                    newActivity.activityID = newActivityID
                    newActivity.recipeID = nil
                    newActivity.workoutID = nil
                    newActivity.eventID = nil
                    newActivity.placeID = nil
                    
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
                    if active && !activeList {
                        dispatchGroup.enter()
                        self.getSelectedFalconUsers(forActivity: mergeActivity) { (participants) in
                            let deleteFirstActivity = ActivityActions(activity: mergeActivity, active: true, selectedFalconUsers: participants)
                            deleteFirstActivity.deleteActivity()
                            dispatchGroup.leave()
                        }
                        dispatchGroup.enter()
                        self.getSelectedFalconUsers(forActivity: activity) { (participants) in
                            let deleteSecondActivity = ActivityActions(activity: activity, active: true, selectedFalconUsers: participants)
                            deleteSecondActivity.deleteActivity()
                            dispatchGroup.leave()
                        }
                        
                    // need to delete merge activity
                    } else {
                        dispatchGroup.enter()
                        self.getSelectedFalconUsers(forActivity: mergeActivity) { (participants) in
                            let deleteActivity = ActivityActions(activity: mergeActivity, active: true, selectedFalconUsers: participants)
                            deleteActivity.deleteActivity()
                            dispatchGroup.leave()
                        }
                    }
                    
                    dispatchGroup.enter()
                    self.getSelectedFalconUsers(forActivity: newActivity) { (participants) in
                        let createActivity = ActivityActions(activity: newActivity, active: false, selectedFalconUsers: participants)
                        createActivity.createNewActivity()
                        dispatchGroup.leave()
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
                
                if let oldParticipantsIDs = activity.participantsIDs {
                    if let newParticipantsIDs = mergeActivity.participantsIDs {
                        for id in oldParticipantsIDs {
                            if !newParticipantsIDs.contains(id) {
                                mergeActivity.participantsIDs!.append(id)
                            }
                        }
                    } else {
                        mergeActivity.participantsIDs = activity.participantsIDs
                    }
                }
                
                self.showActivityIndicator()
                
                // need to delete current activity
                if active && !activeList {
                    dispatchGroup.enter()
                    self.getSelectedFalconUsers(forActivity: activity) { (participants) in
                        let deleteActivity = ActivityActions(activity: activity, active: true, selectedFalconUsers: participants)
                        deleteActivity.deleteActivity()
                        dispatchGroup.leave()
                    }
                }
                
                dispatchGroup.enter()
                self.getSelectedFalconUsers(forActivity: mergeActivity) { (participants) in
                    let createActivity = ActivityActions(activity: mergeActivity, active: true, selectedFalconUsers: participants)
                    createActivity.createNewActivity()
                    dispatchGroup.leave()
                    self.hideActivityIndicator()
                }
            
            }
            
            dispatchGroup.notify(queue: .main) {
               self.actAddAlert()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                    self.removeActAddAlert()
                })
            }
        }
    }
}

extension PlaceDetailViewController: ActivityDetailCellDelegate {
    func segmentSwitched(segment: Int) {
        self.segment = segment
        self.collectionView.reloadData()
    }
    
    func plusButtonTapped() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if activeList, let object = place {
            var updatedObject = object
            updatedObject.name = updatedObject.name.removeCharacters()
            if !active {
                self.listDelegate!.updateList(recipe: nil, workout: nil, event: nil, place: updatedObject, activityType: activityType)
                self.actAddAlert()
                self.removeActAddAlert()
            } else if let activity = self.activity {
                activity.name = updatedObject.name
                activity.activityType = activityType
                activity.placeID = "\(updatedObject.id)"
                
                let original = Date()
                let rounded = Date(timeIntervalSinceReferenceDate:
                    (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                let timezone = TimeZone.current
                let seconds = TimeInterval(timezone.secondsFromGMT(for: Date()))
                startDateTime = rounded.addingTimeInterval(seconds)
                endDateTime = rounded.addingTimeInterval(seconds)
                activity.allDay = false
                activity.startDateTime = NSNumber(value: Int((startDateTime!).timeIntervalSince1970))
                activity.endDateTime = NSNumber(value: Int((endDateTime!).timeIntervalSince1970))
                
                if let location = updatedObject.location, let locationName = location.formattedAddress?[0], let latitude = location.lat, let longitude = location.lng {
                    let newLocationName = locationName.removeCharacters()
                    activity.locationName = newLocationName
                    activity.locationAddress = [newLocationName: [latitude, longitude]]
                }
            
                alert.addAction(UIAlertAction(title: "Create New Activity", style: .default, handler: { (_) in
                    print("User click Approve button")
                    // create new activity
                    self.showActivityIndicator()
                    let createActivity = ActivityActions(activity: activity, active: false, selectedFalconUsers: self.selectedFalconUsers)
                    createActivity.createNewActivity()
                    self.hideActivityIndicator()
                    
                    self.activityCreatedAlert()
                    self.dismiss(animated: true, completion: nil)
                    
                }))
                
                alert.addAction(UIAlertAction(title: "Add to Existing Activity", style: .default, handler: { (_) in
                    
                    // ChooseActivityTableViewController
                    let destination = ChooseActivityTableViewController()
                    let navController = UINavigationController(rootViewController: destination)
                    destination.delegate = self
                    destination.activity = activity
                    destination.activities = self.activities
                    destination.filteredActivities = self.activities
                    self.present(navController, animated: true, completion: nil)
                
                }))
            }
            
        } else if active, !schedule, let activity = activity {
            alert.addAction(UIAlertAction(title: "Update Activity", style: .default, handler: { (_) in
                print("User click Approve button")
                                
                // update activity
                self.showActivityIndicator()
                let createActivity = ActivityActions(activity: activity, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                createActivity.createNewActivity()
                self.hideActivityIndicator()
                
                self.navigationController?.backToViewController(viewController: MasterActivityContainerController.self)
                
            }))
            
            alert.addAction(UIAlertAction(title: "Duplicate Activity", style: .default, handler: { (_) in
                print("User click Approve button")
                // create new activity with updated time
                guard self.currentReachabilityStatus != .notReachable else {
                    basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
                    return
                }
                            
                if let currentUserID = Auth.auth().currentUser?.uid {
                    //duplicate activity
                    let newActivityID = Database.database().reference().child("user-activities").child(currentUserID).childByAutoId().key ?? ""
                    let newActivity = activity.copy() as! Activity
                    newActivity.activityID = newActivityID
                    newActivity.admin = currentUserID
                    newActivity.participantsIDs = nil
                    newActivity.activityPhotos = nil
                    newActivity.activityFiles = nil
                    newActivity.activityOriginalPhotoURL = nil
                    newActivity.activityThumbnailPhotoURL = nil
                    newActivity.conversationID = nil
                    
                    if let scheduleList = newActivity.schedule {
                        for schedule in scheduleList {
                            schedule.participantsIDs = nil
                        }
                    }
                    
                    self.showActivityIndicator()
                    let createActivity = ActivityActions(activity: newActivity, active: false, selectedFalconUsers: [])
                    createActivity.createNewActivity()
                    self.hideActivityIndicator()
                    
                    self.navigationController?.backToViewController(viewController: MasterActivityContainerController.self)
                    
                }
                

            }))
            
            alert.addAction(UIAlertAction(title: "Merge with Activity", style: .default, handler: { (_) in
                print("User click Edit button")
                                    
                // ChooseActivityTableViewController
                let destination = ChooseActivityTableViewController()
                let navController = UINavigationController(rootViewController: destination)
                destination.delegate = self
                destination.activity = activity
                destination.activities = self.activities
                destination.filteredActivities = self.activities
                self.present(navController, animated: true, completion: nil)
            
            }))
            
            alert.addAction(UIAlertAction(title: "Duplicate & Add to Activity", style: .default, handler: { (_) in
                print("User click Edit button")
                
                if let currentUserID = Auth.auth().currentUser?.uid {
                                            
                    //duplicate activity as if it never was deleted aka leave admin and participants intact
                    let newActivityID = Database.database().reference().child("user-activities").child(currentUserID).childByAutoId().key ?? ""
                    let newActivity = activity.copy() as! Activity
                    newActivity.activityID = newActivityID
                    
                    
                    self.showActivityIndicator()
                    let createActivity = ActivityActions(activity: newActivity, active: false, selectedFalconUsers: self.selectedFalconUsers)
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
            
            alert.addAction(UIAlertAction(title: "Add to List", style: .default, handler: { (_) in
                
                // ChooseActivityTableViewController
                let destination = ChooseListTableViewController()
                let navController = UINavigationController(rootViewController: destination)
                destination.lists = self.listList
                destination.filteredLists = self.listList
                destination.activityType = self.activityType
                self.present(navController, animated: true, completion: nil)
                
            }))
            
        } else if active, schedule, let activity = activity {
            
            alert.addAction(UIAlertAction(title: "Update Activity", style: .default, handler: { (_) in
            
                let membersIDs = self.fetchMembersIDs()
                activity.participantsIDs = membersIDs.0
                
                self.delegate?.updateSchedule(schedule: activity)
                self.navigationController?.backToViewController(viewController: CreateActivityViewController.self)
                
            }))
            
            alert.addAction(UIAlertAction(title: "Add to List", style: .default, handler: { (_) in
                
                // ChooseActivityTableViewController
                let destination = ChooseListTableViewController()
                let navController = UINavigationController(rootViewController: destination)
                destination.lists = self.listList
                destination.filteredLists = self.listList
                destination.fsVenue = self.place
                destination.activityType = self.activityType
                self.present(navController, animated: true, completion: nil)
                
            }))
                        
        } else if schedule, let _ = umbrellaActivity {
            alert.addAction(UIAlertAction(title: "Add to Schedule", style: .default, handler: { (_) in
                print("User click Approve button")
                if let activity = self.activity {
                    let membersIDs = self.fetchMembersIDs()
                    activity.participantsIDs = membersIDs.0
                    
                    self.delegate?.updateSchedule(schedule: activity)
                    self.actAddAlert()
                    self.dismiss(animated: true, completion: nil)
                    
                }
            }))
            
        } else if !schedule {
            alert.addAction(UIAlertAction(title: "Create New Activity", style: .default, handler: { (_) in
                print("User click Approve button")
                // create new activity
                
                if let activity = self.activity {
                    self.showActivityIndicator()
                    let createActivity = ActivityActions(activity: activity, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    createActivity.createNewActivity()
                    self.hideActivityIndicator()
                    
//                    let nav = self.tabBarController!.viewControllers![1] as! UINavigationController
//                    if nav.topViewController is MasterActivityContainerController {
//                        let homeTab = nav.topViewController as! MasterActivityContainerController
//                        homeTab.customSegmented.setIndex(index: 1)
//                        homeTab.changeToIndex(index: 1)
//                    }
                    self.tabBarController?.selectedIndex = 1
                    if #available(iOS 13.0, *) {
                        self.navigationController?.backToViewController(viewController: DiscoverViewController.self)
                    } else {
                        // Fallback on earlier versions
                    }
                }
                
            }))
            
            alert.addAction(UIAlertAction(title: "Add to Existing Activity", style: .default, handler: { (_) in
                
                if let activity = self.activity {
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
            
            alert.addAction(UIAlertAction(title: "Add to List", style: .default, handler: { (_) in
                
                // ChooseActivityTableViewController
                let destination = ChooseListTableViewController()
                let navController = UINavigationController(rootViewController: destination)
                destination.lists = self.listList
                destination.filteredLists = self.listList
                destination.fsVenue = self.place
                destination.activityType = self.activityType
                self.present(navController, animated: true, completion: nil)
                
            }))

        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))

        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
    
    func shareButtonTapped() {
        if let place = place {
            var category = ""
            var subcategory = ""
            if let rating = place.rating {
                category = "Rating: \(rating)/10"
            }
            if let price = place.price, let tier = price.tier, let categories = place.categories, !categories.isEmpty, let category = categories[0].shortName {
                switch tier {
                case 1:
                    subcategory = category + " - $"
                case 2:
                    subcategory = category + " - $$"
                case 3:
                    subcategory = category + " - $$$"
                case 4:
                    subcategory = category + " - $$$$"
                default:
                    subcategory = category
                }
            }
            var activityObject: ActivityObject
            if let activityType = activityType, let image = UIImage(named: activityType) {
                let data = compressImage(image: image)
                let activity = ["activityType": "place",
                            "activityName": "\(place.name)",
                            "activityTypeID": "\(place.id)",
                            "activityImageURL": activityType,
                            "activityCategory": "\(category)",
                            "activitySubcategory": "\(subcategory)",
                            "object": data] as [String: AnyObject]
                activityObject = ActivityObject(dictionary: activity)
            } else {
                let activity = ["activityType": "place",
                            "activityName": "\(place.name)",
                            "activityCategory": "\(category)",
                            "activitySubcategory": "\(subcategory)",
                            "activityTypeID": "\(place.id)"] as [String: AnyObject]
                activityObject = ActivityObject(dictionary: activity)
            }
            
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
            

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                print("User click Dismiss button")
            }))

            self.present(alert, animated: true, completion: {
                print("completion block")
            })
            print("shareButtonTapped")
        }
    }
    
    func bookmarkButtonTapped() {
        print("bookmarkButtonTapped")
        if let currentUserID = Auth.auth().currentUser?.uid {
            let databaseReference = Database.database().reference().child("user-fav-activities").child(currentUserID)
            if let place = place {
                print(place.name)
                databaseReference.child("places").observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists() {
                        var value = snapshot.value as! [String]
                        if value.contains("\(place.id)") {
                            if let index = value.firstIndex(of: "\(place.id)") {
                                value.remove(at: index)
                            }
                            databaseReference.updateChildValues(["places": value as NSArray])
                        } else {
                            value.append("\(place.id)")
                            databaseReference.updateChildValues(["places": value as NSArray])
                        }
                        self.favAct["places"] = value
                    } else {
                        self.favAct["places"] = ["\(place.id)"]
                        databaseReference.updateChildValues(["places": ["\(place.id)"]])
                    }
                })
            }
        }
        
    }
    
    func dotsButtonTapped() {
    
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if !schedule {
            if active, activity.conversationID == nil {
                alert.addAction(UIAlertAction(title: "Connect Activity to a Chat", style: .default, handler: { (_) in
                    print("User click Approve button")
                    self.goToChat()

                }))
            } else if active {
                alert.addAction(UIAlertAction(title: "Go to Chat", style: .default, handler: { (_) in
                    print("User click Approve button")
                    self.goToChat()

                }))
            }
        }
            
        if let localName = activity.locationName, localName != "locationName", let _ = activity.locationAddress {
            alert.addAction(UIAlertAction(title: "Go to Map", style: .default, handler: { (_) in
                print("User click Edit button")
                self.goToMap(activity: self.activity)
            }))
        }
           

       alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
           print("User click Dismiss button")
       }))

       self.present(alert, animated: true, completion: {
           print("completion block")
       })
        print("shareButtonTapped")
        
    }

}

extension PlaceDetailViewController: ChooseActivityDelegate {
    func chosenList(finished: Bool) {
        
    }
    
    func chosenActivity(mergeActivity: Activity) {
        if let activity = activity {
            let dispatchGroup = DispatchGroup()
            if mergeActivity.recipeID != nil || mergeActivity.workoutID != nil || mergeActivity.eventID != nil || mergeActivity.placeID != nil {
                if let currentUserID = Auth.auth().currentUser?.uid {
                    
                    let newActivityID = Database.database().reference().child("user-activities").child(currentUserID).childByAutoId().key ?? ""
                    let newActivity = mergeActivity.copy() as! Activity
                    newActivity.activityID = newActivityID
                    newActivity.recipeID = nil
                    newActivity.workoutID = nil
                    newActivity.eventID = nil
                    newActivity.placeID = nil
                    
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
                    if active && !activeList {
                        dispatchGroup.enter()
                        self.getSelectedFalconUsers(forActivity: mergeActivity) { (participants) in
                            let deleteFirstActivity = ActivityActions(activity: mergeActivity, active: true, selectedFalconUsers: participants)
                            deleteFirstActivity.deleteActivity()
                            dispatchGroup.leave()
                        }
                        dispatchGroup.enter()
                        self.getSelectedFalconUsers(forActivity: activity) { (participants) in
                            let deleteSecondActivity = ActivityActions(activity: activity, active: true, selectedFalconUsers: participants)
                            deleteSecondActivity.deleteActivity()
                            dispatchGroup.leave()
                        }
                        
                    // need to delete merge activity
                    } else {
                        dispatchGroup.enter()
                        self.getSelectedFalconUsers(forActivity: mergeActivity) { (participants) in
                            let deleteActivity = ActivityActions(activity: mergeActivity, active: true, selectedFalconUsers: participants)
                            deleteActivity.deleteActivity()
                            dispatchGroup.leave()
                        }
                    }
                    
                    dispatchGroup.enter()
                    self.getSelectedFalconUsers(forActivity: newActivity) { (participants) in
                        let createActivity = ActivityActions(activity: newActivity, active: false, selectedFalconUsers: participants)
                        createActivity.createNewActivity()
                        dispatchGroup.leave()
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
                
                if let oldParticipantsIDs = activity.participantsIDs {
                    if let newParticipantsIDs = mergeActivity.participantsIDs {
                        for id in oldParticipantsIDs {
                            if !newParticipantsIDs.contains(id) {
                                mergeActivity.participantsIDs!.append(id)
                            }
                        }
                    } else {
                        mergeActivity.participantsIDs = activity.participantsIDs
                    }
                }
                
                self.showActivityIndicator()
                
                // need to delete current activity
                if active && !activeList {
                    dispatchGroup.enter()
                    self.getSelectedFalconUsers(forActivity: activity) { (participants) in
                        let deleteActivity = ActivityActions(activity: activity, active: true, selectedFalconUsers: participants)
                        deleteActivity.deleteActivity()
                        dispatchGroup.leave()
                    }
                }
                
                dispatchGroup.enter()
                self.getSelectedFalconUsers(forActivity: mergeActivity) { (participants) in
                    let createActivity = ActivityActions(activity: mergeActivity, active: true, selectedFalconUsers: participants)
                    createActivity.createNewActivity()
                    dispatchGroup.leave()
                    self.hideActivityIndicator()
                }
            
            }
            
            dispatchGroup.notify(queue: .main) {
               self.actAddAlert()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                    self.removeActAddAlert()
                })
            }
        }
    }
}
