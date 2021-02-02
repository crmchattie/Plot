//
//  GoogleSetupAssistant.swift
//  Plot
//
//  Created by Cory McHattie on 2/1/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation
import GoogleSignIn

class GoogleSetupAssistant {
    
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
        guard let currentUser = GIDSignIn.sharedInstance().currentUser,
            let authentication = currentUser.authentication else {
                return nil
        }
        service.authorizer = authentication.fetcherAuthorizer()
        return service
    }()
    
    class func setupGoogle(_ completion: @escaping (Bool) -> Void) {
        if let _ = calendarService {
            print("calendarService does not equal nil")
            completion(true)
            return
        }
        completion(false)
    }
}
