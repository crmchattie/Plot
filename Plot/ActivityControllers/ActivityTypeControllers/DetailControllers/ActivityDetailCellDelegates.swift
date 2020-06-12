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
    func servingsUpdated(servings: Int) {
        if let activity = activity, servings != detailedRecipe?.servings {
            activity.servings = servings
            fetchDetails()
        } else if self.servings != nil, servings != detailedRecipe?.servings {
            self.servings = servings
            fetchDetails()
        }
    }
    
    func plusButtonTapped() {
        if activeRecipe {
            if let recipe = self.detailedRecipe {
                var updatedRecipe = recipe
                if updatedRecipe.title.contains("/") {
                    updatedRecipe.title = updatedRecipe.title.replacingOccurrences(of: "/", with: "")
                }
                if updatedRecipe.title.contains(".") {
                    updatedRecipe.title = updatedRecipe.title.replacingOccurrences(of: ".", with: "")
                }
                if updatedRecipe.title.contains("#") {
                    updatedRecipe.title = updatedRecipe.title.replacingOccurrences(of: "#", with: "")
                }
                if updatedRecipe.title.contains("$") {
                    updatedRecipe.title = updatedRecipe.title.replacingOccurrences(of: "$", with: "")
                }
                if updatedRecipe.title.contains("[") {
                    updatedRecipe.title = updatedRecipe.title.replacingOccurrences(of: "[", with: "")
                }
                if updatedRecipe.title.contains("]") {
                    updatedRecipe.title = updatedRecipe.title.replacingOccurrences(of: "]", with: "")
                }
                self.recipeDelegate?.updateRecipe(recipe: updatedRecipe)
                self.navigationController?.backToViewController(viewController: GrocerylistViewController.self)
                return
            }
        }
        if active, schedule, let activity = activity {
            
            let membersIDs = self.fetchMembersIDs()
            activity.participantsIDs = membersIDs.0
            
            self.delegate?.updateSchedule(schedule: activity)
            if let recipe = self.detailedRecipe {
                self.delegate?.updateIngredients(recipe: recipe, recipeID: nil)
                self.navigationController?.backToViewController(viewController: CreateActivityViewController.self)
                return
            }
        }
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if active, !schedule, let activity = activity {
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
            
            alert.addAction(UIAlertAction(title: "Duplicate & Merge with Activity", style: .default, handler: { (_) in
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
            
        } else if schedule, let _ = umbrellaActivity {
            alert.addAction(UIAlertAction(title: "Add to Schedule", style: .default, handler: { (_) in
                print("User click Approve button")
                if let activity = self.activity {
                    activity.name = self.recipe?.title
                    
                    let membersIDs = self.fetchMembersIDs()
                    activity.participantsIDs = membersIDs.0
                    
                    self.delegate?.updateSchedule(schedule: activity)
                    if let recipe = self.detailedRecipe {
                        self.delegate?.updateIngredients(recipe: recipe, recipeID: nil)
                    }
                    
                    self.navigationController?.backToViewController(viewController: CreateActivityViewController.self)
                }
            }))
            
        } else if !schedule {
            alert.addAction(UIAlertAction(title: "Create New Activity", style: .default, handler: { (_) in
                print("User click Approve button")
                // create new activity
                
                if let activity = self.activity {
                    activity.name = self.recipe?.title
                                        
                    self.showActivityIndicator()
                    let createActivity = ActivityActions(activity: activity, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    createActivity.createNewActivity()
                    self.hideActivityIndicator()
                                        
                    let nav = self.tabBarController!.viewControllers![1] as! UINavigationController
                    if nav.topViewController is MasterActivityContainerController {
                        let homeTab = nav.topViewController as! MasterActivityContainerController
                        homeTab.customSegmented.setIndex(index: 2)
                        homeTab.changeToIndex(index: 2)
                    }
                    self.tabBarController?.selectedIndex = 1
                    self.navigationController?.backToViewController(viewController: ActivityTypeViewController.self)
                }
                
            }))
            
            alert.addAction(UIAlertAction(title: "Merge with Existing Activity", style: .default, handler: { (_) in
                
                if let activity = self.activity {
                    activity.name = self.recipe?.title
                    
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
    func chosenList(finished: Bool) {
        
    }
    
    func chosenActivity(mergeActivity: Activity) {
        if let activity = activity {
            let dispatchGroup = DispatchGroup()
            if mergeActivity.recipeID != nil || mergeActivity.workoutID != nil || mergeActivity.eventID != nil {
                if let currentUserID = Auth.auth().currentUser?.uid {
                    
                    let newActivityID = Database.database().reference().child("user-activities").child(currentUserID).childByAutoId().key ?? ""
                    let newActivity = mergeActivity.copy() as! Activity
                    newActivity.activityID = newActivityID
                    newActivity.recipeID = nil
                    newActivity.workoutID = nil
                    newActivity.eventID = nil
                    
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
                if active {
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
                if self.active {
                    self.navigationController?.backToViewController(viewController: MasterActivityContainerController.self)
                } else {
                    let nav = self.tabBarController!.viewControllers![1] as! UINavigationController
                    if nav.topViewController is MasterActivityContainerController {
                        let homeTab = nav.topViewController as! MasterActivityContainerController
                        homeTab.customSegmented.setIndex(index: 2)
                        homeTab.changeToIndex(index: 2)
                    }
                    self.tabBarController?.selectedIndex = 1
                    self.navigationController?.backToViewController(viewController: ActivityTypeViewController.self)
                }
            }
        }
    }
}

extension WorkoutDetailViewController: ActivityDetailCellDelegate {
    func servingsUpdated(servings: Int) {
        
    }
    
    func plusButtonTapped() {
        if active, schedule, let activity = activity {
            
            let membersIDs = self.fetchMembersIDs()
            activity.participantsIDs = membersIDs.0
            
            self.delegate?.updateSchedule(schedule: activity)
            self.navigationController?.backToViewController(viewController: CreateActivityViewController.self)
            return
                
        }
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if active, !schedule, let activity = activity {
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
            
            alert.addAction(UIAlertAction(title: "Duplicate & Merge with Activity", style: .default, handler: { (_) in
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
            
        } else if schedule, let _ = umbrellaActivity {
            alert.addAction(UIAlertAction(title: "Add to Schedule", style: .default, handler: { (_) in
                print("User click Approve button")
                if let activity = self.activity {
                    activity.name = self.workout?.title
                    
                    let membersIDs = self.fetchMembersIDs()
                    activity.participantsIDs = membersIDs.0
                    
                    self.delegate?.updateSchedule(schedule: activity)
                    
                    self.navigationController?.backToViewController(viewController: CreateActivityViewController.self)
                }
            }))
            
        } else if !schedule {
            alert.addAction(UIAlertAction(title: "Create New Activity", style: .default, handler: { (_) in
                print("User click Approve button")
                // create new activity
                
                if let activity = self.activity {
                    activity.name = self.workout?.title
                                        
                    self.showActivityIndicator()
                    let createActivity = ActivityActions(activity: activity, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    createActivity.createNewActivity()
                    self.hideActivityIndicator()
                    
                    let nav = self.tabBarController!.viewControllers![1] as! UINavigationController
                    if nav.topViewController is MasterActivityContainerController {
                        let homeTab = nav.topViewController as! MasterActivityContainerController
                        homeTab.customSegmented.setIndex(index: 2)
                        homeTab.changeToIndex(index: 2)
                    }
                    self.tabBarController?.selectedIndex = 1
                    self.navigationController?.backToViewController(viewController: ActivityTypeViewController.self)
                }
                
            }))
            
            alert.addAction(UIAlertAction(title: "Merge with Existing Activity", style: .default, handler: { (_) in
                
                if let activity = self.activity {
                    activity.name = self.workout?.title
                                        
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
            if let workout = type as? Workout {
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

extension WorkoutDetailViewController: ChooseActivityDelegate {
    func chosenList(finished: Bool) {
        
    }
    
    func chosenActivity(mergeActivity: Activity) {
        if let activity = activity {
            let dispatchGroup = DispatchGroup()
            if mergeActivity.recipeID != nil || mergeActivity.workoutID != nil || mergeActivity.eventID != nil {
                if let currentUserID = Auth.auth().currentUser?.uid {
                    
                    let newActivityID = Database.database().reference().child("user-activities").child(currentUserID).childByAutoId().key ?? ""
                    let newActivity = mergeActivity.copy() as! Activity
                    newActivity.activityID = newActivityID
                    newActivity.recipeID = nil
                    newActivity.workoutID = nil
                    newActivity.eventID = nil
                    
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
                if active {
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
                if self.active {
                    self.navigationController?.backToViewController(viewController: MasterActivityContainerController.self)
                } else {
                    let nav = self.tabBarController!.viewControllers![1] as! UINavigationController
                    if nav.topViewController is MasterActivityContainerController {
                        let homeTab = nav.topViewController as! MasterActivityContainerController
                        homeTab.customSegmented.setIndex(index: 2)
                        homeTab.changeToIndex(index: 2)
                    }
                    self.tabBarController?.selectedIndex = 1
                    self.navigationController?.backToViewController(viewController: ActivityTypeViewController.self)
                }
            }
        }
    }
}

extension EventDetailViewController: ActivityDetailCellDelegate {
    func servingsUpdated(servings: Int) {
        
    }
    
    func plusButtonTapped() {
        if active, schedule, let activity = activity {
            
            let membersIDs = self.fetchMembersIDs()
            activity.participantsIDs = membersIDs.0
            
            self.delegate?.updateSchedule(schedule: activity)
            self.navigationController?.backToViewController(viewController: CreateActivityViewController.self)
            return
                
        }
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if active, !schedule, let activity = activity {
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
            
            alert.addAction(UIAlertAction(title: "Duplicate & Merge with Activity", style: .default, handler: { (_) in
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
            
        } else if schedule, let _ = umbrellaActivity {
            alert.addAction(UIAlertAction(title: "Add to Schedule", style: .default, handler: { (_) in
                print("User click Approve button")
                if let activity = self.activity {
                    activity.name = self.event?.name
                    
                    let membersIDs = self.fetchMembersIDs()
                    activity.participantsIDs = membersIDs.0
                    
                    self.delegate?.updateSchedule(schedule: activity)
                    
                    self.navigationController?.backToViewController(viewController: CreateActivityViewController.self)
                }
            }))
            
        } else if !schedule {
            alert.addAction(UIAlertAction(title: "Create New Activity", style: .default, handler: { (_) in
                print("User click Approve button")
                // create new activity
                
                if let activity = self.activity {
                    activity.name = self.event?.name
                                        
                    self.showActivityIndicator()
                    let createActivity = ActivityActions(activity: activity, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    createActivity.createNewActivity()
                    self.hideActivityIndicator()
                                        
                    let nav = self.tabBarController!.viewControllers![1] as! UINavigationController
                    if nav.topViewController is MasterActivityContainerController {
                        let homeTab = nav.topViewController as! MasterActivityContainerController
                        homeTab.customSegmented.setIndex(index: 2)
                        homeTab.changeToIndex(index: 2)
                    }
                    self.tabBarController?.selectedIndex = 1
                    self.navigationController?.backToViewController(viewController: ActivityTypeViewController.self)
                }
                
            }))
            
            alert.addAction(UIAlertAction(title: "Merge with Existing Activity", style: .default, handler: { (_) in
                
                if let activity = self.activity {
                    activity.name = self.event?.name
                    
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
            if let event = type as? Event {
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
            } else if let attraction = type as? Attraction {
                print(attraction.name)
                databaseReference.child("attractions").observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists() {
                        var value = snapshot.value as! [String]
                        if value.contains("\(attraction.id)") {
                            if let index = value.firstIndex(of: "\(attraction.id)") {
                                value.remove(at: index)
                            }
                            databaseReference.updateChildValues(["attractions": value as NSArray])
                        } else {
                            value.append("\(attraction.id)")
                            databaseReference.updateChildValues(["attractions": value as NSArray])
                        }
                        self.favAct["attractions"] = value
                    } else {
                        self.favAct["attractions"] = ["\(attraction.id)"]
                        databaseReference.updateChildValues(["attractions": ["\(attraction.id)"]])
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

extension EventDetailViewController: ChooseActivityDelegate {
    func chosenList(finished: Bool) {
        
    }
    
    func chosenActivity(mergeActivity: Activity) {
        if let activity = activity {
            let dispatchGroup = DispatchGroup()
            if mergeActivity.recipeID != nil || mergeActivity.workoutID != nil || mergeActivity.eventID != nil {
                if let currentUserID = Auth.auth().currentUser?.uid {
                    
                    let newActivityID = Database.database().reference().child("user-activities").child(currentUserID).childByAutoId().key ?? ""
                    let newActivity = mergeActivity.copy() as! Activity
                    newActivity.activityID = newActivityID
                    newActivity.recipeID = nil
                    newActivity.workoutID = nil
                    newActivity.eventID = nil
                    
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
                if active {
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
                if self.active {
                    self.navigationController?.backToViewController(viewController: MasterActivityContainerController.self)
                } else {
                    let nav = self.tabBarController!.viewControllers![1] as! UINavigationController
                    if nav.topViewController is MasterActivityContainerController {
                        let homeTab = nav.topViewController as! MasterActivityContainerController
                        homeTab.customSegmented.setIndex(index: 2)
                        homeTab.changeToIndex(index: 2)
                    }
                    self.tabBarController?.selectedIndex = 1
                    self.navigationController?.backToViewController(viewController: ActivityTypeViewController.self)
                }
            }
        }
    }
}
