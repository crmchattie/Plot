//
//  ParticipantsFetcher.swift
//  Plot
//
//  Created by Cory McHattie on 9/8/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import Foundation
import Firebase

class ParticipantsFetcher: NSObject {
    class func getParticipants(forActivity activity: Activity?, completion: @escaping ([User])->()) {
        guard let activity = activity, let participantsIDs = activity.participantsIDs else {
            completion([])
            return
        }
        
        let group = DispatchGroup()
        var participants: [User] = []
        for id in participantsIDs {
            // Only if the current user is created this activity
            if id.isEmpty {
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
            completion(participants)
        }
    }
    
    class func getAcceptedParticipant(forActivity activity: Activity?, allParticipants participants: [User], completion: @escaping ([User])->Void) {
        guard let activity = activity else {
            completion(participants)
            return
        }
        if participants.count > 0 {
            let dispatchGroup = DispatchGroup()
            var acceptedParticipant: [User] = []
            for user in participants {
                dispatchGroup.enter()
                guard let userID = user.id else {
                    dispatchGroup.leave()
                    continue
                }
                
                // If user is admin of the activity it won't have an invitation
                // It should be considered as accepted
                if userID == activity.admin {
                    acceptedParticipant.append(user)
                    dispatchGroup.leave()
                    continue
                }
                
                InvitationsFetcher.activityInvitation(forUser: userID, activityID: activity.activityID!) { (invitation) in
                    if let invitation = invitation, invitation.status == .accepted {
                        acceptedParticipant.append(user)
                    }
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.notify(queue: .main) {
                completion(acceptedParticipant)
            }
        } else {
            completion([])
        }
    }
    
    class func getParticipants(forTransaction transaction: Transaction?, completion: @escaping ([User])->()) {
        if let transaction = transaction, let participantsIDs = transaction.participantsIDs {
            let group = DispatchGroup()
            var participants: [User] = []
            for id in participantsIDs {
                if id.isEmpty {
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
                completion(participants)
            }
        } else {
            let participants: [User] = []
            completion(participants)
        }
    }
    
    class func getParticipants(forAccount account: MXAccount?, completion: @escaping ([User])->()) {
        if let account = account, let participantsIDs = account.participantsIDs {
            let group = DispatchGroup()
            var participants: [User] = []
            
            for id in participantsIDs {
                if id.isEmpty {
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
                completion(participants)
            }
        } else {
            let participants: [User] = []
            completion(participants)
        }
    }
    
    class func getParticipants(forHolding holding: MXHolding?, completion: @escaping ([User])->()) {
        if let holding = holding, let participantsIDs = holding.participantsIDs {
            let group = DispatchGroup()
            var participants: [User] = []
            
            for id in participantsIDs {
                if id.isEmpty {
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
                completion(participants)
            }
        } else {
            let participants: [User] = []
            completion(participants)
        }
    }
    
    class func getParticipants(forList list: ListType?, completion: @escaping ([User])->()) {
        if let list = list, let participantsIDs = list.participantsIDs {
            let group = DispatchGroup()
            var participants: [User] = []
            
            for id in participantsIDs {
                if id.isEmpty {
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
                completion(participants)
            }
        } else {
            let participants: [User] = []
            completion(participants)
        }
    }
    
    class func getParticipants(forCalendar calendar: CalendarType?, completion: @escaping ([User])->()) {
        if let calendar = calendar, let participantsIDs = calendar.participantsIDs {
            let group = DispatchGroup()
            var participants: [User] = []
            
            for id in participantsIDs {
                if id.isEmpty {
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
                completion(participants)
            }
        } else {
            let participants: [User] = []
            completion(participants)
        }
    }
    
    class func getParticipants(forWorkout workout: Workout?, completion: @escaping ([User])->()) {
        if let workout = workout, let participantsIDs = workout.participantsIDs {
            let group = DispatchGroup()
            var participants: [User] = []
            
            for id in participantsIDs {
                if id.isEmpty {
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
                completion(participants)
            }
        } else {
            let participants: [User] = []
            completion(participants)
        }
    }
    
    class func getParticipants(forMindfulness mindfulness: Mindfulness?, completion: @escaping ([User])->()) {
        if let mindfulness = mindfulness, let participantsIDs = mindfulness.participantsIDs {
            let group = DispatchGroup()
            var participants: [User] = []
            
            for id in participantsIDs {
                if id.isEmpty {
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
                completion(participants)
            }
        } else {
            let participants: [User] = []
            completion(participants)
        }
    }
    
    class func getParticipants(forMood mood: Mood?, completion: @escaping ([User])->()) {
        if let mood = mood, let participantsIDs = mood.participantsIDs {
            let group = DispatchGroup()
            var participants: [User] = []
            
            for id in participantsIDs {
                if id.isEmpty {
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
                completion(participants)
            }
        } else {
            let participants: [User] = []
            completion(participants)
        }
    }
    
    class func getParticipants(grocerylist: Grocerylist?, checklist: Checklist?, packinglist: Packinglist?, activitylist: Activitylist?, completion: @escaping ([User])->()) {
        if let grocerylist = grocerylist, let participantsIDs = grocerylist.participantsIDs {
            let group = DispatchGroup()
            var participants: [User] = []
            for id in participantsIDs {
                if id.isEmpty {
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
                completion(participants)
            }
        } else if let checklist = checklist, let participantsIDs = checklist.participantsIDs {
            let group = DispatchGroup()
            var participants: [User] = []
            for id in participantsIDs {
                if id.isEmpty {
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
                completion(participants)
            }
        } else if let activitylist = activitylist, let participantsIDs = activitylist.participantsIDs {
            let group = DispatchGroup()
            var participants: [User] = []
            for id in participantsIDs {
                if id.isEmpty {
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
                completion(participants)
            }
        } else if let packinglist = packinglist, let participantsIDs = packinglist.participantsIDs {
            let group = DispatchGroup()
            var participants: [User] = []
            for id in participantsIDs {
                if id.isEmpty {
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
                completion(participants)
            }
        } else {
            return
        }
    }
}
