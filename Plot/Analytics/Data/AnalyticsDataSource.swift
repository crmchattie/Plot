//
//  AnalyticsDataSource.swift
//  Plot
//
//  Created by Botond Magyarosi on 11/03/2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import Charts
import Combine
import HealthKit

protocol AnalyticsDataSource: AnyObject {    
    var title: String { get }
    var dataExists: Bool? { get set }
    var range: DateRange { get set }
    func updateRange(_ newRange: DateRange)
    
    var chartViewModel: CurrentValueSubject<StackedBarChartViewModel, Never> { get }
    
    /// Load data asyncronously.
    func loadData(completion: (() -> Void)?)
    
    /// Fetch entries for the current analytics summary. Used on the detail list.
    /// - Parameters:
    ///   - range: Date range to fetch entries to
    ///   - completion: returns a list of entries
    func fetchEntries(range: DateRange, completion: ([AnalyticsBreakdownEntry]) -> Void)
}

extension AnalyticsDataSource {
    func updateRange(_ newRange: DateRange, completion: @escaping () -> Void) {
        range = newRange
        loadData(completion: completion)
    }
}

enum AnalyticsBreakdownEntry {
    case activity(Activity)
    case transaction(Transaction)
    case account(MXAccount)
    case sample(HKSample)
    case mood(Mood)
    case workout(Workout)
    case mindfulness(Mindfulness)
}
