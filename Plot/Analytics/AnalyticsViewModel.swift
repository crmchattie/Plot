//
//  AnalyticsViewModel.swift
//  Plot
//
//  Created by Botond Magyarosi on 15.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import Charts

class AnalyticsViewModel {
    
    let service = SummaryService()
    let networkController: NetworkController
    
    private(set) var items: [StackedBarChartViewModel] = []
    
    init(networkController: NetworkController) {
        self.networkController = networkController
//        items = [
            
//            HealthStackedBarChartViewModel(),
//            FinancesStackedBarChartViewModel()
//        ]
    }
    
    func fetchActivities(completion: @escaping (Result<Void, Error>) -> Void) {
        service.getSamples(segmentType: .week,
                           activities: networkController.activityService.activities,
                           transactions: nil) { (_, foo, bar, stats, err) in
            print(foo, bar, stats)
            DispatchQueue.global(qos: .background).async {
                if let activities = stats?[.calendarSummary] {
                    self.items.append(ActivityStackedBarChartViewModel(items: activities))
                }
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            }
        }
    }
}

//private extension BarChartDataSet {
//
////    static func activityDataSet(items: [Statistic], startDate: Date, endDate: Date) -> BarChartDataSet {
////        var entries: [BarChartDataEntry] = []
////        for offset in 0..<endDate.daysSince(startDate) {
////            if startDate.addDays(offset).is
////        }
////        return BarChartDataSet(entries: entries)
////    }
//}
