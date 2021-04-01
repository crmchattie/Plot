//
//  EventKit+Utility.swift
//  Plot
//
//  Created by Botond Magyarosi on 01.04.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import EventKit

extension EKRecurrenceRule {
    
    // This might not be a 100% correct,
    // but there's not other way to access the RULE set of `EKRecurrenceRule`.
    func iCalRuleString() -> String {
        let ret = self.description
        return "RRULE " + ret.components(separatedBy: " RRULE ")[1]
    }
}
