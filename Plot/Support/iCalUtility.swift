//
//  iCalUtility.swift
//  Plot
//
//  Created by Botond Magyarosi on 20.04.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
//import RRuleSwift

/*
 Supported rules according to the RFC5545 standard:
 RRULE, EXRULE, RDATE and EXDATE.
 Also check GTLRCalendarObjects.h
 */
struct iCalUtility {
    
    func recurringDates(forRules rules: [String], startDate: Date) -> [Date] {
        let recurringDates: [Date] = []

        for rule in rules {
            if rule.starts(with: "RRULE") {
//                guard var rule = RecurrenceRule(rruleString: rule) else { continue }
//                rule.startDate = startDate
//                recurringDates += rule.allOccurrences()
            } else if rule.starts(with: "EXRULE") {

            } else if rule.starts(with: "RDATE") {
//                guard let rule = InclusionDate(rdateString: rule) else { continue }
//                recurringDates += rule.dates
            } else if rule.starts(with: "EXDATE") {
                
            } else {
                print("Invalid recurrence rule found: \(rule)")
            }
        }
        return recurringDates
    }
}
