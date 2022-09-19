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
    var nutrition = [String: [HKQuantitySample]]()
    var workouts = [String: [HKWorkout]]()
    var mindfulnesses = [HKCategorySample]()
    
    func getSamples(for healthMetric: HealthMetric, segmentType: TimeSegmentType, completion: @escaping ([Statistic]?, [HKSample]?, Error?) -> Swift.Void) {
        getStatisticalSamples(for: healthMetric, segmentType: segmentType, completion: completion)
    }
    
    private func getStatisticalSamples(for healthMetric: HealthMetric, segmentType: TimeSegmentType, completion: @escaping ([Statistic]?, [HKSample]?, Error?) -> Void) {
        let healthMetricType = healthMetric.type
        var interval = DateComponents()
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
        else if case .flightsClimbed = healthMetricType {
            guard let type = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.flightsClimbed) else {
                print("*** Unable to create a flight climbed count type ***")
                completion(nil, nil, nil)
                return
            }
            
            statisticsOptions = .cumulativeSum
            quantityType = type
        }
        else if case .weight = healthMetricType {
            guard let type = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass) else {
                print("*** Unable to create a bodyMass count type ***")
                completion(nil, nil, nil)
                return
            }
            
            unit = HKUnit.pound()
            quantityType = type
        }
        else if case .heartRate = healthMetricType {
            guard let type = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
                print("*** Unable to create a heartRate count type ***")
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
        else if case .activeEnergy = healthMetricType {
            guard let type = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned), let healthMetricUnit = healthMetric.unit else {
                print("*** Unable to create a activeEnergy count type ***")
                completion(nil, nil, nil)
                return
            }
            
            statisticsOptions = .cumulativeSum
            unit = healthMetricUnit
            quantityType = type
        }
        
        //https://developer.apple.com/documentation/healthkit/hkstatisticscollectionquery/1615241-anchordate?language=objc
        // The date used to anchor the collection’s time intervals.
        // Use the anchor date to set the start time for your time intervals. For example, if you are using a day interval, you might create a date object with a time of 2:00 a.m. This value sets the start of each day for all of your time intervals.
        // Use start of the day in local time
        let timezone = TimeZone.current
        let seconds = TimeInterval(timezone.secondsFromGMT(for: Date()))
        let anchorDate = Date().localTime.startOfDay.addingTimeInterval(-seconds)
        var startDate = anchorDate
        let endDate = anchorDate.advanced(by: 86399)
                        
        if segmentType == .day {
            interval.hour = 1
        }
        else if segmentType == .week {
            interval.day = 1
            startDate = anchorDate.weekBefore
        }
        else if segmentType == .month {
            interval.day = 1
            startDate = anchorDate.monthBefore
        }
        else if segmentType == .year {
            if case .steps = healthMetricType {
                interval.day = 1
            } else if case .flightsClimbed = healthMetricType {
                interval.day = 1
            } else if case .activeEnergy = healthMetricType {
                interval.day = 1
            } else {
                interval.month = 1
            }
            startDate = anchorDate.lastYear
        }
        
        if case .sleep = healthMetricType {
            startDate = startDate.dayBefore.startOfDay.advanced(by: 86400)
        }
        
        if HealthKitService.authorized {
            if case .workout = healthMetricType, let hkWorkout = healthMetric.hkSample as? HKWorkout {
                let workoutActivityType = hkWorkout.workoutActivityType
                HealthKitService.getWorkouts(forWorkoutActivityType: workoutActivityType, startDate: startDate, endDate: endDate) { [weak self] workouts, error  in
                    var stats: [Statistic]?
                    if segmentType == .day {
                        stats = self?.perpareCustomStatsForHourlyWorkouts(from: workouts)
                    } else {
                        stats = self?.perpareCustomStatsForDailyWorkouts(from: workouts, segmentType: segmentType)
                    }
                    completion(stats, workouts, nil)
                }
            }
            else if case .workoutMinutes = healthMetricType {
                HealthKitService.getAllWorkouts(startDate: startDate, endDate: endDate) { [weak self] workouts, errorList  in
                    var stats: [Statistic]?
                    if segmentType == .day {
                        stats = self?.perpareCustomStatsForHourlyWorkoutMinutes(from: workouts)
                    } else {
                        stats = self?.perpareCustomStatsForDailyWorkoutMinutes(from: workouts, segmentType: segmentType)
                    }
                    completion(stats, workouts, nil)
                }
            }
            else if case .sleep = healthMetricType {
                HealthKitService.getAllCategoryTypeSamples(forIdentifier:.sleepAnalysis, startDate: startDate, endDate: endDate) { [weak self ] (samples, error) in
                    self?.perpareCustomStatsForSleepSamples(from: samples, startDate: startDate, endDate: endDate, segmentType: segmentType, type: healthMetricType) { stats, samples in
                        completion(stats, samples, nil)
                    }
                }
            }
            else if case .mindfulness = healthMetricType {
                HealthKitService.getAllCategoryTypeSamples(forIdentifier:.mindfulSession, startDate: startDate, endDate: endDate) { [weak self ] (samples, error) in
                    let stats = self?.perpareCustomStatsForCategorySamples(from: samples, startDate: startDate, endDate: endDate, segmentType: segmentType, type: healthMetricType)
                    completion(stats, samples, nil)
                }
            }
            else {
                guard let quantityTypeValue = quantityType else {
                    completion(nil, nil, nil)
                    return
                }
                
                HealthKitService.getIntervalBasedSamples(for: quantityTypeValue, statisticsOptions: statisticsOptions, startDate: startDate, endDate: endDate, anchorDate: anchorDate, interval: interval) { [weak self] (results, error) in
                    if case .steps = healthMetricType {
                        HealthKitService.getAllTheSamples(for: quantityTypeValue, startDate: startDate, endDate: endDate) { (samples, error) in
                            if segmentType == .year {
                                self?.perpareCustomStatsForDailyAverageForAnnualMetrics(from: samples, quantityType: quantityTypeValue, hkStatistics: results, unit: unit, completion: { stats, samples in
                                    completion(stats, samples, nil)
                                })
                                
                            } else {
                                self?.perpareCustomStats(from: samples, quantityType: quantityTypeValue,hkStatistics: results, unit: unit, statisticsOptions: statisticsOptions, completion: { stats, samples in
                                    completion(stats, samples, nil)
                                })
                            }
                        }
                    }
                    else if case .flightsClimbed = healthMetricType {
                        HealthKitService.getAllTheSamples(for: quantityTypeValue, startDate: startDate, endDate: endDate) { (samples, error) in
                            if segmentType == .year {
                                self?.perpareCustomStatsForDailyAverageForAnnualMetrics(from: samples, quantityType: quantityTypeValue, hkStatistics: results, unit: unit, completion: { stats, samples in
                                    completion(stats, samples, nil)
                                })
                                
                            } else {
                                self?.perpareCustomStats(from: samples, quantityType: quantityTypeValue,hkStatistics: results, unit: unit, statisticsOptions: statisticsOptions, completion: { stats, samples in
                                    completion(stats, samples, nil)
                                })
                            }
                        }
                    }
                    else if case .activeEnergy = healthMetricType {
                        HealthKitService.getAllTheSamples(for: quantityTypeValue, startDate: startDate, endDate: endDate) { (samples, error) in
                            if segmentType == .year {
                                self?.perpareCustomStatsForDailyAverageForAnnualMetrics(from: samples, quantityType: quantityTypeValue, hkStatistics: results, unit: unit, completion: { stats, samples in
                                    completion(stats, samples, nil)
                                })
                                
                            } else {
                                self?.perpareCustomStats(from: samples, quantityType: quantityTypeValue,hkStatistics: results, unit: unit, statisticsOptions: statisticsOptions, completion: { stats, samples in
                                    completion(stats, samples, nil)
                                })
                            }
                        }
                    }
                    else {
                        HealthKitService.getAllTheSamples(for: quantityTypeValue, startDate: startDate, endDate: endDate) { (samples, error) in
                            self?.perpareCustomStats(from: samples, quantityType: quantityTypeValue,hkStatistics: results, unit: unit, statisticsOptions: statisticsOptions, completion: { stats, samples in
                                completion(stats, samples, nil)
                            })
                        }
                    }
                }
            }
        } else {
            if case .workout = healthMetricType, let hkWorkout = healthMetric.hkSample as? HKWorkout {
                let workoutActivityType = hkWorkout.workoutActivityType
                grabWorkouts(forWorkoutActivityType: workoutActivityType.name, startDate: startDate, endDate: endDate) { [weak self] (workouts) in
                    var stats: [Statistic]?
                    if segmentType == .day {
                        stats = self?.perpareCustomStatsForHourlyWorkouts(from: workouts)
                    } else {
                        stats = self?.perpareCustomStatsForDailyWorkouts(from: workouts, segmentType: segmentType)
                    }
                    completion(stats, workouts, nil)
                }
            } else if case .mindfulness = healthMetricType {
                grabMindfulness(startDate: startDate, endDate: endDate) { [weak self] (samples) in
                    let stats = self?.perpareCustomStatsForCategorySamples(from: samples, startDate: startDate, endDate: endDate, segmentType: segmentType, type: healthMetricType)
                    completion(stats, samples, nil)
                }
            } else if case HealthMetricType.nutrition(let value) = healthMetric.type {
                grabNutrition(forNutritionType: value, startDate: startDate, endDate: endDate) { [weak self] (samples) in
                    let stats = self?.perpareCustomStatsForQuantitySamples(from: samples, startDate: startDate, endDate: endDate, segmentType: segmentType, type: healthMetricType)
                    completion(stats, samples, nil)
                }
            }
        }
    }
    
    private func grabNutrition(forNutritionType: String, startDate: Date, endDate: Date, completion: @escaping ([HKQuantitySample]?) -> Void) {
        var list = [HKQuantitySample]()
        if let samples = nutrition[forNutritionType] {
            for sample in samples {
                if sample.startDate < startDate || endDate < sample.startDate {
                    continue
                }
                list.append(sample)
            }
        }
        completion(list)
    }
    
    private func grabWorkouts(forWorkoutActivityType: String, startDate: Date, endDate: Date, completion: @escaping ([HKWorkout]?) -> Void) {
        var list = [HKWorkout]()
        if let samples = workouts[forWorkoutActivityType] {
            for sample in samples {
                if sample.startDate < startDate || endDate < sample.startDate {
                    continue
                }
                list.append(sample)
            }
        }
        completion(list)
    }
    
    private func grabMindfulness(startDate: Date, endDate: Date, completion: @escaping ([HKCategorySample]?) -> Void) {
        var list = [HKCategorySample]()
        for sample in mindfulnesses {
            if sample.startDate < startDate || endDate < sample.startDate {
                continue
            }
            list.append(sample)
        }
        completion(list)
    }
    
    private func perpareCustomStatsForQuantitySamples(from samples: [HKQuantitySample]?, startDate: Date, endDate: Date, segmentType: TimeSegmentType, type: HealthMetricType) -> [Statistic]? {
        var customStats: [Statistic] = []
        
        guard let samples = samples else {
            return customStats
        }
        
        if segmentType == .day {
            for sample in samples {
                var double: Double = 0
                if sample.quantityType.is(compatibleWith: .gram()) {
                    double = sample.quantity.doubleValue(for: .gram())
                } else if sample.quantityType.is(compatibleWith: .jouleUnit(with: .kilo)) {
                    double = sample.quantity.doubleValue(for: .jouleUnit(with: .kilo))
                }
                let statistic = Statistic(date: sample.endDate, value: double)
                customStats.append(statistic)
            }
        }
        else {
            var startDay = startDate.startOfDay
            var interval = NSDateInterval(start: startDay, duration: 86400)
            var map: [Date: Double] = [:]
            var sum: Double = 0
            for sample in samples {
                while !(interval.contains(sample.endDate)) && interval.endDate < endDate {
                    startDay = startDay.advanced(by: 86400)
                    interval = NSDateInterval(start: startDay, duration: 86400)
                }
                
                var double: Double = 0
                if sample.quantityType.is(compatibleWith: .gram()) {
                    double = sample.quantity.doubleValue(for: .gram())
                } else if sample.quantityType.is(compatibleWith: .jouleUnit(with: .kilo)) {
                    double = sample.quantity.doubleValue(for: .jouleUnit(with: .kilo))
                }

                map[startDay, default: 0] += double
                sum += double
            }
            
            let sortedDates = Array(map.sorted(by: { $0.0 < $1.0 }))
            
            for item in sortedDates {
                let stat = Statistic(date: item.key, value: item.value)
                customStats.append(stat)
            }
        }
        
        return customStats
    }
    
    private func perpareCustomStatsForCategorySamples(from samples: [HKCategorySample]?, startDate: Date, endDate: Date, segmentType: TimeSegmentType, type: HealthMetricType) -> [Statistic]? {
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
            var startDay = startDate.startOfDay
            var interval = NSDateInterval(start: startDay, duration: 86400)
            var map: [Date: Double] = [:]
            var sum: Double = 0
            for sample in samples {
                while !(interval.contains(sample.endDate.localTime)) && interval.endDate < endDate {
                    startDay = startDay.advanced(by: 86400)
                    interval = NSDateInterval(start: startDay, duration: 86400)
                }
                
                let timeSum = sample.endDate.timeIntervalSince(sample.startDate)
                map[startDay, default: 0] += timeSum
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
    
    private func perpareCustomStatsForSleepSamples(from samples: [HKCategorySample]?, startDate: Date, endDate: Date, segmentType: TimeSegmentType, type: HealthMetricType, completion: @escaping ([Statistic]?, [HKCategorySample]?) -> Void) {
        var customStats: [Statistic] = []
        var customSamples: [HKCategorySample] = []
        
        guard let samples = samples else {
            completion(customStats, customSamples)
            return
        }
        
        var typeOfSleep: HKCategoryValueSleepAnalysis = .inBed
        
        if segmentType == .day {
            let sleepValues = samples.map({HKCategoryValueSleepAnalysis(rawValue: $0.value)})
            if sleepValues.contains(.asleep) {
                typeOfSleep = .asleep
            } else {
                typeOfSleep = .inBed
            }
            for sample in samples {
                if let sleepValue = HKCategoryValueSleepAnalysis(rawValue: sample.value), sleepValue != typeOfSleep {
                    continue
                }
                let timeSum = sample.endDate.timeIntervalSince(sample.startDate)
                let hours = TimeInterval(timeSum).totalHours
                let stat = Statistic(date: sample.startDate, value: hours)
                customStats.append(stat)

            }
            
            let customSample = HKCategorySample(type: samples.first!.categoryType, value: typeOfSleep.rawValue, start: samples.first!.startDate, end: samples.last!.endDate)
            customSamples.append(customSample)
        }
        else {
            var midDay = startDate.dayBefore.startOfDay.advanced(by: 43200)
            var interval = NSDateInterval(start: midDay, duration: 86400)
            var map: [Date: Double] = [:]
            var sum: Double = 0
            
            let relevantSamples = samples.filter({interval.contains($0.endDate.localTime)})
            let sleepValues = relevantSamples.map({HKCategoryValueSleepAnalysis(rawValue: $0.value)})
            if sleepValues.contains(.asleep) {
                typeOfSleep = .asleep
            } else {
                typeOfSleep = .inBed
            }
            for sample in samples {
                while !(interval.contains(sample.endDate.localTime)) && interval.endDate < endDate {
                    midDay = midDay.advanced(by: 86400)
                    interval = NSDateInterval(start: midDay, duration: 86400)
                    let relevantSamples = samples.filter({interval.contains($0.endDate.localTime)})
                    let sleepValues = relevantSamples.map({HKCategoryValueSleepAnalysis(rawValue: $0.value)})
                    if sleepValues.contains(.asleep) {
                        typeOfSleep = .asleep
                    } else {
                        typeOfSleep = .inBed
                    }
                }
                if let sleepValue = HKCategoryValueSleepAnalysis(rawValue: sample.value), sleepValue != typeOfSleep {
                    continue
                }
                
                let timeSum = sample.endDate.timeIntervalSince(sample.startDate)
                map[interval.endDate, default: 0] += timeSum
                sum += timeSum
            }
            
            let sortedDates = Array(map.sorted(by: { $0.0 < $1.0 }))
            
            if segmentType == .year {
                var monthMap: [String: [Statistic]] = [:]
                
                for item in sortedDates {
                    let hours = TimeInterval(item.value).totalHours
                    let statistic = Statistic(date: item.key, value: hours)
                    let key = item.key.getShortMonthAndYear()
                    var group = monthMap[key, default: []]
                    group.append(statistic)
                    monthMap[key] = group
                    
                    let customSample = HKCategorySample(type: relevantSamples.first!.categoryType, value: typeOfSleep.rawValue, start: item.key.addingTimeInterval(-item.value), end: item.key)
                    customSamples.append(customSample)

                }
                
                for (_, value) in monthMap {
                    var total: Double = 0
                    var count: Int = 0
                    var firstDate: Date?
                    for item in value {
                        total += item.value
                        count += 1
                        if firstDate == nil {
                            firstDate = item.date
                        }
                    }
                    
                    if let date = firstDate, value.count > 0 {
                        let statistic = Statistic(date: date, value: total/Double(count))
                        customStats.append(statistic)
                    }
                }
                
                customStats.sort(by: {$0.date < $1.date})
                
            } else {
                for item in sortedDates {
                    let hours = TimeInterval(item.value).totalHours
                    let stat = Statistic(date: item.key, value: hours)
                    customStats.append(stat)
                    
                    print(item.key.addingTimeInterval(-item.value))
                    print(hours)
                    print(item.key)
                    
                    let customSample = HKCategorySample(type: relevantSamples.first!.categoryType, value: typeOfSleep.rawValue, start: item.key.addingTimeInterval(-item.value), end: item.key)
                    customSamples.append(customSample)
                }
            }
            
        }
        
        completion(customStats, customSamples)
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
    
    private func perpareCustomStatsForHourlyWorkoutMinutes(from hkWorkouts: [HKWorkout]?) -> [Statistic]? {
        guard let hkWorkouts = hkWorkouts else {
            return nil
        }
        
        var customStats: [Statistic] = []
        for workout in hkWorkouts {
            let duration = workout.endDate.timeIntervalSince(workout.startDate) / 60
            let statistic = Statistic(date: workout.endDate, value: duration)
            customStats.append(statistic)
        }
        
        customStats.sort(by: {$0.date < $1.date})
        return customStats
    }
    
    private func perpareCustomStatsForDailyWorkoutMinutes(from hkWorkouts: [HKWorkout]?, segmentType: TimeSegmentType) -> [Statistic]? {
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
                total += item.endDate.timeIntervalSince(item.startDate) / 60
                if firstDate == nil {
                    firstDate = item.startDate
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
    
    private func perpareCustomStats(from samples: [HKSample]?, quantityType: HKQuantityType, hkStatistics: [HKStatistics]?, unit: HKUnit, statisticsOptions: HKStatisticsOptions, completion: @escaping ([Statistic]?, [HKQuantitySample]?) -> Void) {
        guard let statsCollection = hkStatistics else {
            completion(nil, nil)
            return
        }
        
        var customStats: [Statistic] = []
        var customSamples: [HKQuantitySample] = []
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
                
                let customSample = HKQuantitySample(type: quantityType, quantity: HKQuantity(unit: unit, doubleValue: value), start: statistics.startDate, end: statistics.endDate)
                customSamples.append(customSample)
            }
        }
        
        completion(customStats, customSamples)
    }
    
    private func perpareCustomStatsForDailyAverageForAnnualMetrics(from samples: [HKSample]?, quantityType: HKQuantityType, hkStatistics: [HKStatistics]?, unit: HKUnit, completion: @escaping ([Statistic]?, [HKQuantitySample]?) -> Void) {
        guard let statsCollection = hkStatistics else {
            completion(nil, nil)
            return
        }
        
        var map: [String: [HKStatistics]] = [:]
        for statistics in statsCollection {
            let key: String = statistics.startDate.getShortMonthAndYear()
            var group = map[key, default: []]
            group.append(statistics)
            map[key] = group
        }
        
        var customStats: [Statistic] = []
        var customSamples: [HKQuantitySample] = []
        for (_, value) in map {
            var total: Double = 0
            var count: Int = 0
            var firstDate: Date?
            for item in value {
                if let sumQuantity = item.sumQuantity() {
                    total += sumQuantity.doubleValue(for: unit)
                    count += 1
                    if firstDate == nil {
                        firstDate = item.startDate
                    }
                }
            }
            
            if let date = firstDate, value.count > 0 {
                let statistic = Statistic(date: date, value: total/Double(count))
                customStats.append(statistic)
                
                let customSample = HKQuantitySample(type: quantityType, quantity: HKQuantity(unit: unit, doubleValue: total/Double(count)), start: date, end: date.addingTimeInterval(total/Double(count)))
                customSamples.append(customSample)
            }
        }
        
        customStats.sort(by: {$0.date < $1.date})
        completion(customStats, customSamples)
    }
}
