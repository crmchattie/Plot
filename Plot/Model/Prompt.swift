//
//  Prompt.swift
//  Plot
//
//  Created by Cory McHattie on 3/26/23.
//  Copyright © 2023 Immature Creations. All rights reserved.
//

import Foundation

let promptString = "prompt"

struct Prompt {
    var question: PromptQuestion
    var networkController: NetworkController
    var timeSegment: TimeSegmentType
    var contextObjects = [AnyHashable]()
    var prompt: String {
        return question.question + context
    }
    var context: String {
        var context = String()
        for object in contextObjects {
            if let item = object as? Activity {
                context += item.promptContext
            } else if let item = object as? HealthMetric {
                context += item.promptContext
            } else if let item = object as? Workout {
                context += item.promptContext
            } else if let item = object as? Mood {
                context += item.promptContext
            } else if let item = object as? Mindfulness {
                context += item.promptContext
            } else if let item = object as? TransactionDetails {
                context += item.promptContext(selectedIndex: timeSegment)
            } else if let item = object as? AccountDetails {
                context += item.promptContext(selectedIndex: timeSegment)
            } else if let item = object as? MXHolding {
                context += item.promptContext
            } else if let item = object as? Transaction {
                context += item.promptContext(accounts: networkController.financeService.accounts)
            } else if let item = object as? MXAccount {
                context += item.promptContext
            }
        }
        return context
    }
    
    init(question: PromptQuestion, networkController: NetworkController) {
        self.question = question
        self.networkController = networkController
        self.timeSegment = question.timeSegment
        
        var startDate = Date().localTime
        let endDate = Date().localTime
        switch question.timeSegment {
        case .day:
            startDate = startDate.startOfDay.dayBefore
        case .week:
            startDate = startDate.startOfDay.weekBefore
        case .month:
            startDate = startDate.startOfDay.monthBefore
        case .year:
            startDate = startDate.startOfDay.lastYear
        }
        switch question {
        case .summaryTime:
            contextObjects = networkController.activityService.activitiesWithRepeats
                .filter { activity -> Bool in
                    guard let date = activity.finalDateForDisplay?.localTime else { return false }
                    return startDate <= date && date <= endDate
                }
        case .summaryHealth:
            let filteredSamples = Array(networkController.healthService.healthMetrics.values.flatMap { $0 })
            .filter { metric -> Bool in
                    return startDate <= metric.date && metric.date <= endDate
                }
            contextObjects.append(contentsOf: filteredSamples)
            let filteredWorkouts = networkController.healthService.workouts
                .filter { workout -> Bool in
                    guard let date = workout.startDateTime?.localTime else { return false }
                    return startDate <= date && date <= endDate
                }.prefix(10)
            contextObjects.append(contentsOf: Array(filteredWorkouts))
            let filteredMinfulnesses = networkController.healthService.mindfulnesses
                .filter { mindfulness -> Bool in
                    guard let date = mindfulness.startDateTime?.localTime else { return false }
                    return startDate <= date && date <= endDate
                }.prefix(10)
            contextObjects.append(contentsOf: Array(filteredMinfulnesses))
            let filteredMoods = networkController.healthService.moods
                .filter { mood -> Bool in
                    guard let date = mood.moodDate?.localTime else { return false }
                    return startDate <= date && date <= endDate
                }.prefix(10)
            contextObjects.append(contentsOf: Array(filteredMoods))
        case .summaryFinances:
//            [.financialIssues, .incomeStatement, .balanceSheet, .transactions, .investments, .financialAccounts]
//                .values.flatMap({ $0 })
            let filteredObjects = networkController.financeService.financeGroups.filter({ $0.key == .incomeStatement || $0.key == .balanceSheet }).values.flatMap({ $0 })
            for object in filteredObjects {
                if let details = object as? TransactionDetails, details.level == TransactionCatLevel.group {
                    contextObjects.append(details)
                } else if let details = object as? AccountDetails, (details.level == AccountCatLevel.bs_type || details.level == AccountCatLevel.type) {
                    contextObjects.append(details)
                }
            }
            let filteredTransactions = networkController.financeService.transactions
                .filter { transaction -> Bool in
                    guard let date = transaction.transactionDate else { return false }
                    return startDate <= date && date <= endDate
                }.prefix(10)
            contextObjects.append(contentsOf: Array(filteredTransactions))
        }
    }
}

enum PromptQuestion: String {
    case summaryTime = "Act as a time advisor. Could you give me a summary of my time given the following: "
    case summaryHealth = "Act as a health advisor. Could you give me a summary of my health given the following: "
    case summaryFinances = "Act as a financial advisor. Could you give me a summary of my finances given the following: "
    
    var question: String {
        return rawValue
    }
    
    var timeSegment: TimeSegmentType {
        switch self {
        case .summaryTime:
            return TimeSegmentType.week
        case .summaryHealth:
            return TimeSegmentType.week
        case .summaryFinances:
            return TimeSegmentType.month
        }
    }
}



//time prompts
//"Schedule a meeting with [person's name] next week for [date and time]."
//"Remind me to call my doctor at [time] on [date]."
//"Add [task] to my to-do list for [day]."
//"What tasks do I have due this week?"
//"Schedule time for [activity] on my calendar for [day and time]."
//"Create a reminder for [event] two days before it happens."
//"Reschedule my meeting with [person's name] to [new date and time]."
//"What goals have I set for this month?"
//"Update my to-do list with [new task]."
//"What meetings do I have scheduled for today?"

//health prompts
//"Act as a health advisor. What are some health concerns or conditions you are currently experiencing or have experienced in the past?"
//"Act as a health advisor. Have you had any recent medical check-ups or tests done? If so, what were the results?"
//"Act as a health advisor. What is your current level of physical activity and exercise routine?"
//"Act as a health advisor. Do you have any dietary restrictions or preferences?"
//"Act as a health advisor. How many hours of sleep do you typically get per night, and do you feel well-rested upon waking?"
//"Act as a health advisor. Do you smoke or use any tobacco products, or have you in the past?"
//"Act as a health advisor. Are you currently taking any medications or supplements?"
//"Act as a health advisor. Have you experienced any recent changes in weight, energy levels, or mood?"
//"Act as a health advisor. What is your typical stress level, and do you have any strategies for managing stress?"
//"Act as a health advisor. Do you have any family history of health conditions that you are aware of?"

//finance prompts
//"Act as a financial advisor. What are some tips for creating and sticking to a budget?"
//"Act as a financial advisor. How can I improve my credit score?"
//"Act as a financial advisor. What are some strategies for paying off debt?"
//"Act as a financial advisor. How can I save more money each month?"
//"Act as a financial advisor. What are some common mistakes people make when investing?"
//"Act as a financial advisor. How can I prepare for retirement?"
//"Act as a financial advisor. What are some strategies for negotiating a salary or raise?"
//"Act as a financial advisor. How can I make sure I have enough money in case of an emergency?"
//"Act as a financial advisor. What should I consider when deciding whether to rent or buy a home?"
//"Act as a financial advisor. How can I balance saving for the future with enjoying my money in the present?"


