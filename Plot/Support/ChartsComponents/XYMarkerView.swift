//
//  XYMarkerView.swift
//  ChartsDemo-iOS
//
//  Created by Jacob Christie on 2017-07-09.
//  Copyright © 2017 jc. All rights reserved.
//

import Foundation
import Charts
#if canImport(UIKit)
    import UIKit
#endif

public class XYMarkerView: BalloonMarker {
    public var xAxisValueFormatter: DayAxisValueFormatter
    fileprivate var yFormatter = NumberFormatter()
    fileprivate var units = String()
    fileprivate var dateFormatter = DateComponentsFormatter()
    
    public init(color: UIColor, font: UIFont, textColor: UIColor, insets: UIEdgeInsets,
                xAxisValueFormatter: DayAxisValueFormatter, units: String) {
        self.xAxisValueFormatter = xAxisValueFormatter
        self.units = units
        yFormatter.minimumFractionDigits = 0
        yFormatter.maximumFractionDigits = 0
        super.init(color: color, font: font, textColor: textColor, insets: insets)
    }
    
    public override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        if units == "currency" {
            yFormatter.numberStyle = .currency
            let string = yFormatter.string(from: NSNumber(floatLiteral: entry.y))! + "\n"
            + xAxisValueFormatter.stringForMarkerGivenDate(entry.data, axis: XAxis())
            setLabel(string)
        } else if units == "time" {
            dateFormatter.unitsStyle = .abbreviated
            dateFormatter.allowedUnits = [.hour, .minute]
            let totalString = dateFormatter.string(from: entry.y) ?? "NaN"
            let string = totalString + "\n"
            + xAxisValueFormatter.stringForMarkerGivenDate(entry.data, axis: XAxis())
            setLabel(string)
        } else {
            yFormatter.numberStyle = .decimal
            let string = yFormatter.string(from: NSNumber(floatLiteral: entry.y))! + " \(units)\n"
            + xAxisValueFormatter.stringForMarkerGivenDate(entry.data, axis: XAxis())
            setLabel(string)
        }
    }
    
}
