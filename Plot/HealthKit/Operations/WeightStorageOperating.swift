//
//  WeightStorageOperating.swift
//  Plot
//
//  Created by Cory McHattie on 4/18/23.
//  Copyright © 2023 Immature Creations. All rights reserved.
//

import Foundation
import HealthKit
import Firebase

class WeightStorageOperation: AsyncOperation {
    private var startDate: Date
    private let dateFormatter = ISO8601DateFormatter()
    
    init(date: Date) {
        self.startDate = date
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        let unit = HKUnit.pound()
        HealthKitService.getLatestDiscreteDailyAverageSampleForDay(forIdentifier: .bodyMass, unit: unit, date: self.startDate) { [weak self] weight, _ in
            guard let weight = weight, let currentUserID = Auth.auth().currentUser?.uid, let _self = self else {
                print("finish WeightStorageOperation")
                self?.finish()
                return
            }
            
            let dateString = _self.dateFormatter.string(from: _self.startDate.startOfDay)
            let ref = Database.database().reference()
            let values: [String : Any] = ["weight": weight, "unit": unit.unitString]
            ref.child(userBodyMassEntity).child(currentUserID).child(dateString).updateChildValues(values)
            print("finish WeightStorageOperation")
                self?.finish()
        }
    }
}
