//
//  StackedBarChartViewModel.swift
//  Plot
//
//  Created by Botond Magyarosi on 11/03/2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import Charts
import Combine

protocol StackedBarChartViewModel {
    var onChange: PassthroughSubject<Void, Never> { get }
    
    var sectionTitle: String { get }
    var title: String { get }
    var description: String { get }
    var categories: [CategorySummaryViewModel] { get }
    
    var chartData: BarChartData { get }
}

struct CategorySummaryViewModel {
    let title: String
    let color: UIColor
    let value: String
}

// MARK: - HealthStackedBarChartViewModel

struct HealthStackedBarChartViewModel: StackedBarChartViewModel {
    
    let onChange = PassthroughSubject<Void, Never>()

    var sectionTitle: String = "Health"
    let title: String = "Daily average"
    let description: String = "6h 1m"
    
    var categories: [CategorySummaryViewModel] = []

    let chartData: BarChartData

    init() {
        let dataEntries = (0..<7).map {
            BarChartDataEntry(x: Double($0) + 0.5, yValues: [Double.random(in: 0...20), Double.random(in: 0...20), Double.random(in: 0...20)])
        }
        let chartDataSet = BarChartDataSet(entries: dataEntries)
        chartDataSet.colors = [.blue, .orange, .darkGray]
        chartData = BarChartData(dataSets: [chartDataSet])
        chartData.barWidth = 0.5
        chartData.setDrawValues(false)
    }
}

// MARK: - FinancesStackedBarChartViewModel

struct FinancesStackedBarChartViewModel: StackedBarChartViewModel {
    
    let onChange = PassthroughSubject<Void, Never>()

    var sectionTitle: String = "Health"
    let title: String = "Daily average"
    let description: String = "6h 1m"

    var categories: [CategorySummaryViewModel] = []
    
    let chartData: BarChartData

    init() {
        let dataEntries = (0..<7).map {
            BarChartDataEntry(x: Double($0) + 0.5, yValues: [Double.random(in: 0...20), Double.random(in: 0...20), Double.random(in: 0...20)])
        }
        let chartDataSet = BarChartDataSet(entries: dataEntries)
        chartDataSet.colors = [.blue, .orange, .darkGray]
        chartData = BarChartData(dataSets: [chartDataSet])
        chartData.barWidth = 0.5
        chartData.setDrawValues(false)
    }
}
