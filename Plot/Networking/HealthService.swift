//
//  HealthService.swift
//  Plot
//
//  Created by Cory McHattie on 12/24/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import HealthKit
import Firebase

extension NSNotification.Name {
    static let healthUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".healthUpdated")
    static let workoutsUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".workoutsUpdated")
    static let mindfulnessUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".mindfulnessUpdated")
    static let moodsUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".moodsUpdated")
    static let healthKitUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".healthKitUpdated")
    static let hasLoadedHealth = NSNotification.Name(Bundle.main.bundleIdentifier! + ".hasLoadedHealth")
    static let healthDataIsSetup = NSNotification.Name(Bundle.main.bundleIdentifier! + ".healthDataIsSetup")
}

class HealthService {
    let healhKitManager = HealthKitManager()
    let workoutFetcher = WorkoutFetcher()
    let mindfulnessFetcher = MindfulnessFetcher()
    let moodFetcher = MoodFetcher()
    
    fileprivate var userHealthDatabaseRef: DatabaseReference!
    fileprivate var currentUserHealthAddHandle = DatabaseHandle()
    var healthAdded: (()->())?

    var healthMetricSections: [HealthMetricCategory] = [] {
        didSet {
            if oldValue != healthMetricSections {
                healthMetricSections.sort(by: { (v1, v2) -> Bool in
                    return v1.rank < v2.rank
                })
                NotificationCenter.default.post(name: .healthUpdated, object: nil)
            }
        }
    }
    
    var healthMetrics: [HealthMetricCategory: [HealthMetric]] = [:] {
        didSet {
            if oldValue != healthMetrics {
                NotificationCenter.default.post(name: .healthUpdated, object: nil)
            }
        }
    }
    
    var workouts: [Workout] = [] {
        didSet {
            if oldValue != workouts {
                workouts.sort(by: {
                    $0.startDateTime ?? Date.distantPast > $1.startDateTime ?? Date.distantPast
                })
                NotificationCenter.default.post(name: .workoutsUpdated, object: nil)
            }
        }
    }
    
    var mindfulnesses: [Mindfulness] = [] {
        didSet {
            if oldValue != mindfulnesses {
                mindfulnesses.sort(by: {
                    $0.startDateTime ?? Date.distantPast > $1.startDateTime ?? Date.distantPast
                })
                NotificationCenter.default.post(name: .mindfulnessUpdated, object: nil)
            }
        }
    }
    
    var moods: [Mood] = [] {
        didSet {
            if oldValue != moods {
                print("oldValue != moods")
                moods.sort(by: {
                    $0.moodDate ?? Date.distantPast > $1.moodDate ?? Date.distantPast
                })
                NotificationCenter.default.post(name: .moodsUpdated, object: nil)
            }
        }
    }
    
    var hasLoadedHealth = false {
        didSet {
            NotificationCenter.default.post(name: .hasLoadedHealth, object: nil)
        }
    }
    
    var dataIsSetup = false {
        didSet {
            if dataIsSetup {
                NotificationCenter.default.post(name: .healthDataIsSetup, object: nil)
            }
        }
    }
    
    var authorized: Bool = false
    
    var isRunning: Bool = true
        
