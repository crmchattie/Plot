//
//  EventViewController+UpdateInvitees.swift
//  Plot
//
//  Created by Hafiz Usama on 10/23/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import Foundation
import Eureka
import Firebase

extension EventViewController: UpdateInvitees {
    func updateInvitees(selectedFalconUsers: [User]) {
        if let inviteesRow: LabelRow = form.rowBy(tag: "Participants") {
            self.selectedFalconUsers = selectedFalconUsers
            self.acceptedParticipant = acceptedParticipant.filter { selectedFalconUsers.contains($0) }
            
            inviteesRow.value = String(selectedFalconUsers.count + 1)
            inviteesRow.updateCell()
            
            if active {
                showActivityIndicator()
//                if let container = container {
//                    ContainerFunctions.updateParticipants(containerID: container.id, selectedFalconUsers: selectedFalconUsers)
//                } else {
//                    let createActivity = ActivityActions(activity: activity, active: active, selectedFalconUsers: selectedFalconUsers)
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
