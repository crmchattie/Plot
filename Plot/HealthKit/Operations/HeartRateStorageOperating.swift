//
//  HeartRateStorageOperating.swift
//  Plot
//
//  Created by Cory McHattie on 4/18/23.
//  Copyright © 2023 Immature Creations. All rights reserved.
//

import Foundation
import HealthKit
import Firebase

class HeartRateStorageOperation: AsyncOperation {
    private var startDate: Date
    private let dateFormatter = ISO8601DateFormatter()
    
    init(date: Date) {
        self.startDate = date
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        guard let _ = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            self.finish()
            return
        }
                
        let beatsPerMinuteUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
        HealthKitService.getLatestDiscreteDailyAverageSampleForDay(forIdentifier: .heartRate, unit: beatsPerMinuteUnit, date: self.startDate) { [weak self] heartRate, _ in
            guard let heartRate = heartRate, heartRate > 0, let currentUserID = Auth.auth().currentUser?.uid, let _self = self else {
                print("finish HeartRateStorageOperation")
                self?.finish()
                return
            }
            
            let dateString = _self.dateFormatter.string(from: _self.startDate.startOfDay)
            let ref = Database.database().reference()
            ref.child(userHeartRateEntity).child(currentUserID).child(dateString).setValue(heartRate)

            print("finish HeartRateStorageOperation")
                self?.finish()
        }
    }
}
