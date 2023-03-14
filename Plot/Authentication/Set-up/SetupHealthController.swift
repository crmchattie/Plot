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
    
    override func nextButtonDidTap() {
        super.nextButtonDidTap()
        let destination = SetupFinanceController(networkController: networkController)
        navigationController?.pushViewController(destination, animated: true)
    }
}
