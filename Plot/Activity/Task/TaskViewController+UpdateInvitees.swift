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
        if let inviteesRow: LabelRow = form.rowBy(tag: "Participants") {
            self.selectedFalconUsers = selectedFalconUsers
            if task.admin == nil || task.admin == Auth.auth().currentUser?.uid {
                inviteesRow.value = String(self.selectedFalconUsers.count + 1)
            } else {
                inviteesRow.value = String(self.selectedFalconUsers.count)
            }
            inviteesRow.updateCell()
            
            if active {
                showActivityIndicator()
                let createActivity = ActivityActions(activity: task, active: active, selectedFalconUsers: selectedFalconUsers)
                createActivity.updateActivityParticipants()
                
//                for list in listList {
//                    if let grocerylist = list.grocerylist {
//                        let createGrocerylist = GrocerylistActions(grocerylist: grocerylist, active: active, selectedFalconUsers: selectedFalconUsers)
//                        createGrocerylist.updateGrocerylistParticipants()
//                    } else if let checklist = list.checklist {
//                        let createChecklist = ChecklistActions(checklist: checklist, active: active, selectedFalconUsers: selectedFalconUsers)
//                        createChecklist.updateChecklistParticipants()
//                    }
//                }
                hideActivityIndicator()
            }
            decimalRowFunc()
        }
    }
}

