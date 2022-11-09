//
//  DayAxisValueFormatter.swift
//  ChartsDemo-iOS
//
//  Created by Jacob Christie on 2017-07-09.
//  Copyright © 2017 jc. All rights reserved.
//

import Foundation
import Charts

public class DayAxisValueFormatter: NSObject, AxisValueFormatter {
    weak var chart: BarLineChartViewBase?
    var formatType = 0
    let months = ["Jan", "Feb", "Mar",
                  "Apr", "May", "Jun",
                  "Jul", "Aug", "Sep",
                  "Oct", "Nov", "Dec"]
    
    init(chart: BarLineChartViewBase) {
        self.chart = chart
    }
    
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        guard let entry = self.chart?.data?.dataSets.first?.entryForIndex(Int(value)), let date = entry.data as? Date else {
            return ""
        }
        
        switch formatType {
        case 0:
            return date.getHourlyTimeString()
        case 1:
            return date.getShortDayName()
        case 2:
            return date.getDayDigit()
        case 3:
            return date.getShortMonth()
        default:
            return ""
        }
    }
    
    public func stringForMarker(_ value: Double, axis: AxisBase?) -> String {
        if let entry = self.chart?.data?.dataSets.first?.entryForIndex(Int(value)), let date = entry.data as? Date {
            switch formatType {
            case 0:
                return date.getHourlyTimeStringForMarker()
            case 1:
                return date.getMonthAndDateAndYear()
            case 2:
                return date.getMonthAndDateAndYear()
            case 3:
                return date.getShortMonthAndYear()
            default:
                return ""
            }
        } else if let entry = self.chart?.data?.dataSets.first?.entryForIndex(Int(value - 1)), let date = entry.data as? Date {
            switch formatType {
            case 0:
                return date.getHourlyTimeStringForMarker()
            case 1:
                return date.getMonthAndDateAndYear()
            case 2:
                return date.getMonthAndDateAndYear()
            case 3:
                return date.getShortMonthAndYear()
            default:
                return ""
            }
        }
        return ""
    }
    
    private func days(forMonth month: Int, year: Int) -> Int {
        // month is 0-based
        switch month {
        case 1:
            var is29Feb = false
            if year < 1582 {
                is29Feb = (year < 1 ? year + 1 : year) % 4 == 0
            } else if year > 1582 {
                is29Feb = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
            }
            
            return is29Feb ? 29 : 28
            
        case 3, 5, 8, 10:
            return 30
            
        default:
            return 31
        }
    }
    
    private func determineMonth(forDayOfYear dayOfYear: Int) -> Int {
        var month = -1
        var days = 0
        
        while days < dayOfYear {
            month += 1
            if month >= 12 {
                month = 0
            }
            
            let year = determineYear(forDays: days)
            days += self.days(forMonth: month, year: year)
        }
        
        return max(month, 0)
    }
    
    private func determineDayOfMonth(forDays days: Int, month: Int) -> Int {
        var count = 0
        var daysForMonth = 0
        
        while count < month {
            let year = determineYear(forDays: days)
            daysForMonth += self.days(forMonth: count % 12, year: year)
            count += 1
        }
        
        return days - daysForMonth
    }
    
    private func determineYear(forDays days: Int) -> Int {
        switch days {
        case ...366: return 2016
        case 367...730: return 2017
        case 731...1094: return 2018
        case 1095...1458: return 2019
        default: return 2020
        }
    }
}
