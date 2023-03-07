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
            inviteesRow.value = String(selectedFalconUsers.count)
            inviteesRow.updateCell()
            
            if active {
                showActivityIndicator()
//                if let container = container {
//                    ContainerFunctions.updateParticipants(containerID: container.id, selectedFalconUsers: selectedFalconUsers)
//                } else {
//                    let createActivity = ActivityActions(activity: task, active: active, selectedFalconUsers: selectedFalconUsers)
//                    createActivity.updateActivityParticipants()
//                }
                
                let createActivity = ActivityActions(activity: task, active: active, selectedFalconUsers: selectedFalconUsers)
                createActivity.updateActivityParticipants()
                
                hideActivityIndicator()
            }
//            decimalRowFunc()
        }
    }
}

