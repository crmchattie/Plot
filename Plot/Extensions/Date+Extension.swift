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
//        formatter.timeZone = TimeZone(identifier: "UTC")
    
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
        value += " \(formatter.string(from: self))"
            
        return (value)
    
    }

}
