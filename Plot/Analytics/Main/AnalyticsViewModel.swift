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
        let title: String
        let items: [StackedBarChartViewModel]
        fileprivate let dataSources: [AnalyticsDataSource]
    }
    
    let networkController: NetworkController
    
    private(set) var sections: [Section] = []
    private let range = DateRange(type: .week)
    
    init(networkController: NetworkController) {
        self.networkController = networkController
        addObservers()
    }
    
    func loadData(completion: @escaping () -> Void) {
        let group = DispatchGroup()
        
        group.enter()
        let taskDataSource = TaskAnalyticsDataSource(range: range, networkController: networkController)
        taskDataSource.loadData {
            group.leave()
        }

        group.enter()
        let eventDataSource = EventAnalyticsDataSource(range: range, networkController: networkController)
        eventDataSource.loadData {
            group.leave()
        }
        
        group.enter()
        let stepsDataSource = StepsAnalyticsDataSource(range: range, networkController: networkController)
        stepsDataSource.loadData {
            group.leave()
        }
        
        group.enter()
        let sleepDataSource = SleepAnalyticsDataSource(range: range, networkController: networkController)
        sleepDataSource.loadData {
            group.leave()
        }
        
        group.enter()
        let activeEnergyDataSource = ActiveEnergyAnalyticsDataSource(range: range, networkController: networkController)
        activeEnergyDataSource.loadData {
            group.leave()
        }
        
        group.enter()
        let financeDataSource = TransactionAnalyticsDataSource(range: range, networkController: networkController)
        financeDataSource.loadData {
            group.leave()
        }
        
        group.enter()
        let netWorthViewModel = NetWorthAnalyticsDataSource(range: range, networkController: networkController)
        netWorthViewModel.loadData {
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.sections = []
            
            if taskDataSource.dataExists ?? false {
                self.sections.append(Section(title: "Completed Tasks", items: [taskDataSource.chartViewModel.value], dataSources: [taskDataSource]))
            }
            
            if eventDataSource.dataExists ?? false {
                self.sections.append(Section(title: "Events", items: [eventDataSource.chartViewModel.value], dataSources: [eventDataSource]))
            }
            
            if stepsDataSource.dataExists ?? false {
                self.sections.append(Section(title: "Steps", items: [stepsDataSource.chartViewModel.value], dataSources: [stepsDataSource]))
            }
            
            if sleepDataSource.dataExists ?? false {
                self.sections.append(Section(title: "Sleep", items: [sleepDataSource.chartViewModel.value], dataSources: [sleepDataSource]))
            }
            
            if activeEnergyDataSource.dataExists ?? false {
                self.sections.append(Section(title: "Active Calories", items: [activeEnergyDataSource.chartViewModel.value], dataSources: [activeEnergyDataSource]))
            }
            
            if financeDataSource.dataExists ?? false {
                self.sections.append(Section(title: "Spending", items: [financeDataSource.chartViewModel.value], dataSources: [financeDataSource]))
            }
            
            if netWorthViewModel.dataExists ?? false {
                self.sections.append(Section(title: "Net Worth", items: [netWorthViewModel.chartViewModel.value], dataSources: [netWorthViewModel]))
            }
            
            completion()
        }
    }
    
    func makeDetailViewModel(for indexPath: IndexPath) -> AnalyticsDetailViewModel {
        let dataSource = sections[indexPath.section].dataSources[indexPath.row / 2]
        return AnalyticsDetailViewModel(dataSource: dataSource, networkController: networkController)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(tasksUpdated), name: .tasksUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(eventsUpdated), name: .calendarActivitiesUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(healthUpdated), name: .healthUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(financeUpdated), name: .financeUpdated, object: nil)
    }
    
    @objc fileprivate func tasksUpdated() {
        if let section = sections.first(where: {$0.title == "Tasks"}) {
            section.dataSources[0].loadData(completion: nil)
        } else if sections.isEmpty {
            let dataSource = TaskAnalyticsDataSource(range: range, networkController: networkController)
            dataSource.loadData {
                if dataSource.dataExists ?? false {
                    self.sections.append(Section(title: "Completed Tasks", items: [dataSource.chartViewModel.value], dataSources: [dataSource]))
                }
            }
        }
    }
    
    @objc fileprivate func eventsUpdated() {
        if let section = sections.first(where: {$0.title == "Events"}) {
            section.dataSources[0].loadData(completion: nil)
        } else if sections.isEmpty {
            let dataSource = EventAnalyticsDataSource(range: range, networkController: networkController)
            dataSource.loadData {
                if dataSource.dataExists ?? false {
                    self.sections.append(Section(title: "Events", items: [dataSource.chartViewModel.value], dataSources: [dataSource]))
                }
            }
        }
    }
    
    @objc fileprivate func healthUpdated() {
        if let section = sections.first(where: {$0.title == "Steps"}) {
            section.dataSources[0].loadData(completion: nil)
        } else if sections.isEmpty {
            let dataSource = StepsAnalyticsDataSource(range: range, networkController: networkController)
            dataSource.loadData {
                if dataSource.dataExists ?? false {
                    self.sections.append(Section(title: "Steps", items: [dataSource.chartViewModel.value], dataSources: [dataSource]))
                }
            }
        }
        if let section = sections.first(where: {$0.title == "Sleep"}) {
            section.dataSources[0].loadData(completion: nil)
        } else if sections.isEmpty {
            let dataSource = SleepAnalyticsDataSource(range: range, networkController: networkController)
            dataSource.loadData {
                if dataSource.dataExists ?? false {
                    self.sections.append(Section(title: "Sleep", items: [dataSource.chartViewModel.value], dataSources: [dataSource]))
                }
            }
        }
        if let section = sections.first(where: {$0.title == "Active Energy"}) {
            section.dataSources[0].loadData(completion: nil)
        } else if sections.isEmpty {
            let dataSource = ActiveEnergyAnalyticsDataSource(range: range, networkController: networkController)
            dataSource.loadData {
                if dataSource.dataExists ?? false {
                    self.sections.append(Section(title: "Active Energy", items: [dataSource.chartViewModel.value], dataSources: [dataSource]))
                }
            }
        }
    }
    
    @objc fileprivate func financeUpdated() {
        if let section = sections.first(where: {$0.title == "Spending"}) {
            section.dataSources[0].loadData(completion: nil)
        } else if sections.isEmpty {
            let dataSource = TransactionAnalyticsDataSource(range: range, networkController: networkController)
            dataSource.loadData {
                if dataSource.dataExists ?? false {
                    self.sections.append(Section(title: "Spending", items: [dataSource.chartViewModel.value], dataSources: [dataSource]))
                }
            }
        }
        if let section = sections.first(where: {$0.title == "Net Worth"}) {
            section.dataSources[0].loadData(completion: nil)
        } else if sections.isEmpty {
            let dataSource = NetWorthAnalyticsDataSource(range: range, networkController: networkController)
            dataSource.loadData {
                if dataSource.dataExists ?? false {
                    self.sections.append(Section(title: "Net Worth", items: [dataSource.chartViewModel.value], dataSources: [dataSource]))
                }
            }
        }
    }
}
