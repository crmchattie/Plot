//
//  HealthKitActivityOperation.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-09-01.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import HealthKit

class HealthKitActivityOperation: AsyncOperation {
    private var date: Date
    weak var delegate: HealthKitActivityOperationDelegate?
    
    init(date: Date) {
        self.date = date
    }
    
    override func main() {
        startFetchRequest()
    }
    
    func startFetchRequest() {
        let year = Calendar.current.component(.year, from: date)
        let month = Calendar.current.component(.month, from: date)
        let day = Calendar.current.component(.day, from: date)
        guard let lastYear = Calendar.current.date(from: DateComponents(year: year-1, month: month, day: day)) else {
            self.finish()
            return
        }
        
        HealthKitService.getCumulativeSumSample(forIdentifier: .stepCount, unit: .count(), startDate: lastYear, endDate: date) { [weak self] annualSteps in
            if let annualSteps = annualSteps {
                guard let _self = self else {
                    self?.finish()
                    return
                }
                
                let totalDays = Calendar.current.dateComponents([.day], from: lastYear, to: _self.date).day ?? 0
                let annualAverage = Int(annualSteps)/totalDays
                HealthKitService.getCumulativeSumSample(forIdentifier: .stepCount, unit: .count(), date: _self.date) { steps in
                    guard let steps = steps else {
                        self?.finish()
                        return
                    }
                        
                    let stepsActivity = Activity(dictionary: ["activityID": UUID().uuidString as AnyObject])
                    stepsActivity.activityType = ActivityType.workout.rawValue
                    stepsActivity.name = "Steps"
                    stepsActivity.activityDescription = "\(steps) steps today"
                    stepsActivity.notes = "\(annualAverage) steps on average"
                    _self.delegate?.insertActivity(_self, stepsActivity)
                    self?.finish()
                }
            }
        }
    }
}

protocol HealthKitActivityOperationDelegate: class {
    func insertActivity(_ operation: HealthKitActivityOperation, _ activity: Activity)
}
