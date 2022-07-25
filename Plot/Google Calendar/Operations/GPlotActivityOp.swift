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

class GPlotActivityOp: AsyncOperation {
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
        let reference = Database.database().reference().child(userCalendarEventsEntity).child(currentUserId).child(calendarEventsKey)
        // @FIX-ME - need a better way to check if event ID exists
        reference.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            if snapshot.exists(), let value = snapshot.value as? [String: [String:String]] {
                let dispatchGroup = DispatchGroup()
                let values = value.values
                let activitiesIDs = values.compactMap { $0["activityID"] }
                for activity in self!.activities {
                    if !(activity.calendarExport ?? false), let activityID = activity.activityID, !activitiesIDs.contains(activityID) {
                        dispatchGroup.enter()
                        if let event = self?.googleCalService.storeEvent(for: activity), let id = event.identifier {
                            let calendarEventActivityValue: [String : Any] = ["activityID": activityID as AnyObject]
                            reference.child(id).updateChildValues(calendarEventActivityValue) { (_, _) in
                                let userReference = Database.database().reference().child(userActivitiesEntity).child(currentUserId).child(activityID).child(messageMetaDataFirebaseFolder)
                                let values:[String : Any] = ["calendarExport": true]
                                userReference.updateChildValues(values)
                                dispatchGroup.leave()
                            }
                        } else {
                            dispatchGroup.leave()
                        }
                    }
                }
                dispatchGroup.notify(queue: .global()) {
                    self?.finish()
                }
            }
            else {
                self?.finish()
            }
        })
    }
}
