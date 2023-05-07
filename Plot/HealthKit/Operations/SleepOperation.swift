//
//  SleepOperation.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-12-09.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import HealthKit

class SleepOperation: AsyncOperation {
    weak var delegate: MetricOperationDelegate?
    
    private var date: Date
    init(date: Date) {
        self.date = date
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        let endDate = date.localTime.startOfDay.addHours(18).addingTimeInterval(-Double(TimeZone.current.secondsFromGMT(for: Date()))).addDays(1)
        let startDate = endDate.lastYear
        HealthKitService.getAllCategoryTypeSamples(forIdentifier:.sleepAnalysis, startDate: startDate, endDate: endDate) { [weak self] sleepSamples, error  in
            guard let sleepSamples = sleepSamples, sleepSamples.count > 0, error == nil, let _self = self else {
                print("finish SleepOperation")
                self?.finish()
                return
            }
            
            var typeOfSleep: PlotSleepAnalysis = .inBed
            
            var midDay = startDate.dayBefore.startOfDay.addHours(18).addingTimeInterval(-Double(TimeZone.current.secondsFromGMT(for: Date())))
            var interval = NSDateInterval(start: midDay, duration: 86400)
            var map: [Date: Double] = [:]
            var sum: Double = 0
            
            for sample in sleepSamples {
                while !(interval.contains(sample.endDate.localTime)) && interval.endDate < endDate {
                    midDay = midDay.addDays(1)
                    interval = NSDateInterval(start: midDay, duration: 86400)
                    let relevantSamples = sleepSamples.filter({interval.contains($0.endDate.localTime)})
                    let sleepValues = relevantSamples.map({HKCategoryValueSleepAnalysis(rawValue: $0.value)})
                    if #available(iOS 16.0, *) {
                        if sleepValues.contains(.asleepCore) || sleepValues.contains(.asleepREM) || sleepValues.contains(.asleepDeep) || sleepValues.contains(.asleepUnspecified) || sleepValues.contains(.awake) {
                            typeOfSleep = .asleep
                        } else {
                            typeOfSleep = .inBed
                        }
                    } else {
                        if sleepValues.contains(.asleep) {
                            typeOfSleep = .asleep
                        } else {
                            typeOfSleep = .inBed
                        }
                    }
                }
                
                if let sleepValue = HKCategoryValueSleepAnalysis(rawValue: sample.value) {
                    if typeOfSleep == .inBed, sleepValue != .inBed {
                        continue
                    } else if typeOfSleep == .asleep, (sleepValue == .inBed || sleepValue == .awake) {
                        continue
                    }
                }
                
                let timeSum = sample.endDate.timeIntervalSince(sample.startDate)
                map[interval.endDate, default: 0] += timeSum
                sum += timeSum
            }
            
            let sortedDates = Array(map.sorted(by: { $0.0 < $1.0 }))
            let average = sum / Double(map.count)
                                    
            if let last = sortedDates.last?.key, let val = map[last] {
                var metric = HealthMetric(type: .sleep, total: val, date: last, unitName: "hrs", rank: HealthMetricType.sleep.rank)
                metric.average = average
                _self.delegate?.insertMetric(_self, metric, HealthMetricCategory.general)
            }

            print("finish SleepOperation")
            self?.finish()
        }
    }
}

enum PlotSleepAnalysis {
    case inBed
    case asleep
    
    var hkValue: HKCategoryValueSleepAnalysis {
        switch self {
        case .inBed:
            return .inBed
        case .asleep:
            return .asleep
        }
    }
}
