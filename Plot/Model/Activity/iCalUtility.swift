//
//  iCalUtility.swift
//  Plot
//
//  Created by Botond Magyarosi on 20.04.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import RRuleSwift

/*
 Supported rules according to the RFC5545 standard:
 RRULE, EXRULE, RDATE and EXDATE.
 Also check GTLRCalendarObjects.h
 */
struct iCalUtility {
    
    func recurringDates(forRules rules: [String], ruleStartDate: Date, startDate: Date, endDate: Date) -> [Date] {
        if let ruleString = rules.first(where: { $0.starts(with: "RRULE") }), let rule = RecurrenceRule(rruleString: ruleString) {
            var totalRule = rule
            totalRule.startDate = ruleStartDate
            var finalEndDate = endDate
            switch totalRule.frequency {
            case .yearly:
                finalEndDate = finalEndDate.nextYear
            case .monthly, .weekly, .daily, .hourly, .minutely, .secondly:
                break
            }
            for rule in rules {
                if rule.starts(with: "RRULE") {

                } else if rule.starts(with: "EXRULE") {

                } else if rule.starts(with: "RDATE") {
                    print("RDATE")
                    guard let rule = InclusionDate(rdateString: rule) else { continue }
                    totalRule.rdate = rule
                } else if rule.starts(with: "EXDATE") {
                    //not sure what to do with granularity here
                    guard let rule = ExclusionDate(exdateString: rule, granularity: .day) else { continue }
                    totalRule.exdate = rule
                } else {
                    print("Invalid recurrence rule found: \(rule)")
                }
            }
            return totalRule.occurrences(between: startDate, and: finalEndDate)
        }
        return []
    }
}
