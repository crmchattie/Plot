//
//  UIViewController+Navigation.swift
//  Plot
//
//  Created by Botond Magyarosi on 06.04.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

protocol ActivityDetailShowing: UIViewController {
    
    var networkController: NetworkController { get }
    var activitiesParticipants: [String: [User]] { get set }
    
    func showActivityIndicator()
    func hideActivityIndicator()
}

extension ActivityDetailShowing {
    
    func showActivityDetail(activity: Activity) {
        let dispatchGroup = DispatchGroup()
        showActivityIndicator()
        
        if let recipeString = activity.recipeID, let recipeID = Int(recipeString) {
            dispatchGroup.enter()
            Service.shared.fetchRecipesInfo(id: recipeID) { (search, err) in
                if let detailedRecipe = search {
                    dispatchGroup.leave()
                    dispatchGroup.notify(queue: .main) {
                        let destination = RecipeDetailViewController()
                        destination.hidesBottomBarWhenPushed = true
                        destination.recipe = detailedRecipe
                        destination.detailedRecipe = detailedRecipe
                        destination.activity = activity
                        destination.invitation = self.networkController.activityService.invitations[activity.activityID!]
                        destination.users = self.networkController.userService.users
                        destination.filteredUsers = self.networkController.userService.users
                        destination.activities = self.networkController.activityService.activities
                        destination.conversations = self.networkController.conversationService.conversations
                        self.getParticipants(forActivity: activity) { (participants) in
                            InvitationsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                                destination.acceptedParticipant = acceptedParticipant
                                destination.selectedFalconUsers = participants
                                self.hideActivityIndicator()
                                self.navigationController?.pushViewController(destination, animated: true)
                            }
                        }
                    }
                } else {
                    dispatchGroup.leave()
                    dispatchGroup.notify(queue: .main) {
                        self.hideActivityIndicator()
                        self.activityNotFoundAlert()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                            self.dismiss(animated: true, completion: nil)
                        })
                    }
                }
            }
        } else if let eventID = activity.eventID {
            dispatchGroup.enter()
            Service.shared.fetchEventsSegment(size: "50", id: eventID, keyword: "", attractionId: "", venueId: "", postalCode: "", radius: "", unit: "", startDateTime: "", endDateTime: "", city: "", stateCode: "", countryCode: "", classificationName: "", classificationId: "") { (search, err) in
                if let events = search?.embedded?.events {
                    let event = events[0]
                    dispatchGroup.leave()
                    dispatchGroup.notify(queue: .main) {
                        let destination = EventDetailViewController()
                        destination.hidesBottomBarWhenPushed = true
                        destination.event = event
                        destination.activity = activity
                        destination.invitation = self.networkController.activityService.invitations[activity.activityID!]
                        destination.users = self.networkController.userService.users
                        destination.filteredUsers = self.networkController.userService.users
                        destination.activities = self.networkController.activityService.activities
                        destination.conversations = self.networkController.conversationService.conversations
                        self.getParticipants(forActivity: activity) { (participants) in
                            InvitationsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                                destination.acceptedParticipant = acceptedParticipant
                                destination.selectedFalconUsers = participants
                                self.hideActivityIndicator()
                                self.navigationController?.pushViewController(destination, animated: true)
                            }
                        }
                    }
                } else {
                    dispatchGroup.leave()
                    dispatchGroup.notify(queue: .main) {
                        self.hideActivityIndicator()
                        self.activityNotFoundAlert()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                            self.dismiss(animated: true, completion: nil)
                        })
                    }
                }
            }
        } else if let workoutID = activity.workoutID {
            var reference = Database.database().reference()
            dispatchGroup.enter()
            reference = Database.database().reference().child("workouts").child("workouts")
            reference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                    if let workout = try? FirebaseDecoder().decode(PreBuiltWorkout.self, from: workoutSnapshotValue) {
                        dispatchGroup.leave()
                        let destination = WorkoutDetailViewController()
                        destination.hidesBottomBarWhenPushed = true
                        destination.workout = workout
                        destination.intColor = 0
                        destination.activity = activity
                        destination.invitation = self.networkController.activityService.invitations[activity.activityID!]
                        destination.users = self.networkController.userService.users
                        destination.filteredUsers = self.networkController.userService.users
                        destination.activities = self.networkController.activityService.activities
                        destination.conversations = self.networkController.conversationService.conversations
                        self.getParticipants(forActivity: activity) { (participants) in
                            InvitationsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                                destination.acceptedParticipant = acceptedParticipant
                                destination.selectedFalconUsers = participants
                                self.hideActivityIndicator()
                                self.navigationController?.pushViewController(destination, animated: true)
                            }
                        }
                    }
                }
            })
            { (error) in
                print(error.localizedDescription)
            }
        } else if let attractionID = activity.attractionID {
            dispatchGroup.enter()
            Service.shared.fetchAttractionsSegment(size: "50", id: attractionID, keyword: "", classificationName: "", classificationId: "") { (search, err) in
                if let attraction = search?.embedded?.attractions![0] {
                    dispatchGroup.leave()
                    dispatchGroup.notify(queue: .main) {
                        let destination = EventDetailViewController()
                        destination.hidesBottomBarWhenPushed = true
                        destination.attraction = attraction
                        destination.activity = activity
                        destination.invitation = self.networkController.activityService.invitations[activity.activityID!]
                        destination.users = self.networkController.userService.users
                        destination.filteredUsers = self.networkController.userService.users
                        destination.activities = self.networkController.activityService.activities
                        destination.conversations = self.networkController.conversationService.conversations
                        self.getParticipants(forActivity: activity) { (participants) in
                            InvitationsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                                destination.acceptedParticipant = acceptedParticipant
                                destination.selectedFalconUsers = participants
                                self.hideActivityIndicator()
                                self.navigationController?.pushViewController(destination, animated: true)
                            }
                        }
                    }
                } else {
                    dispatchGroup.leave()
                    dispatchGroup.notify(queue: .main) {
                        self.hideActivityIndicator()
                        self.activityNotFoundAlert()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                            self.dismiss(animated: true, completion: nil)
                        })
                    }
                }
            }
        } else if let placeID = activity.placeID {
            dispatchGroup.enter()
            Service.shared.fetchFSDetails(id: placeID) { (search, err) in
                if let place = search?.response?.venue {
                    dispatchGroup.leave()
                    dispatchGroup.notify(queue: .main) {
                        let destination = PlaceDetailViewController()
                        destination.hidesBottomBarWhenPushed = true
                        destination.place = place
                        destination.activity = activity
                        destination.invitation = self.networkController.activityService.invitations[activity.activityID!]
                        destination.users = self.networkController.userService.users
                        destination.filteredUsers = self.networkController.userService.users
                        destination.activities = self.networkController.activityService.activities
                        destination.conversations = self.networkController.conversationService.conversations
                        self.getParticipants(forActivity: activity) { (participants) in
                            InvitationsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                                destination.acceptedParticipant = acceptedParticipant
                                destination.selectedFalconUsers = participants
                                self.hideActivityIndicator()
                                self.navigationController?.pushViewController(destination, animated: true)
                            }
                        }
                    }
                } else {
                    dispatchGroup.leave()
                    dispatchGroup.notify(queue: .main) {
                        self.hideActivityIndicator()
                        self.activityNotFoundAlert()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                            self.dismiss(animated: true, completion: nil)
                        })
                    }
                }
            }
        } else {
            self.hideActivityIndicator()
            let destination = CreateActivityViewController()
            destination.hidesBottomBarWhenPushed = true
            destination.activity = activity
            destination.invitation = self.networkController.activityService.invitations[activity.activityID ?? ""]
            destination.users = self.networkController.userService.users
            destination.filteredUsers = self.networkController.userService.users
            destination.activities = self.networkController.activityService.activities
            destination.transactions = self.networkController.financeService.transactions
            destination.conversations = self.networkController.conversationService.conversations
            self.getParticipants(forActivity: activity) { (participants) in
                InvitationsFetcher.getAcceptedParticipant(forActivity: activity, allParticipants: participants) { acceptedParticipant in
                    destination.acceptedParticipant = acceptedParticipant
                    destination.selectedFalconUsers = participants
                    self.navigationController?.pushViewController(destination, animated: true)
                }
            }
        }
    }
    
    func getParticipants(forActivity activity: Activity, completion: @escaping ([User])->()) {
        guard let activityID = activity.activityID, let participantsIDs = activity.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let group = DispatchGroup()
        let olderParticipants = self.activitiesParticipants[activityID]
        var participants: [User] = []
        for id in participantsIDs {
            // Only if the current user is created this activity
            if activity.admin == currentUserID && id == currentUserID {
                continue
            }
            
            if let first = olderParticipants?.filter({$0.id == id}).first {
                participants.append(first)
                continue
            }
            
            group.enter()
            let participantReference = Database.database().reference().child("users").child(id)
            participantReference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), var dictionary = snapshot.value as? [String: AnyObject] {
                    dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                    let user = User(dictionary: dictionary)
                    participants.append(user)
                }
                
                group.leave()
            })
        }
        
        group.notify(queue: .main) {
            self.activitiesParticipants[activityID] = participants
            completion(participants)
        }
    }
}
