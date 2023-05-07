//
//  SleepStorageOperation.swift
//  Plot
//
//  Created by Cory McHattie on 4/18/23.
//  Copyright © 2023 Immature Creations. All rights reserved.
//

import Foundation
import HealthKit
import Firebase

class SleepStorageOperation: AsyncOperation {
    private let dateFormatter = ISO8601DateFormatter()
    
    private var date: Date
    init(date: Date) {
        self.date = date
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        let startDate = date.localTime.startOfDay.addHours(18).addingTimeInterval(-Double(TimeZone.current.secondsFromGMT(for: Date())))
        let endDate = startDate.addDays(1)
        HealthKitService.getAllCategoryTypeSamples(forIdentifier:.sleepAnalysis, startDate: startDate, endDate: endDate) { [weak self] sleepSamples, error  in
            guard let sleepSamples = sleepSamples, sleepSamples.count > 0, error == nil, let currentUserID = Auth.auth().currentUser?.uid, let _self = self else {
                print("finish SleepStorageOperation")
                self?.finish()
                return
            }
                        
            var map: [Int: Double] = [:]
            
            for sample in sleepSamples {
                if let sleepValue = HKCategoryValueSleepAnalysis(rawValue: sample.value) {
                    let timeSum = sample.endDate.timeIntervalSince(sample.startDate)
                    map[sleepValue.rawValue, default: 0] += timeSum
                }
            }
            
            var values = [String : Any]()
            for key in map.keys {
                if let sleepValue = HKCategoryValueSleepAnalysis(rawValue: key) {
                    let timeSum = map[key]
                    switch sleepValue {
                    case .inBed:
                        values["inBed"] = timeSum
                    case .asleepUnspecified:
                        values["asleepUnspecified"] = timeSum
                    case .asleep:
                        values["asleep"] = timeSum
                    case .awake:
                        values["awake"] = timeSum
                    case .asleepCore:
                        values["asleepCore"] = timeSum
                    case .asleepDeep:
                        values["asleepDeep"] = timeSum
                    case .asleepREM:
                        values["asleepREM"] = timeSum
                    @unknown default:
                        break
                    }
                }
            }
            
            let dateString = _self.dateFormatter.string(from: endDate.startOfDay)
            let ref = Database.database().reference()
            ref.child(userSleepEntity).child(currentUserID).child(dateString).setValue(values)
            
            print("finish SleepStorageOperation")
                self?.finish()
        }
    }
}
