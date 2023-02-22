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
    var moodsDataSource: AnalyticsDataSource
    var spendingDataSource: AnalyticsDataSource
    var netWorthDataSource: AnalyticsDataSource
    
    private(set) var sections: [Section] = []
    private let range = DateRange(type: .week)
    
    init(networkController: NetworkController) {
        self.networkController = networkController
        self.goalDataSource = GoalAnalyticsDataSource(range: range, networkController: networkController)
        self.taskDataSource = TaskAnalyticsDataSource(range: range, networkController: networkController)
        self.eventDataSource = EventAnalyticsDataSource(range: range, networkController: networkController)
        self.stepsDataSource = StepsAnalyticsDataSource(range: range, networkController: networkController)
        self.sleepDataSource = SleepAnalyticsDataSource(range: range, networkController: networkController)
        self.activeEnergyDataSource = ActiveEnergyAnalyticsDataSource(range: range, networkController: networkController)
        self.moodsDataSource = MoodAnalyticsDataSource(range: range, networkController: networkController)
        self.spendingDataSource = SpendingAnalyticsDataSource(range: range, networkController: networkController)
        self.netWorthDataSource = NetWorthAnalyticsDataSource(range: range, networkController: networkController)
    }
    
    func loadData(completion: @escaping () -> Void) {
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
        moodsDataSource.loadData {
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
            
            if self.moodsDataSource.dataExists ?? false {
                self.sections.append(Section(title: AnalyticsSections.mood, items: [self.moodsDataSource.chartViewModel.value], dataSources: [self.moodsDataSource]))
            }
            
            if self.spendingDataSource.dataExists ?? false {
                self.sections.append(Section(title: AnalyticsSections.spending, items: [self.spendingDataSource.chartViewModel.value], dataSources: [self.spendingDataSource]))
            }
            
            if self.netWorthDataSource.dataExists ?? false {
                self.sections.append(Section(title: AnalyticsSections.netWorth, items: [self.netWorthDataSource.chartViewModel.value], dataSources: [self.netWorthDataSource]))
            }
            
            completion()
        }
    }
    
    func goalsUpdate(completion: @escaping () -> Void) {
        goalDataSource.loadData {
            if self.goalDataSource.dataExists ?? false {
                if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.goals} ) {
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
        taskDataSource.loadData {
            if self.taskDataSource.dataExists ?? false {
                if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.tasks} ) {
                    self.sections[index] = Section(title: AnalyticsSections.tasks, items: [self.taskDataSource.chartViewModel.value], dataSources: [self.taskDataSource])
                } else if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.goals} ) {
                    self.sections.insert(Section(title: AnalyticsSections.tasks, items: [self.taskDataSource.chartViewModel.value], dataSources: [self.taskDataSource]), at: index + 1)
                } else if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.events} ) {
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
        eventDataSource.loadData {
            if self.eventDataSource.dataExists ?? false {
                if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.events} ) {
                    self.sections[index] = Section(title: AnalyticsSections.events, items: [self.eventDataSource.chartViewModel.value], dataSources: [self.eventDataSource])
                } else if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.tasks} ) {
                    self.sections.insert(Section(title: AnalyticsSections.events, items: [self.eventDataSource.chartViewModel.value], dataSources: [self.eventDataSource]), at: index + 1)
                } else if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.steps} ) {
                    self.sections.insert(Section(title: AnalyticsSections.events, items: [self.eventDataSource.chartViewModel.value], dataSources: [self.eventDataSource]), at: index - 1)
                }
                completion()
            } else {
                completion()
            }
        }
    }
    
    func healthUpdate(completion: @escaping () -> Void) {
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
        stepsDataSource.loadData {
            if self.stepsDataSource.dataExists ?? false {
                if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.steps} ) {
                    self.sections[index] = Section(title: AnalyticsSections.steps, items: [self.stepsDataSource.chartViewModel.value], dataSources: [self.stepsDataSource])
                } else if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.events} ) {
                    self.sections.insert(Section(title: AnalyticsSections.steps, items: [self.stepsDataSource.chartViewModel.value], dataSources: [self.stepsDataSource]), at: index + 1)
                } else if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.sleep} ) {
                    self.sections.insert(Section(title: AnalyticsSections.steps, items: [self.stepsDataSource.chartViewModel.value], dataSources: [self.stepsDataSource]), at: index - 1)
                }
                completion()
            } else {
                completion()
            }
        }
    }
    
    func sleepUpdate(completion: @escaping () -> Void) {
        sleepDataSource.loadData {
            if self.sleepDataSource.dataExists ?? false {
                if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.sleep} ) {
                    self.sections[index] = Section(title: AnalyticsSections.sleep, items: [self.sleepDataSource.chartViewModel.value], dataSources: [self.sleepDataSource])
                } else if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.steps} ) {
                    self.sections.insert(Section(title: AnalyticsSections.sleep, items: [self.sleepDataSource.chartViewModel.value], dataSources: [self.sleepDataSource]), at: index + 1)
                } else if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.activeEnergy} ) {
                    self.sections.insert(Section(title: AnalyticsSections.sleep, items: [self.sleepDataSource.chartViewModel.value], dataSources: [self.sleepDataSource]), at: index - 1)
                }
                completion()
            } else {
                completion()
            }
        }
    }
    
    func activeEnergyUpdate(completion: @escaping () -> Void) {
        activeEnergyDataSource.loadData {
            if self.activeEnergyDataSource.dataExists ?? false {
                if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.activeEnergy} ) {
                    self.sections[index] = Section(title: AnalyticsSections.activeEnergy, items: [self.activeEnergyDataSource.chartViewModel.value], dataSources: [self.activeEnergyDataSource])
                } else if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.sleep} ) {
                    self.sections.insert(Section(title: AnalyticsSections.activeEnergy, items: [self.activeEnergyDataSource.chartViewModel.value], dataSources: [self.activeEnergyDataSource]), at: index + 1)
                } else if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.mood} ) {
                    self.sections.insert(Section(title: AnalyticsSections.activeEnergy, items: [self.activeEnergyDataSource.chartViewModel.value], dataSources: [self.activeEnergyDataSource]), at: index - 1)
                }
                completion()
            } else {
                completion()
            }
        }
    }
    
    func moodUpdate(completion: @escaping () -> Void) {
        moodsDataSource.loadData {
            if self.moodsDataSource.dataExists ?? false {
                if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.mood} ) {
                    self.sections[index] = Section(title: AnalyticsSections.mood, items: [self.moodsDataSource.chartViewModel.value], dataSources: [self.moodsDataSource])
                } else if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.activeEnergy} ) {
                    self.sections.insert(Section(title: AnalyticsSections.mood, items: [self.moodsDataSource.chartViewModel.value], dataSources: [self.moodsDataSource]), at: index + 1)
                } else if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.spending} ) {
                    self.sections.insert(Section(title: AnalyticsSections.mood, items: [self.moodsDataSource.chartViewModel.value], dataSources: [self.moodsDataSource]), at: index - 1)
                }
                completion()
            } else {
                completion()
            }
        }
    }
    
    func financeUpdate(completion: @escaping () -> Void) {
        let group = DispatchGroup()
        
        group.enter()
        spendingUpdate {
            group.leave()
        }
        group.enter()
        netWorthUpdate {
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion()
        }
    }
    
    func spendingUpdate(completion: @escaping () -> Void) {
        spendingDataSource.loadData {
            if self.spendingDataSource.dataExists ?? false {
                if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.spending} ) {
                    self.sections[index] = Section(title: AnalyticsSections.spending, items: [self.spendingDataSource.chartViewModel.value], dataSources: [self.spendingDataSource])
                } else if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.mood} ) {
                    self.sections.insert(Section(title: AnalyticsSections.spending, items: [self.spendingDataSource.chartViewModel.value], dataSources: [self.spendingDataSource]), at: index + 1)
                } else if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.netWorth} ) {
                    self.sections.insert(Section(title: AnalyticsSections.spending, items: [self.spendingDataSource.chartViewModel.value], dataSources: [self.spendingDataSource]), at: index - 1)
                }
                completion()
            } else {
                completion()
            }
        }
    }
    
    func netWorthUpdate(completion: @escaping () -> Void) {
        netWorthDataSource.loadData {
            if self.netWorthDataSource.dataExists ?? false {
                if let index = self.sections.firstIndex(where: {$0.title == AnalyticsSections.netWorth} ) {
                    self.sections[index] = Section(title: AnalyticsSections.netWorth, items: [self.netWorthDataSource.chartViewModel.value], dataSources: [self.netWorthDataSource])
                } else {
                    self.sections.insert(Section(title: AnalyticsSections.netWorth, items: [self.netWorthDataSource.chartViewModel.value], dataSources: [self.netWorthDataSource]), at: self.sections.count)
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
