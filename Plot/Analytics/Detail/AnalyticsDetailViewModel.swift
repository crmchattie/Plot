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
    var range: DateRange = .init(type: .week) {
        didSet { updateRange() }
    }
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
        print("reloadData")
        dataSource.fetchEntries(range: range) { entries in
            self.entries.send(entries)
        }
    }
    
    private func updateRange() {
        print("updateRange")
        dataSource.updateRange(range)
        reloadData()
    }
    
    // MARK: - Actions
    
    func loadPreviousSegment() {
        range.previous()
    }
    
    func loadNextSegment() {
        range.next()
    }
}
