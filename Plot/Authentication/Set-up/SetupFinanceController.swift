//
//  SetupFinanceController.swift
//  Plot
//
//  Created by Cory McHattie on 3/14/23.
//  Copyright © 2023 Immature Creations. All rights reserved.
//

import Foundation

class SetupFinanceController: SetupController {
    override func viewDidLoad() {
        customType = CustomType.finances
        NotificationCenter.default.addObserver(self, selector: #selector(nextButtonDidTap), name: .financeDataIsSetup, object: nil)
        footerTitle = "Finish"
        super.viewDidLoad()
    }
    
    override func nextButtonDidTap() {
        super.nextButtonDidTap()
        NotificationCenter.default.removeObserver(self)
        DispatchQueue.main.async {
            self.dismiss(animated: true) {
                self.dismiss(animated: true)
                self.networkController.setupInitialFinanceGoals()
            }
        }
    }
}