    func grabHealth(_ completion: @escaping () -> Void) {
        healhKitManager.checkHealthAuthorizationStatus {}
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        HealthKitService.authorizeHealthKit { [weak self] _ in
            self?.healhKitManager.loadHealthKitActivities { metrics, successfullyGrabbedHealthMetrics in
                HealthKitService.authorized = true
                self?.authorized = successfullyGrabbedHealthMetrics
                self?.healthMetricSections = Array(metrics.keys)
                self?.healthMetrics = metrics
                dispatchGroup.leave()
            }
        }
        
        if self.isRunning {
            dispatchGroup.enter()
            self.grabFirebase {
                self.isRunning = false
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion()
            self.addObservers()
            self.dataIsSetup = true
            self.hasLoadedHealth = true
        }
    }
    
    func grabFirebase(_ completion: @escaping () -> Void) {
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        self.observeWorkoutsForCurrentUser {
            dispatchGroup.leave()
        }
        dispatchGroup.enter()
        self.observeMindfulnesssForCurrentUser {
            dispatchGroup.leave()
        }
        dispatchGroup.enter()
        self.observeMoodForCurrentUser {
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            completion()
        }
    }
    
    func setupFirebase(_ completion: @escaping () -> Void) {
        self.observeWorkoutsForCurrentUser {}
        self.observeMindfulnesssForCurrentUser {}
        self.observeMoodForCurrentUser {}
        self.hasLoadedHealth = true
        completion()
    }
    
    func regrabHealth(_ completion: @escaping () -> Void) {
        hasLoadedHealth = false
        healhKitManager.checkHealthAuthorizationStatus {}
        HealthKitService.authorizeHealthKit { [weak self] askedforAuthorization in
            self?.healhKitManager.loadHealthKitActivities { metrics, successfullyGrabbedHealthMetrics in
                self?.dataIsSetup = true
                self?.authorized = successfullyGrabbedHealthMetrics
                HealthKitService.authorized = true
                self?.healthMetricSections = Array(metrics.keys)
                self?.healthMetrics = metrics
                self?.hasLoadedHealth = true
                completion()
            }
        }
    }
    
    func observeWorkoutsForCurrentUser(_ completion: @escaping () -> Void) {
        workoutFetcher.observeWorkoutForCurrentUser(workoutsInitialAdd: { [weak self] workoutsInitialAdd  in
            if !workoutsInitialAdd.isEmpty {
                if self!.workouts.isEmpty {
                    self?.workouts = workoutsInitialAdd
                    completion()
                }
                for workout in workoutsInitialAdd {
                    if let index = self?.workouts.firstIndex(where: {$0.id == workout.id}) {
                        self?.workouts[index] = workout
                    } else {
                        self?.workouts.append(workout)
                    }
                }
            } else {
                completion()
            }
        }, workoutsAdded: { [weak self] workoutsAdded in
            for workout in workoutsAdded {
                if let index = self?.workouts.firstIndex(where: {$0.id == workout.id}) {
                    self?.workouts[index] = workout
                } else {
                    self?.workouts.append(workout)
                }
            }
        }, workoutsRemoved: { [weak self] workoutsRemoved in
            for workout in workoutsRemoved {
                if let index = self?.workouts.firstIndex(where: {$0.id == workout.id}) {
                    self?.workouts.remove(at: index)
                }
            }
        }, workoutsChanged: { [weak self] workoutsChanged in
            for workout in workoutsChanged {
                if let index = self?.workouts.firstIndex(where: {$0.id == workout.id}) {
                    self?.workouts[index] = workout
                } else {
                    self?.workouts.append(workout)
                }
            }
        })
    }
    
    func observeMindfulnesssForCurrentUser(_ completion: @escaping () -> Void) {
        mindfulnessFetcher.observeMindfulnessForCurrentUser(mindfulnessInitialAdd: { [weak self] mindfulnessInitialAdd in
            if !mindfulnessInitialAdd.isEmpty {
                if self!.mindfulnesses.isEmpty {
                    self?.mindfulnesses = mindfulnessInitialAdd
                    completion()
                }
                for mindfulness in mindfulnessInitialAdd {
                    if let index = self?.mindfulnesses.firstIndex(where: {$0.id == mindfulness.id}) {
                        self?.mindfulnesses[index] = mindfulness
                    } else {
                        self?.mindfulnesses.append(mindfulness)
                    }
                }
            } else {
                completion()
            }
        }, mindfulnessAdded: { [weak self] mindfulnessAdded in
            for mindfulness in mindfulnessAdded {
                if let index = self?.mindfulnesses.firstIndex(where: {$0.id == mindfulness.id}) {
                    self?.mindfulnesses[index] = mindfulness
                } else {
                    self?.mindfulnesses.append(mindfulness)
                }
            }
        }, mindfulnessRemoved: { [weak self] mindfulnessRemoved in
            for mindfulness in mindfulnessRemoved {
                if let index = self?.mindfulnesses.firstIndex(where: {$0.id == mindfulness.id}) {
                    self?.mindfulnesses.remove(at: index)
                }
            }
        }, mindfulnessChanged: { [weak self] mindfulnessChanged in
            for mindfulness in mindfulnessChanged {
                if let index = self?.mindfulnesses.firstIndex(where: {$0.id == mindfulness.id}) {
                    self?.mindfulnesses[index] = mindfulness
                } else {
                    self?.mindfulnesses.append(mindfulness)
                }
            }
        })
    }
    
    func observeMoodForCurrentUser(_ completion: @escaping () -> Void) {
        moodFetcher.observeMoodForCurrentUser(moodInitialAdd: { [weak self] moodInitialAdd in
            if !moodInitialAdd.isEmpty {
                if self!.moods.isEmpty {
                    self?.moods = moodInitialAdd
                    completion()
                }
                for mood in moodInitialAdd {
                    if let index = self?.moods.firstIndex(where: {$0.id == mood.id}) {
                        self?.moods[index] = mood
                    } else {
                        self?.moods.append(mood)
                    }
                }
            } else {
                completion()
            }
        }, moodAdded: { [weak self] moodAdded in
            for mood in moodAdded {
                if let index = self?.moods.firstIndex(where: {$0.id == mood.id}) {
                    self?.moods[index] = mood
                } else {
                    self?.moods.append(mood)
                }
            }
        }, moodRemoved: { [weak self] moodRemoved in
            for mood in moodRemoved {
                if let index = self?.moods.firstIndex(where: {$0.id == mood.id}) {
                    self?.moods.remove(at: index)
                }
            }
        }, moodChanged: { [weak self] moodChanged in
            for mood in moodChanged {
                if let index = self?.moods.firstIndex(where: {$0.id == mood.id}) {
                    self?.moods[index] = mood
                } else {
                    self?.moods.append(mood)
                }
            }
        })
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(healthKitUpdated), name: .healthKitUpdated, object: nil)
    }
    
