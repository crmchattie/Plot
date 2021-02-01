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
        
    init(googleService: GoogleService) {
        self.googleService = googleService
        self.isRunning = false
        self.queue = OperationQueue()
    }
    
    func setupGoogle(_ completion: @escaping () -> Void) {
        googleService.setupGoogle {
            completion()
        }
    }
    
    func syncGoogleAccounts(completion: @escaping () -> Void) {
        guard !isRunning else {
            completion()
            return
        }
        
        isRunning = true
        completion()
    }
}
