//
//  SetupTimeController.swift
//  Plot
//
//  Created by Cory McHattie on 3/14/23.
//  Copyright © 2023 Immature Creations. All rights reserved.
//

import Foundation

class SetupTimeController: SetupController {
    override func viewDidLoad() {
        customType = CustomType.time
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(nextButtonDidTap), name: .timeDataIsSetup, object: nil)
        super.viewDidAppear(false)
    }
    
    override func nextButtonDidTap() {
        super.nextButtonDidTap()
        NotificationCenter.default.removeObserver(self)
        DispatchQueue.main.async {
            print("nextButtonDidTap time")
            let destination = SetupHealthController(networkController: self.networkController)
            self.navigationController?.pushViewController(destination, animated: true)
            self.networkController.setupInitialTimeGoals()
        }
    }
}