    @objc func healthKitUpdated() {
        regrabHealth {}
    }
}

//want to delete but not sure what I am doing yet
//                else {
//                    var metrics: [String: [HealthMetric]] = [:]
//                    HealthKitService.authorized = false
//                    let dispatchGroup = DispatchGroup()
//                    dispatchGroup.enter()
//                    self?.mealFetcher.fetchMeals { firebaseMeals in
//                        guard !firebaseMeals.isEmpty else {
//                            dispatchGroup.leave()
//                            return
//                        }
//                        let sortedFirebaseMeals = firebaseMeals.sorted {
//                            $0.startDateTime! < $1.startDateTime!
//                        }
//                        var nutrients = [HKQuantityTypeIdentifier: [Double]]()
//                        var latestNutrients = [HKQuantityTypeIdentifier: Double]()
//                        let recentStatDate = sortedFirebaseMeals.last?.startDateTime!
//                        for firebaseMeal in sortedFirebaseMeals {
//                            if let mealNutrients = HealthKitSampleBuilder.createHKNutritions(from: firebaseMeal) {
//                                for nutrient in mealNutrients {
//                                    var double: Double = 0
//                                    let type = HKQuantityTypeIdentifier(rawValue: nutrient.quantityType.identifier)
//
//                                    self?.nutrition[type.name, default: []].append(nutrient)
//
//                                    if nutrient.quantityType.is(compatibleWith: .gram()) {
//                                        double = nutrient.quantity.doubleValue(for: .gram())
//                                    } else if nutrient.quantityType.is(compatibleWith: .jouleUnit(with: .kilo)) {
//                                        double = nutrient.quantity.doubleValue(for: .jouleUnit(with: .kilo))
//                                    }
//                                    nutrients[type, default: []].append(double)
//                                    if Calendar.current.compare(firebaseMeal.startDateTime!, to: recentStatDate!, toGranularity: .day) == .orderedSame {
//                                        latestNutrients[type, default: 0] += double
//                                    }
//                                }
//                            }
//                        }
//
//                        for (type, list) in nutrients {
//                            if let dailyTotal = latestNutrients[type] {
//                                let average = list.reduce(0, +) / Double(list.count)
//                                if type == .dietaryEnergyConsumed {
//                                    var metric = HealthMetric(type: HealthMetricType.nutrition(type.name), total: dailyTotal, date: recentStatDate!, unitName: "calories", rank: 1)
//                                    metric.unit = .kilocalorie()
//                                    metric.quantityTypeIdentifier = type
//                                    metric.average = average
//                                    metrics[HealthMetricCategory.nutrition.rawValue, default: []].append(metric)
//                                } else if type == .dietaryFatTotal {
//                                    var metric = HealthMetric(type: HealthMetricType.nutrition(type.name), total: dailyTotal, date: recentStatDate!, unitName: "grams", rank: 2)
//                                    metric.unit = .gram()
//                                    metric.quantityTypeIdentifier = type
//                                    metric.average = average
//                                    metrics[HealthMetricCategory.nutrition.rawValue, default: []].append(metric)
//                                } else if type == .dietaryProtein {
//                                    var metric = HealthMetric(type: HealthMetricType.nutrition(type.name), total: dailyTotal, date: recentStatDate!, unitName: "grams", rank: 3)
//                                    metric.unit = .gram()
//                                    metric.quantityTypeIdentifier = type
//                                    metric.average = average
//                                    metrics[HealthMetricCategory.nutrition.rawValue, default: []].append(metric)
//                                } else if type == .dietaryCarbohydrates {
//                                    var metric = HealthMetric(type: HealthMetricType.nutrition(type.name), total: dailyTotal, date: recentStatDate!, unitName: "grams", rank: 4)
//                                    metric.unit = .gram()
//                                    metric.quantityTypeIdentifier = type
//                                    metric.average = average
//                                    metrics[HealthMetricCategory.nutrition.rawValue, default: []].append(metric)
//                                } else if type == .dietarySugar {
//                                    var metric = HealthMetric(type: HealthMetricType.nutrition(type.name), total: dailyTotal, date: recentStatDate!, unitName: "grams", rank: 5)
//                                    metric.unit = .gram()
//                                    metric.quantityTypeIdentifier = type
//                                    metric.average = average
//                                    metrics[HealthMetricCategory.nutrition.rawValue, default: []].append(metric)
//                                }
//                            }
//                        }
//
//                        dispatchGroup.leave()
//                    }
//                    dispatchGroup.enter()
//                    self?.workoutFetcher.fetchWorkouts { firebaseWorkouts in
//                        guard !firebaseWorkouts.isEmpty else {
//                            dispatchGroup.leave()
//                            return
//                        }
//                        let sortedFirebaseWorkouts = firebaseWorkouts.sorted {
//                            $0.startDateTime! < $1.startDateTime!
//                        }
//                        for firebaseWorkout in sortedFirebaseWorkouts {
//                            if let workout = HealthKitSampleBuilder.createHKWorkout(from: firebaseWorkout) {
//                                let type = workout.workoutActivityType.name
//                                self?.workouts[type, default: []].append(workout)
//                            }
//                        }
//
//                        for (_, workouts) in self!.workouts {
//                            if
//                                // Most recent workout
//                                let workout = workouts.last {
//                                let total = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
//
//                                var metric = HealthMetric(type: HealthMetricType.workout, total: total, date: Date().dayAfter, unitName: "calories", rank: 7)
//
//                                let workoutType = workout.workoutActivityType
//                                if workoutType == .functionalStrengthTraining {
//                                    metric.rank = 2
//                                } else if workoutType == .traditionalStrengthTraining {
//                                    metric.rank = 3
//                                } else if workoutType == .running {
//                                    metric.rank = 4
//                                } else if workoutType == .cycling {
//                                    metric.rank = 5
//                                } else if workoutType == .highIntensityIntervalTraining {
//                                    metric.rank = 6
//                                }
//
//                                metric.hkSample = workout
//
//                                var averageEnergyBurned: Double = 0
//
//                                    workouts.forEach { workout in
//                                        let totalEnergyBurned = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
//                                        averageEnergyBurned += totalEnergyBurned
//
//                                    }
//
//                                if averageEnergyBurned != 0 {
//                                    averageEnergyBurned /= Double(workouts.count)
//                                    metric.average = averageEnergyBurned
//                                }
//                                metrics[HealthMetricCategory.workouts.rawValue, default: []].append(metric)
//                            }
//                        }
//
//                        dispatchGroup.leave()
//                    }
//
//                    dispatchGroup.enter()
//                    self?.mindfulnessFetcher.fetchMindfulness { [self] firebaseMindfulnesses in
//                        guard !firebaseMindfulnesses.isEmpty else {
//                            dispatchGroup.leave()
//                            return
//                        }
//                        for firebaseMindfulness in firebaseMindfulnesses {
//                            if let mindfulness = HealthKitSampleBuilder.createHKMindfulness(from: firebaseMindfulness) {
//                                self?.mindfulnesses.append(mindfulness)
//                            }
//                        }
//
//                        let endDate = Date()
//                        var startDay = endDate.lastYear.dayBefore
//                        var interval = NSDateInterval(start: startDay, duration: 86400)
//                        var map: [Date: Double] = [:]
//                        var sum: Double = 0
//                        for mindfuless in self!.mindfulnesses {
//                            while !(interval.contains(mindfuless.endDate)) && interval.endDate < endDate {
//                                startDay = startDayaddDays(1)
//                                interval = NSDateInterval(start: startDay, duration: 86400)
//                            }
//
//                            let timeSum = mindfuless.endDate.timeIntervalSince(mindfuless.startDate)
//                            map[startDay, default: 0] += timeSum
//                            sum += timeSum
//
//                        }
//
//                        let sortedDates = Array(map.sorted(by: { $0.0 < $1.0 }))
//                        let average = sum / Double(map.count)
//
//                        if let last = sortedDates.last?.key, let val = map[last] {
//                            var metric = HealthMetric(type: .mindfulness, total: val, date: last, unitName: "hrs", rank: HealthMetricType.mindfulness.rank)
//                            metric.average = average
//
//                            metrics[HealthMetricCategory.general.rawValue, default: []].append(metric)
//                        }
//
//                        dispatchGroup.leave()
//                    }
//
//                    dispatchGroup.notify(queue: .main) {
//                        if !metrics.isEmpty {
//                            self?.healthMetrics = metrics
//                            self?.healthMetricSections = Array(metrics.keys)
//                        }
//                        print("loadHealthKitActivities completion")
//                        completion()
//                    }
//                }
