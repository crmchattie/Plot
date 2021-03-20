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
    var verticalAxisValueFormatter: IAxisValueFormatter { get }
    
    var sectionTitle: String { get }
    var title: String { get }
    var description: String { get }
    var categories: [CategorySummaryViewModel] { get }
    
    var chartData: BarChartData { get }
}

struct CategorySummaryViewModel {
    let title: String
    let color: UIColor
    let value: Double
    let formattedValue: String
}
