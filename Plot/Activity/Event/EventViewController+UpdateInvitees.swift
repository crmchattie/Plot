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
            
            if activity.admin == nil || activity.admin == Auth.auth().currentUser?.uid {
                inviteesRow.value = String(self.acceptedParticipant.count + 1)
            } else {
                inviteesRow.value = String(self.acceptedParticipant.count)
            }
            inviteesRow.updateCell()
            
            if active {
                showActivityIndicator()
                if let container = container {
                    ContainerFunctions.updateParticipants(containerID: container.id, selectedFalconUsers: selectedFalconUsers)
                } else {
                    let createActivity = ActivityActions(activity: activity, active: active, selectedFalconUsers: selectedFalconUsers)
                    createActivity.updateActivityParticipants()
                }
                hideActivityIndicator()
            }
//            decimalRowFunc()
        }
    }
}
