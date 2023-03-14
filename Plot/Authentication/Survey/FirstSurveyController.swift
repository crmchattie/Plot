//
//  FirstSurveyController.swift
//  Plot
//
//  Created by Cory McHattie on 3/14/23.
//  Copyright © 2023 Immature Creations. All rights reserved.
//

import Foundation

class FirstSurveyController: SurveyController {
    override func nextButtonDidTap() {
        super.nextButtonDidTap()
        let destination = SecondSurveyController(survey: Survey.goalsTime, networkController: networkController)
        navigationController?.pushViewController(destination, animated: true)
    }
}
