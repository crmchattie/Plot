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
        return "RRULE:" + ret.components(separatedBy: " RRULE ")[1]
    }
}

extension EKEvent {

    var originalOccurrenceDate: Date? {
        guard self.isDetached, let interval = timeIntervalFromExternalIdentifier else { return nil }
        return Date(timeIntervalSinceReferenceDate: interval)
    }

    var timeIntervalFromExternalIdentifier: TimeInterval? {
        let intervalKey = "/RID="
        guard let externalId = calendarItemExternalIdentifier, externalId.contains(intervalKey) else { return nil }

        let identifierSegments = externalId.components(separatedBy: intervalKey)
        guard let lastSegment = identifierSegments.last, let ridInterval = TimeInterval(lastSegment) else { return nil }

        return ridInterval
    }
    
    var calendarItemExternalIdentifierClean: String {
        let intervalKey = "/RID="
        guard let externalId = calendarItemExternalIdentifier, externalId.contains(intervalKey) else { return calendarItemExternalIdentifier }

        let identifierSegments = externalId.components(separatedBy: intervalKey)
        guard let firstSegment = identifierSegments.first else { return externalId }

        return firstSegment
    }

}
