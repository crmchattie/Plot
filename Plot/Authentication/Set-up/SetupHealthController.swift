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
        NotificationCenter.default.addObserver(self, selector: #selector(nextButtonDidTap), name: .healthDataIsSetup, object: nil)
        super.viewDidLoad()
    }
    
    override func nextButtonDidTap() {
        super.nextButtonDidTap()
        DispatchQueue.main.async {
            print("nextButtonDidTap health")
            let destination = SetupFinanceController(networkController: self.networkController)
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
}
