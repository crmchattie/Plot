//
//  CustomType.swift
//  Plot
//
//  Created by Cory McHattie on 8/25/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import Foundation

enum CustomType: String, Equatable, Hashable {
    case event, task, lists, meal, workout, flight, transaction, financialAccount, transactionRule, sleep, work, mood, mindfulness, calendar, iOSCalendarEvent, googleCalendarEvent, iOSReminder, googleTask, investment, time, health, finances, healthTemplate, mealTemplate, workTemplate, schoolTemplate, socialTemplate, leisureTemplate, familyTemplate, personalTemplate, todoTemplate, financesTemplate
    
    var name: String {
        switch self {
        case .event: return "Event"
        case .task: return "Task"
        case .lists: return "List"
        case .meal: return "Meal"
        case .workout: return "Workout"
        case .flight: return "Flight"
        case .transaction: return "Transaction"
        case .financialAccount: return "Account"
        case .transactionRule: return "Transaction Rule"
        case .sleep: return "Sleep"
        case .work: return "Work"
        case .mood: return "Mood"
        case .iOSCalendarEvent: return "Apple Calendar Event"
        case .googleCalendarEvent: return "Google Calendar Event"
        case .iOSReminder: return "Apple Reminder"
        case .googleTask: return "Google Task"
        case .mindfulness: return "Mindfulness"
        case .calendar: return "Calendar"
        case .investment: return "Investment"
        case .time: return "Time"
        case .health: return "Health"
        case .finances: return "Finances"
        case .healthTemplate: return "Health"
        case .mealTemplate: return "Meal"
        case .workTemplate: return "Work"
        case .schoolTemplate: return "School"
        case .socialTemplate: return "Social"
        case .leisureTemplate: return "Leisure"
        case .familyTemplate: return "Family"
        case .personalTemplate: return "Personal"
        case .todoTemplate: return "To-do"
        case .financesTemplate: return "Finance"
        }
    }
    
    var categoryText: String {
        switch self {
        case .event: return "Build your own event"
        case .task: return "Build your own task list"
        case .lists: return "Build your own task"
        case .meal: return "Build your own meal"
        case .workout: return "Build your own workout"
        case .flight: return "Look up your flight"
        case .transaction: return "Create a transaction"
        case .financialAccount: return "Create a financial account"
        case .transactionRule: return "Create a transaction rule"
        case .sleep: return "Bedtime"
        case .work: return "Start of Work"
        case .mood: return "Add a mood"
        case .iOSCalendarEvent: return "Apple Calendar Event"
        case .googleCalendarEvent: return "Google Calendar Event"
        case .iOSReminder: return "Apple Reminder"
        case .googleTask: return "Google Task"
        case .mindfulness: return "Add mindfulness minutes"
        case .calendar: return "Add new calendar"
        case .investment: return "Add new investment"
        case .time: return "Set Up Tasks and Calendar"
        case .health: return "Set Up Health"
        case .finances: return "Set Up Finances"
        case .healthTemplate: return "Health"
        case .mealTemplate: return "Meal"
        case .workTemplate: return "Work"
        case .schoolTemplate: return "School"
        case .socialTemplate: return "Social"
        case .leisureTemplate: return "Leisure"
        case .familyTemplate: return "Family"
        case .personalTemplate: return "Personal"
        case .todoTemplate: return "To-do"
        case .financesTemplate: return "Finance"
        }
    }
    
    var subcategoryText: String {
        switch self {
        case .event: return "Includes basic event fields plus task, health and transaction fields"
        case .task: return "Includes basic event fields plus event, health and transaction fields"
        case .lists: return "Includes basic event fields plus a checklist, health and transaction fields"
        case .meal: return "Build a meal by looking up grocery products and/or restaurant menu items"
        case .workout: return "Build a workout by setting type, duration and intensity"
        case .flight: return "Look up your flight details based on flight number, airline or airport"
        case .sleep: return "Wake Up"
        case .work: return "End of Work"
        case .transaction, .financialAccount, .transactionRule, .mood, .iOSCalendarEvent, .mindfulness, .calendar, .googleCalendarEvent, .iOSReminder, .googleTask, .investment: return ""
        case .time: return "Set up Time by connecting your Apple or Gmail Account"
        case .health: return "Set up Health by connecting to the Apple Health App"
        case .finances: return "Set up Finances by connecting your existing financial accounts"
        case .healthTemplate: return "Health"
        case .mealTemplate: return "Meal"
        case .workTemplate: return "Work"
        case .schoolTemplate: return "School"
        case .socialTemplate: return "Social"
        case .leisureTemplate: return "Leisure"
        case .familyTemplate: return "Family"
        case .personalTemplate: return "Personal"
        case .todoTemplate: return "To-do"
        case .financesTemplate: return "Finance"
        }
    }
    
    var image: String {
        switch self {
        case .event: return "event"
        case .task: return "task"
        case .lists: return "list"
        case .meal: return "food"
        case .workout: return "workout"
        case .flight: return "plane"
        case .transaction: return "transaction"
        case .financialAccount: return "financialAccount"
        case .transactionRule: return "transactionRule"
        case .sleep: return "sleep"
        case .work: return "work"
        case .mood: return "mood"
        case .mindfulness: return "mindfulness"
        case .calendar: return "calendar"
        case .investment: return "investment"
        case .iOSCalendarEvent,.googleCalendarEvent, .iOSReminder, .googleTask: return ""
        case .time: return "calendar"
        case .health: return "heart"
        case .finances: return "money"
        case .healthTemplate: return "heart-filled"
        case .mealTemplate: return "food"
        case .workTemplate: return "work"
        case .schoolTemplate: return "school"
        case .socialTemplate: return "nightlife"
        case .leisureTemplate: return "leisure"
        case .familyTemplate: return "family"
        case .personalTemplate: return "personal"
        case .todoTemplate: return "todo"
        case .financesTemplate: return "money"
        }
    }
}
