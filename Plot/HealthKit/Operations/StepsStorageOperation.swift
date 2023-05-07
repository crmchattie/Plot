//
//  StepsStorageOperation.swift
//  Plot
//
//  Created by Cory McHattie on 4/18/23.
//  Copyright © 2023 Immature Creations. All rights reserved.
//

import Foundation
import HealthKit
import Firebase

class StepsStorageOperation: AsyncOperation {
    private var startDate: Date
    private let dateFormatter = ISO8601DateFormatter()
    
    init(date: Date) {
        self.startDate = date
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        HealthKitService.getCumulativeSumSampleAverageAndRecent(forIdentifier: .stepCount, unit: .count(), date: self.startDate) { [weak self] stepsResult, _, _ in
            guard let stepsResult = stepsResult, stepsResult > 0, let currentUserID = Auth.auth().currentUser?.uid, let _self = self else {
                print("finish StepsStorageOperation")
                self?.finish()
                return
            }
            
            let dateString = _self.dateFormatter.string(from: _self.startDate.startOfDay)
            let ref = Database.database().reference()
            ref.child(userStepsEntity).child(currentUserID).child(dateString).setValue(stepsResult)

            print("finish StepsStorageOperation")
            self?.finish()
        }
    }
}
