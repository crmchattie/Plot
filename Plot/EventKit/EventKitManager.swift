//
//  EventKitManager.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-11-23.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

class EventKitManager {
    private let eventKitService: EventKitService
    private var isRunning: Bool
    private var activities: [Activity]
    
    init(eventKitService: EventKitService) {
        self.eventKitService = eventKitService
        self.isRunning = false
        self.activities = []
    }
    
    func syncEventKitActivities(_ completion: @escaping () -> Void) {
        guard !isRunning else {
            completion()
            return
        }
        
        activities = []
        isRunning = true
        
        eventKitService.authorizeEventKit { [weak self] (granted, _) in
            guard let weakSelf = self, granted else {
                self?.isRunning = false
                completion()
                return
            }
            
            let yearEvents = weakSelf.eventKitService.fetchEventsOneYearFromNow()
        }
    }
}
