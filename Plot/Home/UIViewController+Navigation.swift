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
    var participants: [String: [User]] { get set }
    
    func showActivityIndicator()
    func hideActivityIndicator()
}

extension ActivityDetailShowing {
    
    func showTaskDetail(task: Activity) {
        let destination = TaskViewController(networkController: networkController)
        destination.hidesBottomBarWhenPushed = true
        destination.task = task
        self.getParticipants(forActivity: task) { (participants) in
            destination.selectedFalconUsers = participants
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    func showEventDetail(event: Activity) {
        let destination = EventViewController(networkController: networkController)
        destination.hidesBottomBarWhenPushed = true
        destination.activity = event
        destination.invitation = self.networkController.activityService.invitations[event.activityID ?? ""]
        self.getParticipants(forActivity: event) { (participants) in
            InvitationsFetcher.getAcceptedParticipant(forActivity: event, allParticipants: participants) { acceptedParticipant in
                destination.acceptedParticipant = acceptedParticipant
                destination.selectedFalconUsers = participants
                self.navigationController?.pushViewController(destination, animated: true)
            }
        }
    }
    
    func getParticipants(forActivity activity: Activity, completion: @escaping ([User])->()) {
        guard let activityID = activity.activityID, let participantsIDs = activity.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let group = DispatchGroup()
        let olderParticipants = self.participants[activityID]
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
            self.participants[activityID] = participants
            completion(participants)
        }
    }
}
