//
//  AnalyticsDetailViewModel.swift
//  Plot
//
//  Created by Botond Magyarosi on 16.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class AnalyticsDetailViewModel {
    
    let networkController: NetworkController
    private let dataSource: AnalyticsDataSource
    
    var title: String { dataSource.title }
    var range: DateRange = .init(type: .week)
    let chartViewModel: CurrentValueSubject<StackedBarChartViewModel, Never>
    var entries = CurrentValueSubject<[AnalyticsBreakdownEntry], Never>([])
    
    init(
        dataSource: AnalyticsDataSource,
        networkController: NetworkController
    ) {
        self.dataSource = dataSource
        self.chartViewModel = dataSource.chartViewModel
        self.networkController = networkController
        reloadData()
    }
    
    private func reloadData() {
        dataSource.fetchEntries(range: range) { entries in
            self.entries.send(entries)
        }
    }
    
    private func updateRange(completion: @escaping () -> Void) {
        dataSource.updateRange(range) {
            self.reloadData()
            completion()
        }
    }
    
    // MARK: - Actions
    
    func updateType(completion: @escaping () -> Void) {
        updateRange {
            completion()
        }
    }
    
    func loadPreviousSegment(completion: @escaping () -> Void) {
        range.previous()
        updateRange {
            completion()
        }
    }
    
    func loadNextSegment(completion: @escaping () -> Void) {
        range.next()
        updateRange {
            completion()
        }
    }
    
    func filter(date: Date?) {
        range.filter(date: date)
        reloadData()
    }
}
