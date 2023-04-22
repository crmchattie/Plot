//
//  ActiveEnergyStorageOperation.swift
//  Plot
//
//  Created by Cory McHattie on 4/18/23.
//  Copyright © 2023 Immature Creations. All rights reserved.
//

import Foundation
import HealthKit
import Firebase

class ActiveEnergyStorageOperation: AsyncOperation {
    private var startDate: Date
    private let dateFormatter = ISO8601DateFormatter()
    
    init(date: Date) {
        self.startDate = date
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        HealthKitService.getCumulativeSumSampleAverageAndRecent(forIdentifier: .activeEnergyBurned, unit: .kilocalorie(), date: self.startDate) { [weak self] caloriesResult, _, _ in
            guard let caloriesResult = caloriesResult, caloriesResult > 0, let currentUserID = Auth.auth().currentUser?.uid, let _self = self else {
                self?.finish()
                return
            }
            
            let dateString = _self.dateFormatter.string(from: _self.startDate.startOfDay)
            let ref = Database.database().reference()            
            ref.child(userActiveEnergyEntity).child(currentUserID).child(dateString).setValue(caloriesResult)

            self?.finish()
            
        }
    }
}
