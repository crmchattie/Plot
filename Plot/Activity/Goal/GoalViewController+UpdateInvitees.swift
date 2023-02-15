//
//  GoalViewController+UpdateInvitees.swift
//  Plot
//
//  Created by Cory McHattie on 2/14/23.
//  Copyright © 2023 Immature Creations. All rights reserved.
//

import Foundation
import Eureka
import Firebase

extension GoalViewController: UpdateInvitees {
    func updateInvitees(selectedFalconUsers: [User]) {
        if let inviteesRow: LabelRow = form.rowBy(tag: "Participants") {
            self.selectedFalconUsers = selectedFalconUsers
            inviteesRow.value = String(selectedFalconUsers.count + 1)
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
