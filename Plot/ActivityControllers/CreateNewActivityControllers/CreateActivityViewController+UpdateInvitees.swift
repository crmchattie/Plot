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

extension CreateActivityViewController: UpdateInvitees {
    func updateInvitees(selectedFalconUsers: [User]) {
        if let inviteesRow: ButtonRow = form.rowBy(tag: "Participants") {
            if !selectedFalconUsers.isEmpty {
                self.selectedFalconUsers = selectedFalconUsers
                self.acceptedParticipant = acceptedParticipant.filter {selectedFalconUsers.contains($0)}
                
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
            
            if active {
                showActivityIndicator()
                let createActivity = ActivityActions(activity: activity, active: active, selectedFalconUsers: selectedFalconUsers)
                createActivity.updateActivityParticipants()
                
                for list in listList {
                    if let grocerylist = list.grocerylist {
                        let createGrocerylist = GrocerylistActions(grocerylist: grocerylist, active: active, selectedFalconUsers: selectedFalconUsers)
                        createGrocerylist.updateGrocerylistParticipants()
                    } else if let checklist = list.checklist {
                        let createChecklist = ChecklistActions(checklist: checklist, active: active, selectedFalconUsers: selectedFalconUsers)
                        createChecklist.updateChecklistParticipants()
                    }
                }
                hideActivityIndicator()
            }
            
            decimalRowFunc()
        }
    }
}
