//
//  GoogleSetupAssistant.swift
//  Plot
//
//  Created by Cory McHattie on 2/1/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import GoogleSignIn

class GoogleCalSetupAssistant {
    
    static let currentUser = GIDSignIn.sharedInstance().currentUser
    static let authentication = currentUser?.authentication
    
    /// Creates calendar service with current authentication
    static let calendarService: GTLRCalendarService? = {
        let service = GTLRCalendarService()
        // Have the service object set tickets to fetch consecutive pages
        // of the feed so we do not need to manually fetch them
        service.shouldFetchNextPages = true
        // Have the service object set tickets to retry temporary error conditions
        // automatically
        service.isRetryEnabled = true
        service.maxRetryInterval = 15
        guard let authentication = authentication else { return nil }
        service.authorizer = authentication.fetcherAuthorizer()
        return service
    }()
    
    /// Creates task service with current authentication
    static let taskService: GTLRTasksService? = {
        let service = GTLRTasksService()
        // Have the service object set tickets to fetch consecutive pages
        // of the feed so we do not need to manually fetch them
        service.shouldFetchNextPages = true
        // Have the service object set tickets to retry temporary error conditions
        // automatically
        service.isRetryEnabled = true
        service.maxRetryInterval = 15
        guard let authentication = authentication else { return nil }
        service.authorizer = authentication.fetcherAuthorizer()
        return service
    }()
    
    class func authorizeGEvents(_ completion: @escaping (Bool) -> Void) {
        if calendarService != nil {
            completion(true)
            return
        }
        completion(false)
    }
    
    class func authorizeGReminders(_ completion: @escaping (Bool) -> Void) {
        if taskService != nil {
            completion(true)
            return
        }
        completion(false)
    }
}
