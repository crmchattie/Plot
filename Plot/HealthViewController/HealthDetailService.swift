//
//  HealthDetailService.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-11-01.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import HealthKit

protocol HealthDetailServiceInterface {
    func getSamples(for healthMetricType: HealthMetricType, segmentType: TimeSegmentType, completion: @escaping ([Statistic]?, Error?) -> Swift.Void)
}

class HealthDetailService: HealthDetailServiceInterface {
    func getSamples(for healthMetricType: HealthMetricType, segmentType: TimeSegmentType, completion: @escaping ([Statistic]?, Error?) -> Swift.Void) {
        
        getStatisticalSamples(for: healthMetricType, segmentType: segmentType, completion: completion)
    }
    
    private func getStatisticalSamples(for healthMetricType: HealthMetricType, segmentType: TimeSegmentType, completion: @escaping ([Statistic]?, Error?) -> Void) {
        if healthMetricType == .steps {
            
            if segmentType == .day {
                HealthKitService.getHourlyStepsForToday(statisticsOptions: .cumulativeSum) { (results, error) in
                    let stats = self.perpareCustomStats(from: results)
                    completion(stats, nil)
                }
            }
            else if segmentType == .week {
                HealthKitService.getDailyStepsForCurrentWeek(statisticsOptions: .cumulativeSum) { (results, error) in
                    let stats = self.perpareCustomStats(from: results)
                    completion(stats, nil)
                }
            }
            else if segmentType == .month {
                HealthKitService.getDailyStepsForCurrentMonth(statisticsOptions: .cumulativeSum) { (results, error) in
                    let stats = self.perpareCustomStats(from: results)
                    completion(stats, nil)
                }
            }
            else if segmentType == .year {
                HealthKitService.getMonthlyStepsForCurrentYear(statisticsOptions: .cumulativeSum) { (results, error) in
                    let stats = self.perpareCustomStatsForDailyAverageForAnnualSteps(from: results)
                    completion(stats, nil)
                }
            }
        }
    }
    
    private func perpareCustomStats(from hkStatistics: [HKStatistics]?) -> [Statistic]? {
        guard let statsCollection = hkStatistics else {
            return nil
        }
        
        var customStats: [Statistic] = []
        for statistics in statsCollection {
            var value: Double = 0
            if let sumQuantity = statistics.sumQuantity() {
                value = sumQuantity.doubleValue(for: HKUnit.count())
            }
            
            let date = statistics.startDate
            let statistic = Statistic(date: date, value: value)
            customStats.append(statistic)
        }
        
        return customStats
    }
    
    private func perpareCustomStatsForDailyAverageForAnnualSteps(from hkStatistics: [HKStatistics]?) -> [Statistic]? {
        guard let statsCollection = hkStatistics else {
            return nil
        }
        
        var map: [String: [HKStatistics]] = [:]
        for statistics in statsCollection {
            let key: String = statistics.startDate.getShortMonthAndYear()
            var group = map[key, default: []]
            group.append(statistics)
            map[key] = group
        }
        
        var customStats: [Statistic] = []
        for (_, value) in map {
            var total: Double = 0
            var firstDate: Date?
            for item in value {
                if let sumQuantity = item.sumQuantity() {
                    total += sumQuantity.doubleValue(for: HKUnit.count())
                    if firstDate == nil {
                        firstDate = item.startDate
                    }
                }
            }
            
            if let date = firstDate, value.count > 0 {
                let statistic = Statistic(date: date, value: total/Double(value.count))
                customStats.append(statistic)
            }
        }
        
        customStats.sort(by: {$0.date < $1.date})
        return customStats
    }
}

struct Statistic {
    let date: Date
    let value: Double
}
