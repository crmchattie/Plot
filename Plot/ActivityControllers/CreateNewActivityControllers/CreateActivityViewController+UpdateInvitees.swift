//
//  CreateActivityViewController+UpdateInvitees.swift
//  Plot
//
//  Created by Hafiz Usama on 10/23/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import Foundation
import Eureka
import Firebase
import CodableFirebase

let invitationsEntity = "invitations"
let userInvitationsEntity = "user-invitations"

extension CreateActivityViewController: UpdateInvitees {
    func updateInvitees(selectedFalconUsers: [User]) {
        if let inviteesRow: ButtonRow = form.rowBy(tag: "Participants") {
            if !selectedFalconUsers.isEmpty {
                self.selectedFalconUsers = selectedFalconUsers
                self.acceptedParticipant = acceptedParticipant.filter { selectedFalconUsers.contains($0) }
                
                var participantCount = self.acceptedParticipant.count
                // If user is creating this activity (admin)
                if activity.admin == nil || activity.admin == Auth.auth().currentUser?.uid {
                    participantCount += 1
                }
                
                if participantCount > 1 {
                    self.userNamesString = "\(participantCount) participants"
                } else {
                    self.userNamesString = "1 participant"
                }
                
                inviteesRow.title = self.userNamesString
                inviteesRow.updateCell()
                
            } else {
                self.selectedFalconUsers = selectedFalconUsers
                self.acceptedParticipant = selectedFalconUsers
                inviteesRow.title = "1 participant"
                inviteesRow.updateCell()
            }
            
            let membersIDs = fetchMembersIDs()
            if Set(activity.participantsIDs!) != Set(membersIDs.0) {
                let groupActivityReference = Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder)
                updateParticipants(membersIDs: membersIDs)
                groupActivityReference.updateChildValues(["participantsIDs": membersIDs.1 as AnyObject])
            }
            
            activityCreatingGroup.notify(queue: DispatchQueue.main, execute: {
                InvitationsFetcher.updateInvitations(forActivity:self.activity, selectedParticipants: self.selectedFalconUsers) {
//                    self.hideActivityIndicator()
                }
            })
            
            decimalRowFunc()
        }
    }
    
    
}

extension Array where Element: Comparable {
    func containsSameElements(_ other: [Element]) -> Bool {
        return self.count == other.count && self.sorted() == other.sorted()
    }
}
