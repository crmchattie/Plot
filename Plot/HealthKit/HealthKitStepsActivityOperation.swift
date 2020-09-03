//
//  HealthKitStepsActivityOperation.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-09-01.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import HealthKit

class HealthKitStepsActivityOperation: AsyncOperation {
    private var startDate: Date
    weak var delegate: HealthKitActivityOperationDelegate?
    var annualAverageSteps: Int?
    
    init(date: Date) {
        self.startDate = date
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        HealthKitService.getCumulativeSumSample(forIdentifier: .stepCount, unit: .count(), date: self.startDate) { [weak self] stepsResult in
            guard let stepsResult = stepsResult, stepsResult > 0, let _self = self else {
                self?.finish()
                return
            }

            let steps = Int(stepsResult)
            let stepsActivity = Activity(dictionary: ["activityID": UUID().uuidString as AnyObject])
            
            let calendar = Calendar.current
            let startDate = calendar.startOfDay(for: _self.startDate)
            let endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: _self.startDate)!
            stepsActivity.startDateTime = NSNumber(value: Int(startDate.timeIntervalSince1970))
            stepsActivity.endDateTime = NSNumber(value: Int(endDate.timeIntervalSince1970))
            //stepsActivity.activityType = ActivityType.workout.rawValue
            stepsActivity.name = "Steps"
            stepsActivity.activityType = "\(steps) steps today"
            
            if let annualAverageSteps = _self.annualAverageSteps {
                stepsActivity.activityDescription = "\(annualAverageSteps) steps on average"
            }
            
            _self.delegate?.insertActivity(_self, stepsActivity)
            self?.finish()
        }
    }
}

protocol HealthKitActivityOperationDelegate: class {
    func insertActivity(_ operation: HealthKitStepsActivityOperation, _ activity: Activity)
}
