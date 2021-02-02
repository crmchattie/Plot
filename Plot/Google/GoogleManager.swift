//
//  GoogleManager.swift
//  Plot
//
//  Created by Cory McHattie on 2/1/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation

class GoogleManager {
    private let googleService: GoogleService
    private var isRunning: Bool
    private var queue: OperationQueue
    
    var isAuthorized: Bool
        
    init(googleService: GoogleService) {
        self.googleService = googleService
        self.isRunning = false
        self.isAuthorized = false
        self.queue = OperationQueue()
    }
    
    func setupGoogle(_ completion: @escaping () -> Void) {
        googleService.setupGoogle { [weak self] bool in
            self?.isAuthorized = bool
            completion()
        }
    }
    
    func syncGoogleAccounts(completion: @escaping () -> Void) {
        guard !isRunning, isAuthorized else {
            completion()
            return
        }
        
        isRunning = true
        completion()
    }
    
    func grabCalendars(completion: @escaping ([String: [String]]?) -> Swift.Void) {
        guard isAuthorized else {
            completion(nil)
            return
        }
        googleService.grabCalendars { (calendars) in
            completion(calendars)
        }
    }
}
