//
//  EKDeletePlotEventOp.swift
//  Plot
//
//  Created by Cory McHattie on 10/22/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import Foundation
import Firebase

class EKDeletePlotActivityOp: AsyncOperation {
    private var activity: Activity
    
    init(activity: Activity) {
        self.activity = activity
    }
    
    override func main() {
        startRequest()
    }
    
    private func startRequest() {
        guard let _ = Auth.auth().currentUser?.uid else {
            self.finish()
            return
        }
        
        ParticipantsFetcher.getParticipants(forActivity: activity) { [weak self] users in
            let activityAction = ActivityActions(activity: self!.activity, active: true, selectedFalconUsers: users)
            activityAction.deleteActivity()
            self?.finish()
        }
    }
    
}
