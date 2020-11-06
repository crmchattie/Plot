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
    func getSamples(for healthMetric: HealthMetric, segmentType: TimeSegmentType, completion: @escaping ([Statistic]?, [HKSample]?, Error?) -> Swift.Void)
}

class HealthDetailService: HealthDetailServiceInterface {
    func getSamples(for healthMetric: HealthMetric, segmentType: TimeSegmentType, completion: @escaping ([Statistic]?, [HKSample]?, Error?) -> Swift.Void) {
        
        getStatisticalSamples(for: healthMetric, segmentType: segmentType, completion: completion)
    }
    
    private func getStatisticalSamples(for healthMetric: HealthMetric, segmentType: TimeSegmentType, completion: @escaping ([Statistic]?, [HKSample]?, Error?) -> Void) {
        let healthMetricType = healthMetric.type
        let calendar = NSCalendar.current
        var interval = DateComponents()
        var anchorComponents = calendar.dateComponents([.day, .month, .year, .weekday], from: Date())
        var quantityType: HKQuantityType?
        var statisticsOptions: HKStatisticsOptions = .discreteAverage
        
        var unit: HKUnit = HKUnit.count()
        if healthMetricType == .steps {
            guard let type = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount) else {
                print("*** Unable to create a step count type ***")
                completion(nil, nil, nil)
                return
            }
            
            statisticsOptions = .cumulativeSum
            quantityType = type
        }
        else if healthMetricType == .weight {
            guard let type = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass) else {
                print("*** Unable to create a step count type ***")
                completion(nil, nil, nil)
                return
            }
            
            unit = HKUnit.pound()
            quantityType = type
        }
        else if healthMetricType == .heartRate {
            guard let type = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
                print("*** Unable to create a step count type ***")
                completion(nil, nil, nil)
                return
            }
            
            unit = HKUnit.count().unitDivided(by: HKUnit.minute())
            quantityType = type
        }
        
        var anchorDate = Date()
        var startDate = anchorDate
        var endDate = anchorDate
        
        if segmentType == .day {
            interval.hour = 1
            anchorComponents.hour = 0
            anchorDate = calendar.date(from: anchorComponents)!
            endDate = Date()
            startDate = calendar.startOfDay(for: endDate)
        }
        else if segmentType == .week {
            interval.day = 1
            anchorComponents.day! -= 7
            anchorComponents.hour = 0
            endDate = Date()
            startDate = endDate.weekBefore
        }
        else if segmentType == .month {
            interval.day = 1
            anchorComponents.month! -= 1
            anchorComponents.hour = 0
            endDate = Date()
            startDate = endDate.monthBefore
        }
        else if segmentType == .year {
            if healthMetricType == .steps {
                interval.day = 1
            } else {
                interval.month = 1
            }
            anchorComponents.year! -= 1
            anchorComponents.hour = 0
            endDate = Date()
            startDate = endDate.lastYear
        }
                
        if healthMetricType == .workout, let workoutActivityType = healthMetric.hkWorkout?.workoutActivityType {
            HealthKitService.getAllWorkouts(forWorkoutActivityType: workoutActivityType, startDate: startDate, endDate: endDate) { [weak self] workouts, error  in
                var stats: [Statistic]?
                if segmentType == .day {
                    stats = self?.perpareCustomStatsForHourlyWorkouts(from: workouts)
                } else {
                    stats = self?.perpareCustomStatsForDailyWorkouts(from: workouts, segmentType: segmentType)
                }
                
                let sortedWorkouts = workouts?.sorted(by: {$0.startDate > $1.startDate})
                completion(stats, sortedWorkouts, nil)
            }
        }
        else {
            guard let quantityTypeValue = quantityType else {
                completion(nil, nil, nil)
                return
            }
            
            HealthKitService.getIntervalBasedSamples(for: quantityTypeValue, statisticsOptions: statisticsOptions, startDate: startDate, endDate: endDate, anchorDate: anchorDate, interval: interval) { [weak self] (results, error) in
                var stats: [Statistic]?
                if healthMetricType == .steps {
                    if segmentType == .year {
                        stats = self?.perpareCustomStatsForDailyAverageForAnnualSteps(from: results)
                    } else {
                        stats = self?.perpareCustomStats(from: results, unit: unit, statisticsOptions: statisticsOptions)
                    }
                }
                else {
                    stats = self?.perpareCustomStats(from: results, unit: unit, statisticsOptions: statisticsOptions)
                }
                
                completion(stats, nil, nil)
            }
        }
    }
    
    private func perpareCustomStatsForHourlyWorkouts(from hkWorkouts: [HKWorkout]?) -> [Statistic]? {
        guard let hkWorkouts = hkWorkouts else {
            return nil
        }
        
        var customStats: [Statistic] = []
        for workout in hkWorkouts {
            if let totalEnergyBurned = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) {
                let statistic = Statistic(date: workout.endDate, value: totalEnergyBurned)
                customStats.append(statistic)
            }
        }
        
        customStats.sort(by: {$0.date < $1.date})
        return customStats
    }
    
    private func perpareCustomStatsForDailyWorkouts(from hkWorkouts: [HKWorkout]?, segmentType: TimeSegmentType) -> [Statistic]? {
        guard let hkWorkouts = hkWorkouts else {
            return nil
        }
        
        var map: [String: [HKWorkout]] = [:]
        for workout in hkWorkouts {
            let key: String
            if segmentType == .year {
                key = workout.startDate.getShortMonthAndYear()
            } else {
                key = workout.startDate.getShortDayMonthAndYear()
            }
            
            var group = map[key, default: []]
            group.append(workout)
            map[key] = group
        }
        
        var customStats: [Statistic] = []
        for (_, value) in map {
            var total: Double = 0
            var firstDate: Date?
            for item in value {
                if let sumQuantity = item.totalEnergyBurned?.doubleValue(for: .kilocalorie()) {
                    total += sumQuantity
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
    
    private func perpareCustomStats(from hkStatistics: [HKStatistics]?, unit: HKUnit, statisticsOptions: HKStatisticsOptions) -> [Statistic]? {
        guard let statsCollection = hkStatistics else {
            return nil
        }
        
        var customStats: [Statistic] = []
        for statistics in statsCollection {
            var value: Double?
            if statisticsOptions == .cumulativeSum {
                if let sumQuantity = statistics.sumQuantity() {
                    value = sumQuantity.doubleValue(for: unit)
                }
            }
            else if statisticsOptions == .discreteAverage {
                if let sumQuantity = statistics.averageQuantity() {
                    value = sumQuantity.doubleValue(for: unit)
                }
            }
            
            if let value = value {
                let date = statistics.startDate
                let statistic = Statistic(date: date, value: value)
                customStats.append(statistic)
            }
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
