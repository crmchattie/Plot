//
//  GoogleCal+Utility.swift
//  Plot
//
//  Created by Cory McHattie on 10/24/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

extension GTLRCalendar_Event {
    
    var identifierClean: String? {
        var intervalKey = "_R"
        guard let id = identifier else { return nil }
        if !id.contains(intervalKey) {
            intervalKey = "_"
        }
        guard id.contains(intervalKey) else { return identifier }
        
        let identifierSegments = id.components(separatedBy: intervalKey)
        guard let last = identifierSegments.last else { return id }
        let dateFormatter = DateFormatter()
        if last.contains("Z") {
            dateFormatter.dateFormat = "yyyyMMdd'T'HHmmssZ"
        } else {
            dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss"
        }
        
        guard let last = identifierSegments.last, let _ = dateFormatter.date(from: last), let firstSegment = identifierSegments.first else { return id }
        return firstSegment
    }
    
    var hasIntervalKey: Bool {
        var intervalKey = "_R"
        guard let id = identifier else { return false }
        if !id.contains(intervalKey) {
            intervalKey = "_"
        }
        guard id.contains(intervalKey) else { return false }
        
        let identifierSegments = id.components(separatedBy: intervalKey)
        guard let last = identifierSegments.last else { return false }
        let dateFormatter = DateFormatter()
        if last.contains("Z") {
            dateFormatter.dateFormat = "yyyyMMdd'T'HHmmssZ"
        } else {
            dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss"
        }
        
        guard let last = identifierSegments.last, let _ = dateFormatter.date(from: last), let firstSegment = identifierSegments.first else { return false }
        return true
    }

}
