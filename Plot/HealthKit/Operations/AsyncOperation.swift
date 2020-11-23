//
//  AsyncOperation.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-09-01.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

class AsyncOperation: Operation {
    
    // MARK: - Internal State
    
    private var _isExecuting: Bool = false
    private var _isFinished: Bool = false
    
    // MARK: - Operation Overrides
    open override func start() {
        isExecuting = true
        main()
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    override var isExecuting: Bool {
        get {
            return _isExecuting
        }
        set {
            let key = "isExecuting"
            willChangeValue(forKey: key)
            _isExecuting = newValue
            didChangeValue(forKey: key)
        }
    }
    
    override var isFinished: Bool {
        get {
            return _isFinished
        }
        set {
            let key = "isFinished"
            willChangeValue(forKey: key)
            _isFinished = newValue
            didChangeValue(forKey: key)
        }
    }
    
    // MARK: - Helper
    
    open func finish() {
        isExecuting = false
        isFinished = true
    }
}
