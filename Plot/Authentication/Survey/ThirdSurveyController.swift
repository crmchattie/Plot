//
//  ThirdSurveyController.swift
//  Plot
//
//  Created by Cory McHattie on 3/14/23.
//  Copyright © 2023 Immature Creations. All rights reserved.
//

import Foundation

class ThirdSurveyController: SurveyController {
    override func nextButtonDidTap() {
        super.nextButtonDidTap()
        let destination = FourthSurveyController(survey: Survey.goalsFinance, surveyAnswers: surveyAnswers, networkController: networkController)
        navigationController?.pushViewController(destination, animated: true)
    }
}
