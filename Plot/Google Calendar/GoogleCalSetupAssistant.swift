//
//  GoogleSetupAssistant.swift
//  Plot
//
//  Created by Cory McHattie on 2/1/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import GoogleSignIn

let googleEmailScope = "https://www.googleapis.com/auth/calendar"
let googleTaskScope = "https://www.googleapis.com/auth/tasks"
let googleScopes = [googleEmailScope, googleTaskScope]

class GoogleCalSetupAssistant {
    static var calendarService: GTLRCalendarService?
    static var taskService: GTLRTasksService?
    
    class func setupCalendarService(_ completion: @escaping () -> Void) {
        let currentUser = GIDSignIn.sharedInstance().currentUser
        let authentication = currentUser?.authentication
        let grantedScopes = currentUser?.grantedScopes as? [String]
        
        authentication?.getTokensWithHandler { authentication, error in
            guard error == nil, let authentication = authentication, let grantedScopes = grantedScopes, grantedScopes.contains(googleTaskScope)
            else {
                print(error as Any)
                completion()
                return
            }
            let service = GTLRCalendarService()
            // Have the service object set tickets to fetch consecutive pages
            // of the feed so we do not need to manually fetch them
            service.shouldFetchNextPages = true
            // Have the service object set tickets to retry temporary error conditions
            // automatically
            service.isRetryEnabled = true
            service.maxRetryInterval = 15
            service.authorizer = authentication.fetcherAuthorizer()
            calendarService = service
            completion()
        }
    }
    
    class func setupTaskService(_ completion: @escaping () -> Void) {        
        let currentUser = GIDSignIn.sharedInstance().currentUser
        let authentication = currentUser?.authentication
        let grantedScopes = currentUser?.grantedScopes as? [String]
        
        authentication?.getTokensWithHandler { authentication, error in
            guard error == nil, let authentication = authentication, let grantedScopes = grantedScopes, grantedScopes.contains(googleTaskScope)
            else {
                print(error as Any)
                completion()
                return
            }
            let service = GTLRTasksService()
            // Have the service object set tickets to fetch consecutive pages
            // of the feed so we do not need to manually fetch them
            service.shouldFetchNextPages = true
            // Have the service object set tickets to retry temporary error conditions
            // automatically
            service.isRetryEnabled = true
            service.maxRetryInterval = 15
            service.authorizer = authentication.fetcherAuthorizer()
            GoogleCalSetupAssistant.taskService = service
            completion()
        }
    }
    
    class func authorizeGEvents(_ completion: @escaping (Bool) -> Void) {
        setupCalendarService {
            if calendarService != nil {
                completion(true)
                return
            }
            completion(false)
        }
    }
    
    class func authorizeGReminders(_ completion: @escaping (Bool) -> Void) {
        setupTaskService {
            if taskService != nil {
                completion(true)
                return
            }
            completion(false)
        }
    }
}
