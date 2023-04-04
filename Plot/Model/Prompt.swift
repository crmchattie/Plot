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
        case .timeInsights, .timeRecs, .timePlan:
            contextObjects = networkController.activityService.activitiesWithRepeats
                .filter { activity -> Bool in
                    guard let date = activity.finalDateForDisplay?.localTime else { return false }
                    return startDate <= date && date <= endDate
                }
        case .healthInsights, .healthRecs, .healthPlan:
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
        case .financialInsights, .financialRecs, .financialPlan:
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
            
        case .transactionsInsights:
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
    case timeInsights = "Act as a time advisor. Could you give me insights into my time given the following: "
    case healthInsights = "Act as a health advisor. Could you give me insights into my health given the following: "
    case financialInsights = "Act as a financial advisor. Could you give me insights into my finances given the following: "
    case timeRecs = "Act as a time advisor. Could give me some recommendations to better manage my time given the following: "
    case healthRecs = "Act as a health advisor. Could give me some recommendations to better manage my health given the following: "
    case financialRecs = "Act as a financial advisor. Could give me some recommendations to better manage my finances given the following: "
    case timePlan = "Act as a time advisor. Could give me a plan to better manage my time given the following: "
    case healthPlan = "Act as a health advisor. Could give me a plan to better manage my health given the following: "
    case financialPlan = "Act as a financial advisor. Could give me a plan to better manage my finances given the following: "
    case transactionsInsights = "Act as a financial advisor. Could you give me insights into my spending given the following: "
    
    
    var question: String {
        return rawValue
    }
    
    var timeSegment: TimeSegmentType {
        switch self {
        case .timeInsights:
            return TimeSegmentType.week
        case .healthInsights:
            return TimeSegmentType.week
        case .financialInsights:
            return TimeSegmentType.month
        case .timeRecs:
            return TimeSegmentType.week
        case .healthRecs:
            return TimeSegmentType.week
        case .financialRecs:
            return TimeSegmentType.month
        case .timePlan:
            return TimeSegmentType.week
        case .healthPlan:
            return TimeSegmentType.week
        case .financialPlan:
            return TimeSegmentType.month
        case .transactionsInsights:
            return TimeSegmentType.month
        }
    }
}

let timeAdvisorString = "Act as a time advisor. "
let healthAdvisorString = "Act as a health advisor. "
let financeAdvisorString = "Act as a finance advisor. "
let insights = "Could you give me insights "
let recommendations = "Could give me some recommendations "
let plan = "Could give me a plan "



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
//"What are some productive hobbies I can start to make better use of my time?"
//"How can I find a good work-life balance to make the most of my time?"
//"What are some effective time management strategies I can adopt?"
//"How can I learn new skills and improve my knowledge in my free time?"
//"What are some effective ways to relax and de-stress?"
//"How can I use my free time to give back to my community?"
//"What are some ways to stay motivated and accountable when pursuing personal goals?"
//"How can I make better use of my commute time?"
//"What are some ways to reduce screen time and increase face-to-face interactions?"
//"How can I use my free time to enhance my personal relationships?"

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
//"Act as a health advisor. Act as a health advisor. Do you have any family history of health conditions that you are aware of?"
//"Act as a health advisor. What are some effective ways to manage stress?"
//"Act as a health advisor. How can I establish a healthy exercise routine?"
//"Act as a health advisor. What are some healthy eating habits to incorporate into my daily life?"
//"Act as a health advisor. What are some good sleep habits to improve my overall health?"
//"Act as a health advisor. How can I maintain a healthy work-life balance?"
//"Act as a health advisor. What are some effective ways to improve my mental health?"
//"Act as a health advisor. How can I stay motivated to exercise and maintain a healthy lifestyle?"
//"Act as a health advisor. What are some common mistakes to avoid when trying to improve my health?"
//"Act as a health advisor. How can I make healthy choices when eating out or traveling?"
//"Act as a health advisor. What are some alternative therapies or practices that can complement traditional medicine in promoting overall health and well-being?"

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
//"Act as a financial advisor. How can I create a budget that works for my lifestyle?"
//"Act as a financial advisor. What are some practical ways to save money on a daily basis?"
//"Act as a financial advisor. How can I pay off my debts efficiently?"
//"Act as a financial advisor. What are some good investment strategies for beginners?"
//"Act as a financial advisor. How can I improve my credit score?"
//"Act as a financial advisor. What are the best retirement planning options for me?"
//"Act as a financial advisor. How do I choose the right insurance policies to protect my financial future?"
//"Act as a financial advisor. How can I make the most of my employee benefits package?"
//"Act as a financial advisor. What are some common mistakes to avoid when managing my personal finances?"
//"Act as a financial advisor. How can I start planning for my financial goals and objectives?"



