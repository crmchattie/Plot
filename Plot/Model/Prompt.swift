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
    var prompt: String {
        return question + context
    }
    var question: String
    var context: String {
        var context = String()
        for object in contextObjects {
            if let item = object as? Activity {
                
            } else if let item = object as? HealthMetric {
                
            } else if let item = object as? Workout {
                
            } else if let item = object as? Mood {
                
            } else if let item = object as? Mindfulness {
                
            } else if let item = object as? TransactionDetails {
                
            } else if let item = object as? AccountDetails {
                
            } else if let item = object as? MXHolding {
                
            } else if let item = object as? Transaction {
                
            } else if let item = object as? MXAccount {
                
            }
        }
        return context
    }
    var contextObjects: [AnyHashable]
}

//time prompts
let summaryTime = "Act as a time advisor. Could you give me a summary of my time given the following:"
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
let summaryHealth = "Act as a health advisor. Could you give me a summary of my health given the following:"
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
let summaryFinances = "Act as a financial advisor. Could you give me a summary of my finances given the following:"
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


