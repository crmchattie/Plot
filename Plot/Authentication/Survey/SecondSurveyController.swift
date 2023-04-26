//
//  SecondSurveyController.swift
//  Plot
//
//  Created by Cory McHattie on 3/14/23.
//  Copyright © 2023 Immature Creations. All rights reserved.
//

import Foundation

class SecondSurveyController: SurveyController {
    override func nextButtonDidTap() {
        super.nextButtonDidTap()
        let destination = ThirdSurveyController(survey: Survey.goalsTime, surveyAnswers: surveyAnswers, networkController: networkController)
        navigationController?.pushViewController(destination, animated: true)
    }
}
