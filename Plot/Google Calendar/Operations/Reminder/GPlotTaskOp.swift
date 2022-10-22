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
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            self.finish()
            return
        }
        let reference = Database.database().reference().child(userReminderTasksEntity).child(currentUserID).child(reminderTasksKey)
        let dispatchGroup = DispatchGroup()
        for activity in activities {
            if let activityID = activity.activityID {
                dispatchGroup.enter()
                if let _ = activity.externalActivityID {
                    googleCalService.updateTask(for: activity)
                    dispatchGroup.leave()
                } else {
                    googleCalService.storeTask(for: activity) { task in
                        if let task = task, let id = task.identifier {
                            let listTaskActivityValue: [String : Any] = ["activityID": activityID as AnyObject]
                            reference.child(id).updateChildValues(listTaskActivityValue) { (_, _) in
                                let userReference = Database.database().reference().child(userActivitiesEntity).child(currentUserID).child(activityID).child(messageMetaDataFirebaseFolder)
                                let values:[String : Any] = ["externalActivityID": id as Any]
                                userReference.updateChildValues(values)
                                dispatchGroup.leave()
                            }
                        } else {
                            dispatchGroup.leave()
                        }
                    }
                }
            }
        }
        dispatchGroup.notify(queue: .global()) {
            self.finish()
        }
    }
}
