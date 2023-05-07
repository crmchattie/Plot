//
//  StepsGroupOperation.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-09-02.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

class StepsGroupOperation: AsyncOperation {
    private let queue: OperationQueue
    private var operations: [AsyncOperation] = []
    private var date: Date
    private var days: Int
    weak var delegate: MetricOperationDelegate?
    var annualAverageSteps: Double?
    
    init(date: Date, days: Int) {
        self.date = date
        self.days = days
        self.queue = OperationQueue()
    }
    
    override func main() {
        startFetchRequest()
    }
    
    private func startFetchRequest() {
        var nextDate = date
        // Loop from current date backward to total days
        for _ in 0..<days {
            let operation = StepsOperation(date: nextDate)
            operation.delegate = delegate
            operation.annualAverageSteps = annualAverageSteps
            queue.addOperation(operation)
            nextDate = nextDate.dayBefore
        }
        
        queue.addBarrierBlock { [weak self] in
            print("finish StepsGroupOperation")
            self?.finish()
        }
    }
}
