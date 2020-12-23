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
        if case .steps = healthMetricType {
            guard let type = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount) else {
                print("*** Unable to create a step count type ***")
                completion(nil, nil, nil)
                return
            }
            
            statisticsOptions = .cumulativeSum
            quantityType = type
        }
        else if case .weight = healthMetricType {
            guard let type = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass) else {
                print("*** Unable to create a step count type ***")
                completion(nil, nil, nil)
                return
            }
            
            unit = HKUnit.pound()
            quantityType = type
        }
        else if case .heartRate = healthMetricType {
            guard let type = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
                print("*** Unable to create a step count type ***")
                completion(nil, nil, nil)
                return
            }
            
            unit = HKUnit.count().unitDivided(by: HKUnit.minute())
            quantityType = type
        }
        else if case .nutrition(_) = healthMetricType {
            guard let quantityTypeIdentifier = healthMetric.quantityTypeIdentifier, let type = HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier), let healthMetricUnit = healthMetric.unit else {
                print("*** Unable to create a nutrition type ***")
                completion(nil, nil, nil)
                return
            }
            
            statisticsOptions = .cumulativeSum
            unit = healthMetricUnit
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
            if case .steps = healthMetricType {
                interval.day = 1
            } else {
                interval.month = 1
            }
            anchorComponents.year! -= 1
            anchorComponents.hour = 0
            endDate = Date()
            startDate = endDate.lastYear
        }
                
        if case .workout = healthMetricType, let hkWorkout = healthMetric.hkSample as? HKWorkout {
            let workoutActivityType = hkWorkout.workoutActivityType
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
        else if case .sleep = healthMetricType {
            HealthKitService.getAllCategoryTypeSamples(forIdentifier:.sleepAnalysis, startDate: startDate, endDate: endDate) { [weak self ] (samples, error) in
                let stats = self?.perpareCustomStatsForSleep(from: samples, startDate: startDate, endDate: endDate, segmentType: segmentType)
                completion(stats, samples, nil)
            }
        }
        else {
            guard let quantityTypeValue = quantityType else {
                completion(nil, nil, nil)
                return
            }
            
            HealthKitService.getIntervalBasedSamples(for: quantityTypeValue, statisticsOptions: statisticsOptions, startDate: startDate, endDate: endDate, anchorDate: anchorDate, interval: interval) { [weak self] (results, error) in
                var stats: [Statistic]?
                if case .steps = healthMetricType {
                    if segmentType == .year {
                        stats = self?.perpareCustomStatsForDailyAverageForAnnualSteps(from: results)
                    } else {
                        stats = self?.perpareCustomStats(from: results, unit: unit, statisticsOptions: statisticsOptions)
                    }
                }
                else {
                    stats = self?.perpareCustomStats(from: results, unit: unit, statisticsOptions: statisticsOptions)
                }
                
                HealthKitService.getAllTheSamples(for: quantityTypeValue, startDate: startDate, endDate: endDate) { (samples, error) in
                    completion(stats, samples, nil)
                }
            }
        }
    }
    
    private func perpareCustomStatsForSleep(from samples: [HKCategorySample]?, startDate: Date, endDate: Date, segmentType: TimeSegmentType) -> [Statistic]? {
        var customStats: [Statistic] = []
        
        guard let samples = samples else {
            return customStats
        }
        
        if segmentType == .day {
            for sample in samples {
                let timeSum = sample.endDate.timeIntervalSince(sample.startDate)
                let hours = TimeInterval(timeSum).totalHours
                let stat = Statistic(date: sample.startDate, value: hours)
                customStats.append(stat)
            }
        }
        else {
            // 12 hours = 43200 seconds
            var midDay = startDate.dayBefore.startOfDay.advanced(by: 43200)
            var interval = NSDateInterval(start: midDay, duration: 86400)
            var map: [Date: Double] = [:]
            var sum: Double = 0
            for sample in samples {
                while !(interval.contains(sample.endDate)) && interval.endDate < endDate {
                    midDay = midDay.advanced(by: 86400)
                    interval = NSDateInterval(start: midDay, duration: 86400)
                }
                
                let timeSum = sample.endDate.timeIntervalSince(sample.startDate)
                map[midDay, default: 0] += timeSum
                sum += timeSum
            }
            
            let sortedDates = Array(map.sorted(by: { $0.0 < $1.0 }))
            
            for item in sortedDates {
                let hours = TimeInterval(item.value).totalHours
                let stat = Statistic(date: item.key, value: hours)
                customStats.append(stat)
            }
        }
        
        return customStats
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
