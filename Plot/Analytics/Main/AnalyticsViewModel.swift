//
//  AnalyticsViewModel.swift
//  Plot
//
//  Created by Botond Magyarosi on 15.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import Charts
import HealthKit
import Combine

class AnalyticsViewModel {
    
    struct Section {
        let title: AnalyticsSections
        let items: [StackedBarChartViewModel]
        fileprivate let dataSources: [AnalyticsDataSource]
    }
    
    let networkController: NetworkController
    var goalDataSource: AnalyticsDataSource
    var taskDataSource: AnalyticsDataSource
    var eventDataSource: AnalyticsDataSource
    var stepsDataSource: AnalyticsDataSource
    var sleepDataSource: AnalyticsDataSource
    var activeEnergyDataSource: AnalyticsDataSource
    var workoutDataSource: AnalyticsDataSource
    var moodsDataSource: AnalyticsDataSource
    var mindfulnessDataSource: AnalyticsDataSource
    var spendingDataSource: AnalyticsDataSource
    var netWorthDataSource: AnalyticsDataSource
    
    private(set) var sections: [Section] = []
    private let range = DateRange(type: .week)
    private var isRunning = false
    
    init(networkController: NetworkController) {
        self.networkController = networkController
        self.goalDataSource = GoalAnalyticsDataSource(range: range, networkController: networkController)
        self.taskDataSource = TaskAnalyticsDataSource(range: range, networkController: networkController)
        self.eventDataSource = EventAnalyticsDataSource(range: range, networkController: networkController)
        self.stepsDataSource = StepsAnalyticsDataSource(range: range, networkController: networkController)
        self.sleepDataSource = SleepAnalyticsDataSource(range: range, networkController: networkController)
        self.activeEnergyDataSource = ActiveEnergyAnalyticsDataSource(range: range, networkController: networkController)
        self.workoutDataSource = WorkoutAnalyticsDataSource(range: range, networkController: networkController)
        self.moodsDataSource = MoodAnalyticsDataSource(range: range, networkController: networkController)
        self.mindfulnessDataSource = MindfulnessAnalyticsDataSource(range: range, networkController: networkController)
        self.spendingDataSource = SpendingAnalyticsDataSource(range: range, networkController: networkController)
        self.netWorthDataSource = NetWorthAnalyticsDataSource(range: range, networkController: networkController)
    }
    
    func loadData(completion: @escaping () -> Void) {
        guard !isRunning else {
            completion()
            return
        }
        
        isRunning = true
        let group = DispatchGroup()
        
        group.enter()
        goalDataSource.loadData {
            group.leave()
        }
        
        group.enter()
        taskDataSource.loadData {
            group.leave()
        }

        group.enter()
        eventDataSource.loadData {
            group.leave()
        }
        
        group.enter()
        stepsDataSource.loadData {
            group.leave()
        }
        
        group.enter()
        sleepDataSource.loadData {
            group.leave()
        }
        
        group.enter()
        activeEnergyDataSource.loadData {
            group.leave()
        }
        
        group.enter()
        workoutDataSource.loadData {
            group.leave()
        }
        
        group.enter()
        moodsDataSource.loadData {
            group.leave()
        }
        
        group.enter()
        mindfulnessDataSource.loadData {
            group.leave()
        }
        
        group.enter()
        spendingDataSource.loadData {
            group.leave()
        }
        
        group.enter()
        netWorthDataSource.loadData {
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.sections = []
            
            if self.goalDataSource.dataExists ?? false {
                self.sections.append(Section(title: AnalyticsSections.goals, items: [self.goalDataSource.chartViewModel.value], dataSources: [self.goalDataSource]))
            }
            
            if self.taskDataSource.dataExists ?? false {
                self.sections.append(Section(title: AnalyticsSections.tasks, items: [self.taskDataSource.chartViewModel.value], dataSources: [self.taskDataSource]))
            }
            
            if self.eventDataSource.dataExists ?? false {
                self.sections.append(Section(title: AnalyticsSections.events, items: [self.eventDataSource.chartViewModel.value], dataSources: [self.eventDataSource]))
            }
            
            if self.stepsDataSource.dataExists ?? false {
                self.sections.append(Section(title: AnalyticsSections.steps, items: [self.stepsDataSource.chartViewModel.value], dataSources: [self.stepsDataSource]))
            }
            
            if self.sleepDataSource.dataExists ?? false {
                self.sections.append(Section(title: AnalyticsSections.sleep, items: [self.sleepDataSource.chartViewModel.value], dataSources: [self.sleepDataSource]))
            }
            
            if self.activeEnergyDataSource.dataExists ?? false {
                self.sections.append(Section(title: AnalyticsSections.activeEnergy, items: [self.activeEnergyDataSource.chartViewModel.value], dataSources: [self.activeEnergyDataSource]))
            }
            
            if self.workoutDataSource.dataExists ?? false {
                self.sections.append(Section(title: AnalyticsSections.workouts, items: [self.workoutDataSource.chartViewModel.value], dataSources: [self.workoutDataSource]))
            }
            
            if self.moodsDataSource.dataExists ?? false {
                self.sections.append(Section(title: AnalyticsSections.mood, items: [self.moodsDataSource.chartViewModel.value], dataSources: [self.moodsDataSource]))
            }
            
            if self.mindfulnessDataSource.dataExists ?? false {
                self.sections.append(Section(title: AnalyticsSections.mindfulness, items: [self.mindfulnessDataSource.chartViewModel.value], dataSources: [self.mindfulnessDataSource]))
            }
            
            if self.spendingDataSource.dataExists ?? false {
                self.sections.append(Section(title: AnalyticsSections.spending, items: [self.spendingDataSource.chartViewModel.value], dataSources: [self.spendingDataSource]))
            }
            
            if self.netWorthDataSource.dataExists ?? false {
                self.sections.append(Section(title: AnalyticsSections.netWorth, items: [self.netWorthDataSource.chartViewModel.value], dataSources: [self.netWorthDataSource]))
            }
            
            self.isRunning = false
            completion()
        }
    }
    
