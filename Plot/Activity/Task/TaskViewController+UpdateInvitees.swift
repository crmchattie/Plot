//
//  TaskViewController+UpdateInvitees.swift
//  Plot
//
//  Created by Cory McHattie on 8/16/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import Foundation
import Eureka
import Firebase

extension TaskViewController: UpdateInvitees {
    func updateInvitees(selectedFalconUsers: [User]) {
        if let inviteesRow: ButtonRow = form.rowBy(tag: "Participants") {
            if !selectedFalconUsers.isEmpty {
                self.selectedFalconUsers = selectedFalconUsers
                
                var participantCount = self.selectedFalconUsers.count
                // If user is creating this activity (admin)
                if task.admin == nil || task.admin == Auth.auth().currentUser?.uid {
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
                inviteesRow.title = "1 participant"
                inviteesRow.updateCell()
            }
            
            if active {
                showActivityIndicator()
                let createActivity = ActivityActions(activity: task, active: active, selectedFalconUsers: selectedFalconUsers)
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

