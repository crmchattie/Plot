//
//  SetupHealthController.swift
//  Plot
//
//  Created by Cory McHattie on 3/14/23.
//  Copyright © 2023 Immature Creations. All rights reserved.
//

import Foundation

class SetupHealthController: SetupController {
    override func viewDidLoad() {
        customType = CustomType.health
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(nextButtonDidTap), name: .healthDataIsSetup, object: nil)
        super.viewDidAppear(false)
    }
    
    override func nextButtonDidTap() {
        super.nextButtonDidTap()
        NotificationCenter.default.removeObserver(self)
        DispatchQueue.main.async {
            print("nextButtonDidTap health")
            let destination = SetupFinanceController(networkController: self.networkController)
            self.navigationController?.pushViewController(destination, animated: true)
            self.networkController.setupInitialHealthGoals()
        }
    }
}
