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
    
    private let networkController: NetworkController
    private(set) var chartViewModel: AnalyticsBreakdownViewModel
    
    var title: String { chartViewModel.title }
    
    var range: DateRange = .init(type: .week) {
        didSet { updateRange() }
    }
    
    var entries = CurrentValueSubject<[AnalyticsBreakdownEntry], Never>([])
    
    init(
        chartViewModel: AnalyticsBreakdownViewModel,
        networkController: NetworkController
    ) {
        self.chartViewModel = chartViewModel
        self.networkController = networkController
        reloadData()
    }
    
    private func reloadData() {
        chartViewModel.fetchEntries(range: range) { entries in
            self.entries.send(entries)
        }
    }
    
    private func updateRange() {
        chartViewModel.updateRange(range)
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
