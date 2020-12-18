//
//  ChartValueFormatter.swift
//  Plot
//
//  Created by Cory McHattie on 12/17/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import Charts

class ChartValueFormatter: NSObject, IValueFormatter {
    fileprivate var numberFormatter: NumberFormatter?

    convenience init(numberFormatter: NumberFormatter) {
        self.init()
        self.numberFormatter = numberFormatter
    }

    func stringForValue(_ value: Double, entry: ChartDataEntry, dataSetIndex: Int, viewPortHandler: ViewPortHandler?) -> String {
        guard let numberFormatter = numberFormatter
            else {
                return ""
        }
        return numberFormatter.string(for: value)!
    }
}
