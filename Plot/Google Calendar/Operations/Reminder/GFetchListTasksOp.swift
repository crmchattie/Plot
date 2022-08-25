//
//  GFetchCalendarEventsOp.swift
//  Plot
//
//  Created by Cory McHattie on 2/3/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation

class GFetchListTasksOp: AsyncOperation {
    private let googleCalService: GoogleCalService
    var listTasksDict: [GTLRTasks_TaskList: [GTLRTasks_Task]] = [:]
    
    init(googleCalService: GoogleCalService) {
        self.googleCalService = googleCalService
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        googleCalService.fetchTasks { listTasksDict in
            self.listTasksDict = listTasksDict
            self.finish()
        }
    }
}
