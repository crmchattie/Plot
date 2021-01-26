//
//  SyncPlotActivitiesOp.swift
//  Plot
//
//  Created by Cory McHattie on 1/25/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import EventKit
import Firebase
import CodableFirebase

class PlotActivityOp: AsyncOperation {
    private let eventKitService: EventKitService
    private var activities: [Activity]
    
    init(eventKitService: EventKitService, activities: [Activity]) {
        self.eventKitService = eventKitService
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
        reference.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            if snapshot.exists(), let value = snapshot.value as? [String: [String:String]] {
                let dispatchGroup = DispatchGroup()
                let values = value.values
                let activitiesIDs = values.compactMap { $0["activityID"] }
                for activity in self!.activities {
                    dispatchGroup.enter()
                    if let activityID = activity.activityID, !activitiesIDs.contains(activityID) {
                        if let event = self?.eventKitService.storeEvent(for: activity) {
//                            let calendarEventActivityValue: [String : Any] = ["activityID": activityID as AnyObject]
//                            reference.child(event.calendarItemIdentifier).updateChildValues(calendarEventActivityValue) { (_, _) in
                                dispatchGroup.leave()
//                            }
                        } else {
                            dispatchGroup.leave()
                        }
                    } else {
                        dispatchGroup.leave()
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
