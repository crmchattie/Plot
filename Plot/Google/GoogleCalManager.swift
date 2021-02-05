//
//  GoogleManager.swift
//  Plot
//
//  Created by Cory McHattie on 2/1/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation

class GoogleCalManager {
    private let googleCalService: GoogleCalService
    private var isRunning: Bool
    private var queue: OperationQueue
    
    var isAuthorized: Bool
        
    init(googleCalService: GoogleCalService) {
        self.googleCalService = googleCalService
        self.isRunning = false
        self.isAuthorized = false
        self.queue = OperationQueue()
    }
    
    func setupGoogle(_ completion: @escaping () -> Void) {
        googleCalService.setupGoogle { [weak self] bool in
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
        googleCalService.grabCalendars { (calendars) in
            completion(calendars)
        }
    }
}
