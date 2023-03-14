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
        footerTitle = "Finish"
        super.viewDidLoad()
    }
    
    override func nextButtonDidTap() {
        super.nextButtonDidTap()
        self.dismiss(animated: true)
    }
}