    func goalsUpdate(completion: @escaping () -> Void) {
        guard !isRunning else {
            completion()
            return
        }
        
        goalDataSource.loadData {
            if self.goalDataSource.dataExists ?? false {
                if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.goals} ), self.sections.count > index {
                    self.sections[index] = Section(title: AnalyticsSections.goals, items: [self.goalDataSource.chartViewModel.value], dataSources: [self.goalDataSource])
                } else {
                    self.sections.insert(Section(title: AnalyticsSections.goals, items: [self.goalDataSource.chartViewModel.value], dataSources: [self.goalDataSource]), at: 0)
                }
                completion()
            } else {
                completion()
            }
        }
    }
    
    func tasksUpdate(completion: @escaping () -> Void) {
        guard !isRunning else {
            completion()
            return
        }
        
        taskDataSource.loadData {
            if self.taskDataSource.dataExists ?? false {
                if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.tasks} ), self.sections.count > index {
                    self.sections[index] = Section(title: AnalyticsSections.tasks, items: [self.taskDataSource.chartViewModel.value], dataSources: [self.taskDataSource])
                } else if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.goals} ), self.sections.count > index {
                    self.sections.insert(Section(title: AnalyticsSections.tasks, items: [self.taskDataSource.chartViewModel.value], dataSources: [self.taskDataSource]), at: index + 1)
                } else if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.events} ), self.sections.count > index {
                    self.sections.insert(Section(title: AnalyticsSections.tasks, items: [self.taskDataSource.chartViewModel.value], dataSources: [self.taskDataSource]), at: index - 1)
                } else {
                    self.sections.insert(Section(title: AnalyticsSections.tasks, items: [self.taskDataSource.chartViewModel.value], dataSources: [self.taskDataSource]), at: 0)
                }
                completion()
            } else {
                completion()
            }
        }
    }
    
    func eventsUpdate(completion: @escaping () -> Void) {
        guard !isRunning else {
            completion()
            return
        }
        
        eventDataSource.loadData {
            if self.eventDataSource.dataExists ?? false {
                if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.events} ), self.sections.count > index {
                    self.sections[index] = Section(title: AnalyticsSections.events, items: [self.eventDataSource.chartViewModel.value], dataSources: [self.eventDataSource])
                } else if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.tasks} ), self.sections.count > index {
                    self.sections.insert(Section(title: AnalyticsSections.events, items: [self.eventDataSource.chartViewModel.value], dataSources: [self.eventDataSource]), at: index + 1)
                } else if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.steps} ), self.sections.count > index {
                    self.sections.insert(Section(title: AnalyticsSections.events, items: [self.eventDataSource.chartViewModel.value], dataSources: [self.eventDataSource]), at: index - 1)
                } else {
                    self.sections.append(Section(title: AnalyticsSections.events, items: [self.eventDataSource.chartViewModel.value], dataSources: [self.eventDataSource]))
                }
                completion()
            } else {
                completion()
            }
        }
    }
    
    func healthUpdate(completion: @escaping () -> Void) {
        guard !isRunning else {
            completion()
            return
        }
        
        let group = DispatchGroup()
        
        group.enter()
        stepsUpdate {
            group.leave()
        }
        group.enter()
        sleepUpdate {
            group.leave()
        }
        group.enter()
        activeEnergyUpdate {
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion()
        }
    }
    
    func stepsUpdate(completion: @escaping () -> Void) {
        guard !isRunning else {
            completion()
            return
        }
        
        stepsDataSource.loadData {
            if self.stepsDataSource.dataExists ?? false {
                if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.steps} ), self.sections.count > index {
                    self.sections[index] = Section(title: AnalyticsSections.steps, items: [self.stepsDataSource.chartViewModel.value], dataSources: [self.stepsDataSource])
                } else if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.events} ), self.sections.count > index {
                    self.sections.insert(Section(title: AnalyticsSections.steps, items: [self.stepsDataSource.chartViewModel.value], dataSources: [self.stepsDataSource]), at: index + 1)
                } else if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.sleep} ), self.sections.count > index {
                    self.sections.insert(Section(title: AnalyticsSections.steps, items: [self.stepsDataSource.chartViewModel.value], dataSources: [self.stepsDataSource]), at: index - 1)
                } else {
                    self.sections.append(Section(title: AnalyticsSections.steps, items: [self.stepsDataSource.chartViewModel.value], dataSources: [self.stepsDataSource]))
                }
                completion()
            } else {
                completion()
            }
        }
    }
    
    func sleepUpdate(completion: @escaping () -> Void) {
        guard !isRunning else {
            completion()
            return
        }
        
        sleepDataSource.loadData {
            if self.sleepDataSource.dataExists ?? false {
                if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.sleep} ), self.sections.count > index {
                    self.sections[index] = Section(title: AnalyticsSections.sleep, items: [self.sleepDataSource.chartViewModel.value], dataSources: [self.sleepDataSource])
                } else if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.steps} ), self.sections.count > index {
                    self.sections.insert(Section(title: AnalyticsSections.sleep, items: [self.sleepDataSource.chartViewModel.value], dataSources: [self.sleepDataSource]), at: index + 1)
                } else if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.activeEnergy} ), self.sections.count > index {
                    self.sections.insert(Section(title: AnalyticsSections.sleep, items: [self.sleepDataSource.chartViewModel.value], dataSources: [self.sleepDataSource]), at: index - 1)
                } else {
                    self.sections.append(Section(title: AnalyticsSections.sleep, items: [self.sleepDataSource.chartViewModel.value], dataSources: [self.sleepDataSource]))
                }
                completion()
            } else {
                completion()
            }
        }
    }
    
    func activeEnergyUpdate(completion: @escaping () -> Void) {
        guard !isRunning else {
            completion()
            return
        }
        
        activeEnergyDataSource.loadData {
            if self.activeEnergyDataSource.dataExists ?? false {
                if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.activeEnergy} ), self.sections.count > index {
                    self.sections[index] = Section(title: AnalyticsSections.activeEnergy, items: [self.activeEnergyDataSource.chartViewModel.value], dataSources: [self.activeEnergyDataSource])
                } else if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.sleep} ), self.sections.count > index {
                    self.sections.insert(Section(title: AnalyticsSections.activeEnergy, items: [self.activeEnergyDataSource.chartViewModel.value], dataSources: [self.activeEnergyDataSource]), at: index + 1)
                } else if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.workouts} ), self.sections.count > index {
                    self.sections.insert(Section(title: AnalyticsSections.activeEnergy, items: [self.activeEnergyDataSource.chartViewModel.value], dataSources: [self.activeEnergyDataSource]), at: index - 1)
                } else {
                    self.sections.append(Section(title: AnalyticsSections.activeEnergy, items: [self.activeEnergyDataSource.chartViewModel.value], dataSources: [self.activeEnergyDataSource]))
                }
                completion()
            } else {
                completion()
            }
        }
    }
    
    func workoutUpdate(completion: @escaping () -> Void) {
        guard !isRunning else {
            completion()
            return
        }
        
        workoutDataSource.loadData {
            if self.workoutDataSource.dataExists ?? false {
                if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.workouts} ), self.sections.count > index {
                    self.sections[index] = Section(title: AnalyticsSections.workouts, items: [self.workoutDataSource.chartViewModel.value], dataSources: [self.workoutDataSource])
                } else if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.activeEnergy} ), self.sections.count > index {
                    self.sections.insert(Section(title: AnalyticsSections.workouts, items: [self.workoutDataSource.chartViewModel.value], dataSources: [self.workoutDataSource]), at: index + 1)
                } else if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.mood} ), self.sections.count > index {
                    self.sections.insert(Section(title: AnalyticsSections.workouts, items: [self.workoutDataSource.chartViewModel.value], dataSources: [self.workoutDataSource]), at: index - 1)
                } else {
                    self.sections.append(Section(title: AnalyticsSections.workouts, items: [self.workoutDataSource.chartViewModel.value], dataSources: [self.workoutDataSource]))
                }
                completion()
            } else {
                completion()
            }
        }
    }
    
    func moodUpdate(completion: @escaping () -> Void) {
        guard !isRunning else {
            completion()
            return
        }
        
        moodsDataSource.loadData {
            if self.moodsDataSource.dataExists ?? false {
                if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.mood} ), self.sections.count > index {
                    self.sections[index] = Section(title: AnalyticsSections.mood, items: [self.moodsDataSource.chartViewModel.value], dataSources: [self.moodsDataSource])
                } else if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.workouts} ), self.sections.count > index {
                    self.sections.insert(Section(title: AnalyticsSections.mood, items: [self.moodsDataSource.chartViewModel.value], dataSources: [self.moodsDataSource]), at: index + 1)
                } else if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.mindfulness} ), self.sections.count > index {
                    self.sections.insert(Section(title: AnalyticsSections.mood, items: [self.moodsDataSource.chartViewModel.value], dataSources: [self.moodsDataSource]), at: index - 1)
                } else {
                    self.sections.append(Section(title: AnalyticsSections.mood, items: [self.moodsDataSource.chartViewModel.value], dataSources: [self.moodsDataSource]))
                }
                completion()
            } else {
                completion()
            }
        }
    }
    
    func mindfulnessUpdate(completion: @escaping () -> Void) {
        guard !isRunning else {
            completion()
            return
        }
        
        mindfulnessDataSource.loadData {
            if self.mindfulnessDataSource.dataExists ?? false {
                if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.mindfulness} ), self.sections.count > index {
                    self.sections[index] = Section(title: AnalyticsSections.mindfulness, items: [self.mindfulnessDataSource.chartViewModel.value], dataSources: [self.mindfulnessDataSource])
                } else if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.mood} ), self.sections.count > index {
                    self.sections.insert(Section(title: AnalyticsSections.mindfulness, items: [self.mindfulnessDataSource.chartViewModel.value], dataSources: [self.mindfulnessDataSource]), at: index + 1)
                } else if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.spending} ), self.sections.count > index {
                    self.sections.insert(Section(title: AnalyticsSections.mindfulness, items: [self.mindfulnessDataSource.chartViewModel.value], dataSources: [self.mindfulnessDataSource]), at: index - 1)
                } else {
                    self.sections.append(Section(title: AnalyticsSections.mindfulness, items: [self.mindfulnessDataSource.chartViewModel.value], dataSources: [self.mindfulnessDataSource]))
                }
                completion()
            } else {
                completion()
            }
        }
    }
    
    func spendingUpdate(completion: @escaping () -> Void) {
        guard !isRunning else {
            completion()
            return
        }
        
        spendingDataSource.loadData {
            if self.spendingDataSource.dataExists ?? false {
                if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.spending} ), self.sections.count > index {
                    self.sections[index] = Section(title: AnalyticsSections.spending, items: [self.spendingDataSource.chartViewModel.value], dataSources: [self.spendingDataSource])
                } else if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.mindfulness} ), self.sections.count > index {
                    self.sections.insert(Section(title: AnalyticsSections.spending, items: [self.spendingDataSource.chartViewModel.value], dataSources: [self.spendingDataSource]), at: index + 1)
                } else if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.netWorth}), self.sections.count > index {
                    self.sections.insert(Section(title: AnalyticsSections.spending, items: [self.spendingDataSource.chartViewModel.value], dataSources: [self.spendingDataSource]), at: index - 1)
                } else {
                    self.sections.append(Section(title: AnalyticsSections.spending, items: [self.spendingDataSource.chartViewModel.value], dataSources: [self.spendingDataSource]))
                }
                completion()
            } else {
                completion()
            }
        }
    }
    
    func netWorthUpdate(completion: @escaping () -> Void) {
        guard !isRunning else {
            completion()
            return
        }
        
        netWorthDataSource.loadData {
            if self.netWorthDataSource.dataExists ?? false {
                if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.netWorth} ), self.sections.count > index {
                    self.sections[index] = Section(title: AnalyticsSections.netWorth, items: [self.netWorthDataSource.chartViewModel.value], dataSources: [self.netWorthDataSource])
                } else {
                    self.sections.append(Section(title: AnalyticsSections.netWorth, items: [self.netWorthDataSource.chartViewModel.value], dataSources: [self.netWorthDataSource]))
                }
                completion()
            } else {
                completion()
            }
        }
    }
    
    func makeDetailViewModel(for indexPath: IndexPath) -> AnalyticsDetailViewModel {
        let dataSource = sections[indexPath.section].dataSources[indexPath.row / 2]
        return AnalyticsDetailViewModel(dataSource: dataSource, networkController: networkController)
    }    
}

enum AnalyticsSections: String {
    case goals = "Goals"
    case tasks = "Tasks"
    case events = "Events"
    case steps = "Steps"
    case sleep = "Sleep"
    case activeEnergy = "Active Energy"
    case mood = "Moods"
    case workouts = "Workouts"
    case mindfulness = "Mindfulness"
    case spending = "Spending"
    case netWorth = "Net Worth"
}
