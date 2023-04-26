//
//  FifthSurveyController.swift
//  Plot
//
//  Created by Cory McHattie on 4/25/23.
//  Copyright © 2023 Immature Creations. All rights reserved.
//

import Foundation

class FifthSurveyController: SurveyController {
    override func nextButtonDidTap() {
        super.nextButtonDidTap()
        if networkController.isOldUser {
            self.dismiss(animated: true)
        } else {
            let destination = SetupTimeController(networkController: networkController)
            navigationController?.pushViewController(destination, animated: true)
        }
    }
}
