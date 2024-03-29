//
//  Date+Extension.swift
//  Plot
//
//  Created by Hafiz Usama on 2019-10-21.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import Foundation

extension Date {

    func stripTime() -> Date {
        let timeZone = TimeZone.current
        let timeIntervalWithTimeZone = self.timeIntervalSinceReferenceDate + Double(timeZone.secondsFromGMT())
        let timeInterval = floor(timeIntervalWithTimeZone / 86399) * 86400
        return Date(timeIntervalSinceReferenceDate: timeInterval)
    }
    
    func formatRelativeString() -> String {
         let dateFormatter = DateFormatter()
         let calendar = Calendar(identifier: .gregorian)
         dateFormatter.doesRelativeDateFormatting = true

         if calendar.isDateInToday(self) {
             dateFormatter.timeStyle = .short
             dateFormatter.dateStyle = .none
         } else if calendar.isDateInYesterday(self){
             dateFormatter.timeStyle = .none
             dateFormatter.dateStyle = .medium
         } else if calendar.compare(Date(), to: self, toGranularity: .weekOfYear) == .orderedSame {
             let weekday = calendar.dateComponents([.weekday], from: self).weekday ?? 0
             return dateFormatter.weekdaySymbols[weekday-1]
         } else {
             dateFormatter.timeStyle = .none
             dateFormatter.dateStyle = .short
         }

         return dateFormatter.string(from: self)
     }
    
    func startDateTimeString() -> String {
        var value = ""
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
    
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .ordinal
        
        var startDay = ""
        let day = formatter.string(from: self)
        if let integer = Int(day) {
            let number = NSNumber(value: integer)
            startDay = numberFormatter.string(from: number) ?? ""
        }
        
        formatter.dateFormat = "EEEE, MMM"
        value += "\(formatter.string(from: self)) \(startDay)"
        
        formatter.dateFormat = "h:mm a"
        if " \(formatter.string(from: self))" != "12:00 AM" {
            value += " \(formatter.string(from: self))"
        }
            
        return (value)
    
    }
    
    func toString(dateFormat format: String ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
    
    public func removeTimeStamp(fromDate: Date) -> Date {
        guard let date = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day], from: fromDate)) else {
            fatalError("Failed to strip time from Date object")
        }
        return date
    }
    
    var hourBefore: Date {
        var calendar = Calendar(identifier: .gregorian)
        if let utcTimeZone = TimeZone(identifier: "UTC") {
            calendar.timeZone = utcTimeZone
            return calendar.date(byAdding: .hour, value: -1, to: self)!
        } else {
            return Calendar.current.date(byAdding: .hour, value: -1, to: self)!
        }
    }
    
    var dayBefore: Date {
        var calendar = Calendar(identifier: .gregorian)
        if let utcTimeZone = TimeZone(identifier: "UTC") {
            calendar.timeZone = utcTimeZone
            return calendar.date(byAdding: .day, value: -1, to: self)!
        } else {
            return Calendar.current.date(byAdding: .day, value: -1, to: self)!
        }
    }
    
    var dayAfter: Date {
        var calendar = Calendar(identifier: .gregorian)
        if let utcTimeZone = TimeZone(identifier: "UTC") {
            calendar.timeZone = utcTimeZone
            return calendar.date(byAdding: .day, value: 1, to: self)!
        } else {
            return Calendar.current.date(byAdding: .day, value: 1, to: self)!
        }
    }
    
    var weekBefore: Date {
        var calendar = Calendar(identifier: .gregorian)
        if let utcTimeZone = TimeZone(identifier: "UTC") {
            calendar.timeZone = utcTimeZone
            return calendar.date(byAdding: .day, value: -7, to: self)!
        } else {
            return Calendar.current.date(byAdding: .day, value: -7, to: self)!
        }
    }
    
    var weekAfter: Date {
        var calendar = Calendar(identifier: .gregorian)
        if let utcTimeZone = TimeZone(identifier: "UTC") {
            calendar.timeZone = utcTimeZone
            return calendar.date(byAdding: .day, value: 7, to: self)!
        } else {
            return Calendar.current.date(byAdding: .day, value: 7, to: self)!
        }
    }
    
    var monthBefore: Date {
        var calendar = Calendar(identifier: .gregorian)
        if let utcTimeZone = TimeZone(identifier: "UTC") {
            calendar.timeZone = utcTimeZone
            return calendar.date(byAdding: .month, value: -1, to: self)!
        } else {
            return Calendar.current.date(byAdding: .month, value: -1, to: self)!
        }
    }
    
    var monthAfter: Date {
        var calendar = Calendar(identifier: .gregorian)
        if let utcTimeZone = TimeZone(identifier: "UTC") {
            calendar.timeZone = utcTimeZone
            return calendar.date(byAdding: .month, value: 1, to: self)!
        } else {
            return Calendar.current.date(byAdding: .month, value: 1, to: self)!
        }
    }
    
    var lastYear: Date {
        var calendar = Calendar(identifier: .gregorian)
        if let utcTimeZone = TimeZone(identifier: "UTC") {
            calendar.timeZone = utcTimeZone
            return calendar.date(byAdding: .year, value: -1, to: self)!
        } else {
            return Calendar.current.date(byAdding: .year, value: -1, to: self)!
        }
    }
    
    var yearAfter: Date {
        var calendar = Calendar(identifier: .gregorian)
        if let utcTimeZone = TimeZone(identifier: "UTC") {
            calendar.timeZone = utcTimeZone
            return calendar.date(byAdding: .year, value: 1, to: self)!
        } else {
            return Calendar.current.date(byAdding: .year, value: 1, to: self)!
        }
    }
    
    func daysSince(_ date: Date) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        if let utcTimeZone = TimeZone(identifier: "UTC") {
            calendar.timeZone = utcTimeZone
            return calendar.dateComponents([.day], from: date, to: self).day ?? 0
        } else {
            return Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
        }
    }
    
    func addHours(_ hours: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        if let utcTimeZone = TimeZone(identifier: "UTC") {
            calendar.timeZone = utcTimeZone
            return calendar.date(byAdding: .hour, value: hours, to: self)!
        } else {
            return Calendar.current.date(byAdding: .hour, value: hours, to: self)!
        }
    }
    
    func addDays(_ days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: days, to: self)!
    }
    
    func addMonths(_ months: Int) -> Date {
        return Calendar.current.date(byAdding: .month, value: months, to: self)!
    }
    
    func isSameDay(as date: Date) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        if let utcTimeZone = TimeZone(identifier: "UTC") {
            calendar.timeZone = utcTimeZone
            return calendar.isDate(self, inSameDayAs: date)
        } else {
            return Calendar.current.isDate(self, inSameDayAs: date)
        }
    }
}
