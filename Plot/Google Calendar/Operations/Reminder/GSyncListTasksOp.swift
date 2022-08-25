//
//  GSyncCalendarEventsOp.swift
//  Plot
//
//  Created by Cory McHattie on 2/3/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation

class GSyncListTasksOp: AsyncOperation {
    
    private let queue: OperationQueue
    private var operations: [AsyncOperation] = []
    var listTasksDict: [GTLRTasks_TaskList: [GTLRTasks_Task]] = [:]
    var existingTasks: [GTLRTasks_Task] = []
    var existingActivities: [Activity] = []
    
    init(existingActivities: [Activity]) {
        self.queue = OperationQueue()
        self.existingActivities = existingActivities
    }
    
    override func main() {
        startRequest()
    }
    
    private func startRequest() {
        for (list, tasks) in listTasksDict {
            for task in tasks {
                let op = GListTaskOp(list: list, task: task)
                queue.addOperation(op)
            }
        }
        
        queue.addBarrierBlock { [weak self] in
            self?.finish()
        }
    }
}
