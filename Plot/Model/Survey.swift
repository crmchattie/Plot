//
//  Survey.swift
//  Plot
//
//  Created by Cory McHattie on 3/13/23.
//  Copyright © 2023 Immature Creations. All rights reserved.
//

import Foundation

enum Survey: String {
    case age, downloadPlot, hearAboutPlot, goalsTime, goalsHealth, goalsFinance
    
    var question: String {
        switch self {
        case .age:
            return "Age"
//        case .height:
//            return "Height"
//        case .weight:
//            return "Weight"
        case .hearAboutPlot:
            return "How did you hear about Plot?"
        case .goalsTime:
            return "What are your time goals?"
        case .goalsHealth:
            return "What are your health goals?"
        case .goalsFinance:
            return "What are your financial goals?"
        case .downloadPlot:
            return "Why are you interested in Plot?"
        }
    }
    
    var questionReason: String {
        switch self {
        case .age:
            return "We are asking so we can give you more accurate goals and scores"
//        case .height:
//            return "We are asking so we can calculate certain health metrics"
//        case .weight:
//            return "We are asking so we can calculate certain health metrics"
        case .hearAboutPlot:
            return "We are asking to better understand how people are learning about Plot"
        case .goalsTime:
            return "We are asking so we can give you better goals and insights in the future"
        case .goalsHealth:
            return "We are asking so we can give you better goals and insights in the future"
        case .goalsFinance:
            return "We are asking so we can give you better goals and insights in the future"
        case .downloadPlot:
            return "We are asking to better understand why people are interested in Plot"
        }
    }
    
    var choices: [String] {
        switch self {
        case .age:
            return ["Prefer not to say"]
//        case .height:
//            return ["Prefer not to say"]
//        case .weight:
//            return ["Prefer not to say"]
        case .hearAboutPlot:
            return ["Friends/Family", "Google Search", "News/Article/Blog", "Facebook/Instagram", "App Store", "Tik Tok", "Youtube", "Other"]
        case .goalsTime:
            return ["Be more productive", "Spend more time with family and friends", "Spend more time on yourself", "Learn a new skill", "Take up a hobby", "Volunteer"]
        case .goalsHealth:
            return ["Maintain healthy weight", "Eat a more balanced and nutritious diet", "Stay physically active", "Get more sleep", "Reduce stress"]
        case .goalsFinance:
            return ["Build and stick to a budget", "Save an emergency fund", "Pay off debt", "Save for retirement", "Save for a big purchase", "Improve credit score"]
        case .downloadPlot:
            return ["Be productive", "Improve Health", "Improve Finances"]
        }
    }
    
    var typeOfSection: TypeOfSection {
        switch self {
        case .age:
            return .date
        case .hearAboutPlot:
            return .single
        case .goalsTime:
            return .multiple
        case .goalsHealth:
            return .multiple
        case .goalsFinance:
            return .multiple
        case .downloadPlot:
            return .multiple
        }
    }
}
