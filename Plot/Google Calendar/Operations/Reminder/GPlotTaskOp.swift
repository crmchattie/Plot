//
//  GPlotActivityOp.swift
//  Plot
//
//  Created by Cory McHattie on 2/3/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import Firebase
import CodableFirebase

class GPlotTaskOp: AsyncOperation {
    private let googleCalService: GoogleCalService
    private var activities: [Activity]
    
    init(googleCalService: GoogleCalService, activities: [Activity]) {
        self.googleCalService = googleCalService
        self.activities = activities
    }
    
    override func main() {
        startRequest()
    }
    
    private func startRequest() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            self.finish()
            return
        }
        let reference = Database.database().reference().child(userReminderTasksEntity).child(currentUserId).child(reminderTasksKey)
        let dispatchGroup = DispatchGroup()
        for activity in activities {
            if let activityID = activity.activityID, !(activity.calendarExport ?? false) {
                dispatchGroup.enter()
                if let task = googleCalService.storeTask(for: activity), let id = task.identifier {
                    let listTaskActivityValue: [String : Any] = ["activityID": activityID as AnyObject]
                    reference.child(id).updateChildValues(listTaskActivityValue) { (_, _) in
                        let userReference = Database.database().reference().child(userActivitiesEntity).child(currentUserId).child(activityID).child(messageMetaDataFirebaseFolder)
                        let values:[String : Any] = ["calendarExport": true, "externalActivityID": id as Any]
                        userReference.updateChildValues(values)
                        dispatchGroup.leave()
                    }
                } else {
                    dispatchGroup.leave()
                }
            }
        }
        dispatchGroup.notify(queue: .global()) {
            self.finish()
        }
    }
}