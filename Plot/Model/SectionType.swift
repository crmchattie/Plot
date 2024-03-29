//
//  Section.swift
//  Plot
//
//  Created by Cory McHattie on 7/3/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

enum SectionType: Hashable, CaseIterable {
    case custom
    case summaryPrompt
    case planPrompt
    case food
    case cheapEats
    case americanFood
    case asianFood
    case bakeryFood
    case breakfastFood
    case coffeeFood
    case dessertFood
    case fastFood
    case frenchFood
    case indianFood
    case italianFood
    case mexicanFood
    case middleeastFood
    case seafoodFood
    case vegetarianFood
    case comfortFood
    case spanishFood
    case nightlife
    case beachBar
    case beerBar
    case beerGarden
    case cocktailBar
    case diveBar
    case pub
    case karaokeBar
    case sportsBar
    case whiskeyBar
    case wineBar
    case brewery
    case club
    case events
    case sightseeing
    case museums
    case artGalleries
    case publicArt
    case historicalSites
    case memorialSites
    case sightseeingThemeParks
    case recreation
    case games
    case recreationThemeParks
    case active
    case parks
    case water
    case land
    case shopping
    case consumerables
    case clothes
    case generalShop
    case generalFood
    case generalDrinks
    case generalCoffee
    case generalArts
    case generalOutdoors
    case topShop
    case topFood
    case topDrinks
    case topSights
    case topRec
    case trending
    case workout
    case recipes
    case american
    case italian
    case vegetarian
    case mexican
    case breakfast
    case dessert
    case music
    case sports
    case artstheatre
    case family
    case film
    case miscellaneous
    case quick
    case hiit
    case cardio
    case yoga
    case medium
    case strength
    case search
    case event
    case incomeStatement
    case cashFlow
    case transactions
    case transactionCategories
    case transactionTopLevelCategories
    case transactionGroups
    case balanceSheet
    case balancesFinances
    case financialAccounts
    case financialIssues
    case customMeal
    case customWorkout
    case customTransaction
    case customTransactionRule
    case customFinancialAccount
    case ingredients
    case groceryItems
    case restaurantItems
    case calendar
    case time
    case health
    case finances
    case activitySummary
    case calendarSummary
    case calendarMix
    case cashFlowSummary
    case spendingMix
    case work
    case sleep
    case mood
    case mindfulness
    case investments
    case investment
    case task
    case tasks
    case lists
    case myLists
    case presetLists
    case templates
    case allTemplates
    case generalHealth
    case goals
    
    
    var name: String {
        switch self {
        case .custom: return "Create"
        case .summaryPrompt: return "Summary"
        case .planPrompt: return "Plan"
        case .food: return "Food"
        case .cheapEats: return "Cheap Eats"
        case .americanFood: return "American"
        case .asianFood: return "Asian"
        case .bakeryFood: return "Bakery"
        case .breakfastFood: return "Breakfast"
        case .coffeeFood: return "Coffee"
        case .dessertFood: return "Dessert"
        case .fastFood: return "Faster Food"
        case .frenchFood: return "French"
        case .indianFood: return "Indian"
        case .italianFood: return "Italian"
        case .mexicanFood: return "Mexican"
        case .middleeastFood: return "Middle Eastern"
        case .seafoodFood: return "Seafood"
        case .vegetarianFood: return "Vegetarian"
        case .comfortFood: return "Comfort"
        case .spanishFood: return "Spanish"
        case .nightlife: return "Nightlife"
        case .beachBar: return "Beach Bar"
        case .beerBar: return "Beer Bar"
        case .beerGarden: return "Beer Garden"
        case .cocktailBar: return "Cocktail Bar"
        case .diveBar: return "Dive Bar"
        case .pub: return "Pub"
        case .karaokeBar: return "Karaoke"
        case .sportsBar: return "Sports Bar"
        case .whiskeyBar: return "Whiskey Bar"
        case .wineBar: return "Wine Bar"
        case .brewery: return "Brewery"
        case .club: return "Club"
        case .events: return "Events"
        case .sightseeing: return "Sightseeing"
        case .museums: return "Museums"
        case .artGalleries: return "Art Galleries"
        case .publicArt: return "Public Art"
        case .historicalSites: return "Historical Sites"
        case .memorialSites: return "Memorial Sites"
        case .sightseeingThemeParks: return "Amusement Parks"
        case .recreationThemeParks: return "Amusement Parks"
        case .recreation: return "Recreation"
        case .games: return "Games"
        case .active: return "Active"
        case .parks: return "Parks"
        case .water: return "Water"
        case .land: return "Land"
        case .shopping: return "Shopping"
        case .clothes: return "Clothes"
        case .consumerables: return "Consumerables"
        case .generalShop: return "General"
        case .generalFood: return "General"
        case .generalDrinks: return "General"
        case .generalCoffee: return "Coffee"
        case .generalArts: return "General"
        case .generalOutdoors: return "General"
        case .topFood, .topShop, .topRec, .topDrinks, .topSights: return "Top Picks"
        case .trending: return "Trending"
        case .workout: return "Workouts"
        case .recipes: return "Recipes"
        case .american: return "American"
        case .italian: return "Italian"
        case .vegetarian: return "Vegetarian"
        case .mexican: return "Mexican"
        case .breakfast: return "Breakfast"
        case .dessert: return "Dessert"
        case .music: return "Music"
        case .sports: return "Sports"
        case .artstheatre: return "Arts & Theatre"
        case .family: return "Family"
        case .film: return "Film"
        case .miscellaneous: return "Miscellaneous"
        case .quick: return "Quick"
        case .hiit: return "HIIT"
        case .cardio: return "Cardio"
        case .yoga: return "Yoga"
        case .medium: return "Medium"
        case .strength: return "Strength"
        case .search: return "Search"
        case .event: return "Event"
        case .transactionCategories: return "Transactions - Subcategories"
        case .transactionTopLevelCategories: return "Transactions - Categories"
        case .transactionGroups: return "Transactions - Groups"
        case .incomeStatement: return "Income Statement"
        case .cashFlow: return "Cash Flow"
        case .transactions: return "Transactions"
        case .balanceSheet: return "Balance Sheet"
        case .balancesFinances: return "Balances"
        case .financialAccounts: return "Accounts"
        case .financialIssues: return "Issues"
        case .customMeal: return "Meal"
        case .customWorkout: return "Workout"
        case .customTransaction: return "Transaction"
        case .customFinancialAccount: return "Account"
        case .customTransactionRule: return "Transaction Rule"
        case .ingredients: return "Ingredients"
        case .groceryItems: return "Grocery Items"
        case .restaurantItems: return "Restaurant Items"
        case .calendar: return "Calendar"
        case .time: return "Time"
        case .health: return "Health"
        case .finances: return "Finances"
        case .activitySummary: return "Activity Summary"
        case .calendarSummary: return "Calendar Summary"
        case .calendarMix: return "Calendar Mix"
        case .cashFlowSummary: return "Cash Flow Summary"
        case .spendingMix: return "Spending Mix"
        case .work: return "Work Schedule"
        case .sleep: return "Sleep Schedule"
        case .mood: return "Moods"
        case .mindfulness: return "Mindfulness"
        case .investments: return "Investments"
        case .investment: return "Investment"
        case .task: return "Task"
        case .tasks: return "Tasks"
        case .lists: return "Lists"
        case .myLists: return "My Lists"
        case .presetLists: return "Preset Lists"
        case .generalHealth: return "General"
        case .templates: return "Templates Categories"
        case .allTemplates: return "All Templates"
        case .goals: return "Goals"
        }
    }
    
    var type: String {
        switch self {
        case .custom, .customMeal, .customWorkout, .customTransaction, .customFinancialAccount, .customTransactionRule, .sleep, .work, .mood, .mindfulness, .generalHealth, .summaryPrompt, .planPrompt: return "ActivityType"
        case .food, .cheapEats, .americanFood, .asianFood, .breakfastFood, .bakeryFood, .coffeeFood, .dessertFood, .fastFood, .frenchFood, .indianFood, .italianFood, .mexicanFood, .middleeastFood, .seafoodFood, .vegetarianFood, .comfortFood, .spanishFood, .nightlife, .beachBar, .beerBar, .beerGarden, .cocktailBar, .diveBar, .pub, .karaokeBar, .sportsBar, .whiskeyBar, .wineBar, .brewery, .club, .recreation, .games, .active, .shopping, .sightseeing, .museums, .artGalleries, .publicArt, .historicalSites, .memorialSites, .sightseeingThemeParks, .recreationThemeParks, .parks, .water, .land, .consumerables, .clothes, .generalShop, .generalFood, .generalDrinks, .generalCoffee, .generalArts, .generalOutdoors, .trending, .topFood, .topShop, .topRec, .topDrinks, .topSights: return "FSVenue"
        case .events, .music, .sports, .artstheatre, .family, .film, .miscellaneous: return "Event"
        case .workout, .quick, .hiit, .cardio, .yoga, .medium, .strength: return "Workout"
        case .recipes, .american, .italian, .vegetarian, .mexican, .breakfast, .dessert: return "Recipe"
        case .search: return "Search"
        case .event: return "Event"
        case .incomeStatement, .transactions, .transactionCategories, .transactionTopLevelCategories, .transactionGroups, .cashFlow: return "Transactions"
        case .balanceSheet, .financialAccounts, .balancesFinances: return "Accounts"
        case .financialIssues: return "Issues"
        case .ingredients, .groceryItems, .restaurantItems: return "Food Products"
        case .calendar: return "Set Up Calendar"
        case .time: return "Set Up Tasks and Calendar"
        case .health: return "Set Up Health"
        case .finances: return "Set Up Finances"
        case .activitySummary: return "Activity Summary"
        case .calendarSummary: return "Calendar Summary"
        case .calendarMix: return "Calendar Mix"
        case .cashFlowSummary: return "Financial Summary"
        case .spendingMix: return "Spending Summary"
        case .investments: return "Investments"
        case .investment: return "Investment"
        case .task: return "Task"
        case .tasks: return "Tasks"
        case .lists, .myLists, .presetLists: return "Set Up Lists"
        case .templates, .allTemplates: return "Templates"
        case .goals: return "Goals"
        }
    }
    
    var subType: String {
        switch self {
        case .custom, .customMeal, .customWorkout, .customTransaction, .customFinancialAccount, .customTransactionRule, .sleep, .work, .mood, .mindfulness, .summaryPrompt, .planPrompt: return "ActivityType"
        case .food, .cheapEats, .nightlife, .recreation, .shopping, .events, .music, .sports, .artstheatre, .family, .film, .miscellaneous, .sightseeing, .generalShop, .generalFood, .generalDrinks, .generalCoffee, .generalArts, .generalOutdoors, .trending,  .topFood, .topShop, .topRec, .topDrinks, .topSights, .clothes, .generalHealth: return "Recommend"
        case .americanFood, .asianFood, .breakfastFood, .bakeryFood, .coffeeFood, .dessertFood, .fastFood, .frenchFood, .indianFood, .italianFood, .mexicanFood, .middleeastFood, .seafoodFood, .vegetarianFood, .comfortFood, .spanishFood, .beachBar, .beerBar, .beerGarden, .cocktailBar, .diveBar, .pub, .karaokeBar, .sportsBar, .whiskeyBar, .wineBar, .brewery, .club, .games, .active, .museums, .artGalleries, .publicArt, .historicalSites, .memorialSites, .sightseeingThemeParks, .recreationThemeParks, .parks, .water, .land, .consumerables: return "Browse"
        case .workout, .hiit, .cardio, .yoga, .strength: return "Type"
        case .quick, .medium: return "Duration"
        case .recipes, .american, .italian, .mexican: return "Cuisine"
        case .breakfast, .dessert: return "Query"
        case .vegetarian: return "Diet"
        case .search: return "Search"
        case .event: return "Event"
        case .task: return "Task"
        case .tasks, .lists, .myLists, .presetLists: return "Set up Tasks by connecting to Apple Reminders or Google Tasks"
        case .transactionCategories: return "Categories"
        case .transactionTopLevelCategories: return "Tops"
        case .transactionGroups: return "Groups"
        case .incomeStatement: return "Income Statement"
        case .cashFlow: return "Cash Flow"
        case .transactions: return "Transactions"
        case .balanceSheet: return "Balance Sheet"
        case .balancesFinances: return "Balances"
        case .financialAccounts: return "Accounts"
        case .financialIssues: return "Issues"
        case .investments: return "Investments"
        case .investment: return "Investment"
        case .ingredients, .groceryItems, .restaurantItems: return "Food Products"
        case .calendar: return "Set up Calendar by connecting your Apple Calendar or Gmail Account"
        case .time: return "Set up Time by connecting your Apple or Gmail Account"
        case .health: return "Set up Health by connecting to the Apple Health App"
        case .finances: return "Set up Finances by connecting your existing financial accounts"
        case .goals: return "Set up Goals by creating a goal on the discover tab"
        case .activitySummary: return "Activity Summary"
        case .calendarSummary: return "Calendar Summary"
        case .calendarMix: return "Calendar Mix"
        case .cashFlowSummary: return "Financial Summary"
        case .spendingMix: return "Spending Summary"
        case .templates, .allTemplates: return "Templates"
        }
    }
    
    var extras: String {
        switch self {
        case .custom, .cheapEats, .events, .music, .sports, .artstheatre, .family, .film, .miscellaneous, .workout, .hiit, .cardio, .yoga, .strength, .quick, .medium, .recipes, .american, .italian, .mexican, .breakfast, .dessert, .vegetarian, .search, .americanFood, .asianFood, .breakfastFood, .bakeryFood, .coffeeFood, .dessertFood, .fastFood, .frenchFood, .indianFood, .italianFood, .mexicanFood, .middleeastFood, .vegetarianFood, .comfortFood, .spanishFood, .customMeal, .customWorkout, .ingredients, .groceryItems, .restaurantItems, .customTransaction, .customFinancialAccount, .customTransactionRule, .sleep, .work, .mood, .mindfulness, .task, .tasks, .lists, .myLists, .presetLists, .templates, .allTemplates, .generalHealth, .goals, .summaryPrompt, .planPrompt: return ""
        case .food, .seafoodFood, .beachBar, .beerBar, .beerGarden, .cocktailBar, .diveBar, .pub, .karaokeBar, .sportsBar, .whiskeyBar, .wineBar, .brewery, .club, .recreation, .games, .active, .sightseeingThemeParks, .recreationThemeParks, .shopping, .parks, .water, .land, .consumerables, .clothes, .museums, .artGalleries, .publicArt, .historicalSites, .memorialSites,  .topFood, .topShop, .topRec: return "topPicks"
        case .sightseeing, .topSights: return "sights"
        case .generalShop: return "shops"
        case .generalFood: return "food"
        case .generalDrinks, .topDrinks, .nightlife: return "drinks"
        case .generalCoffee: return "coffee"
        case .generalArts: return "arts"
        case .generalOutdoors: return "outdoors"
        case .trending: return "trending"
        case .event: return "event"
        case .incomeStatement, .transactions, .transactionCategories, .transactionTopLevelCategories, .transactionGroups, .balanceSheet, .financialAccounts, .cashFlow, .balancesFinances: return "finance"
        case .financialIssues: return "issues"
        case .time: return "time"
        case .calendar: return "calendar"
        case .health: return "health"
        case .finances: return "finances"
        case .activitySummary: return "activitySummary"
        case .calendarSummary: return "calendarSummary"
        case .calendarMix: return "calendarMix"
        case .cashFlowSummary: return "cashFlowSummary"
        case .spendingMix: return "spendingMix"
        case .investments: return "Investments"
        case .investment: return "Investment"
        }
    }
    
    var price: [Int] {
        switch self {
        case .custom, .events, .music, .sports, .artstheatre, .family, .film, .miscellaneous, .workout, .hiit, .cardio, .yoga, .strength, .quick, .medium, .recipes, .american, .italian, .mexican, .breakfast, .dessert, .vegetarian, .search, .americanFood, .asianFood, .breakfastFood, .bakeryFood, .coffeeFood, .dessertFood, .fastFood, .frenchFood, .indianFood, .italianFood, .mexicanFood, .middleeastFood, .vegetarianFood, .comfortFood, .spanishFood, .food, .seafoodFood, .nightlife, .beachBar, .beerBar, .beerGarden, .cocktailBar, .diveBar, .pub, .karaokeBar, .sportsBar, .whiskeyBar, .wineBar, .brewery, .club, .recreation, .games, .active, .sightseeingThemeParks, .recreationThemeParks, .shopping, .parks, .water, .land, .consumerables, .clothes, .museums, .artGalleries, .publicArt, .historicalSites, .memorialSites, .sightseeing, .generalShop, .generalFood, .generalDrinks, .generalCoffee, .generalArts, .generalOutdoors, .trending, .topFood, .topShop, .topRec, .topDrinks, .topSights, .event, .transactionCategories, .transactionTopLevelCategories, .transactionGroups, .transactions, .incomeStatement, .balanceSheet, .financialAccounts, .financialIssues, .customMeal, .customWorkout, .ingredients, .groceryItems, .restaurantItems, .customTransaction, .customFinancialAccount, .customTransactionRule, .calendar, .health, .finances, .activitySummary, .calendarMix, .cashFlowSummary, .spendingMix, .sleep, .work, .mood, .mindfulness, .calendarSummary, .investments, .investment, .task, .tasks, .lists, .time, .myLists, .presetLists, .generalHealth, .templates, .allTemplates, .balancesFinances, .cashFlow, .goals, .summaryPrompt, .planPrompt: return []
        case .cheapEats: return [1]
        }
    }
    
    var searchTerm: String {
        switch self {
        case .custom, .customMeal, .customWorkout, .ingredients, .groceryItems, .restaurantItems, .customTransaction, .customFinancialAccount, .customTransactionRule, .calendar, .health, .finances, .activitySummary, .calendarSummary, .calendarMix, .cashFlowSummary, .spendingMix, .sleep, .work, .mood, .mindfulness, .investments, .investment, .task, .tasks, .lists, .myLists, .time, .presetLists, .generalHealth, .templates, .allTemplates, .goals, .summaryPrompt, .planPrompt: return ""
        case .food, .topFood: return "4d4b7105d754a06374d81259"
        case .cheapEats: return "4d4b7105d754a06374d81259"
        case .americanFood: return "4bf58dd8d48988d14e941735"
        case .asianFood: return "4bf58dd8d48988d142941735"
        case .bakeryFood: return "4bf58dd8d48988d16a941735"
        case .breakfastFood: return "4bf58dd8d48988d143941735"
        case .coffeeFood: return "4bf58dd8d48988d1e0931735"
        case .dessertFood: return "4bf58dd8d48988d1d0941735"
        case .fastFood: return "4bf58dd8d48988d16e941735"
        case .frenchFood: return "4bf58dd8d48988d10c941735"
        case .indianFood: return "4bf58dd8d48988d10f941735"
        case .italianFood: return "4bf58dd8d48988d110941735"
        case .mexicanFood: return "4bf58dd8d48988d1c1941735"
        case .middleeastFood: return "4bf58dd8d48988d115941735"
        case .seafoodFood: return "4bf58dd8d48988d1ce941735"
        case .vegetarianFood: return "4bf58dd8d48988d1d3941735"
        case .comfortFood: return "4bf58dd8d48988d150941735"
        case .spanishFood: return "4bf58dd8d48988d14f941735"
        case .nightlife, .topDrinks: return "4d4b7105d754a06376d81259"
        case .beachBar: return "52e81612bcbc57f1066b7a0d"
        case .beerBar: return "56aa371ce4b08b9a8d57356c"
        case .beerGarden: return "4bf58dd8d48988d117941735"
        case .cocktailBar: return "4bf58dd8d48988d11e941735"
        case .diveBar: return "4bf58dd8d48988d118941735"
        case .pub: return "4bf58dd8d48988d11b941735"
        case .karaokeBar: return "4bf58dd8d48988d120941735"
        case .sportsBar: return "4bf58dd8d48988d11d941735"
        case .whiskeyBar: return "4bf58dd8d48988d122941735"
        case .wineBar: return "4bf58dd8d48988d123941735"
        case .brewery: return "50327c8591d4c4b30a586d5d"
        case .club: return "4bf58dd8d48988d11f941735"
        case .events: return "Events"
        case .sightseeing, .topSights: return "4d4b7104d754a06370d81259"
        case .museums: return "4bf58dd8d48988d181941735"
        case .artGalleries: return "4bf58dd8d48988d1e2931735"
        case .publicArt: return "507c8c4091d498d9fc8c67a9"
        case .historicalSites: return "4deefb944765f83613cdba6e,4bf58dd8d48988d15c941735,50aaa49e4b90af0d42d5de11,52e81612bcbc57f1066b7a14,4bf58dd8d48988d12d941735"
        case .memorialSites: return "5642206c498e4bfca532186c"
        case .sightseeingThemeParks: return "4bf58dd8d48988d182941735,4bf58dd8d48988d193941735,4bf58dd8d48988d17b941735,4fceea171983d5d06c3e9823"
        case .recreationThemeParks: return "4bf58dd8d48988d182941735,4bf58dd8d48988d193941735,4bf58dd8d48988d17b941735,4fceea171983d5d06c3e9823"
        case .recreation, .topRec: return "4d4b7105d754a06377d81259"
        case .games: return "4bf58dd8d48988d1e1931735,4bf58dd8d48988d1e4931735,52e81612bcbc57f1066b79e8,52e81612bcbc57f1066b79ea,52e81612bcbc57f1066b79e6,52e81612bcbc57f1066b79eb,4bf58dd8d48988d1e6941735,58daa1558bbb0b01f18ec1b0,4e39a956bd410d7aed40cbc3,4eb1bf013b7b6f98df247e07,52e81612bcbc57f1066b7a2d,4bf58dd8d48988d1e3931735"
        case .active: return "4f4528bc4b90abdf24c9de85"
        case .parks: return "52e81612bcbc57f1066b7a21, 4bf58dd8d48988d163941735,5bae9231bedf3950379f89d0,4bf58dd8d48988d159941735,56aa371be4b08b9a8d57355e,52e81612bcbc57f1066b7a22,4bf58dd8d48988d15a941735,4bf58dd8d48988d166941735,4bf58dd8d48988d1e4941735"
        case .water: return "56aa371be4b08b9a8d573544,4bf58dd8d48988d1e2941735,52e81612bcbc57f1066b7a12,52e81612bcbc57f1066b7a0f,4bf58dd8d48988d1e0941735,4bf58dd8d48988d160941735,50aaa4314b90af0d42d5de10,4bf58dd8d48988d161941735,4bf58dd8d48988d15d941735,4bf58dd8d48988d15e941735,56aa371be4b08b9a8d573541,4eb1d4dd4b900d56c88a45fd,56aa371be4b08b9a8d573560,56aa371be4b08b9a8d5734c3"
        case .land: return "4bf58dd8d48988d15b941735,4bf58dd8d48988d15f941735,52e81612bcbc57f1066b7a23,5bae9231bedf3950379f89cd,4eb1d4d54b900d56c88a45fc,52e81612bcbc57f1066b7a13,4bf58dd8d48988d165941735,4bf58dd8d48988d1e9941735,4bf58dd8d48988d1de941735,5032848691d4c4b30a586d61"
        case .shopping, .topShop: return "4d4b7105d754a06378d81259"
        case .clothes: return "4bf58dd8d48988d102951735,4bf58dd8d48988d104951735,4bf58dd8d48988d109951735,4bf58dd8d48988d106951735,4bf58dd8d48988d107951735,4bf58dd8d48988d108951735"
        case .consumerables: return "52f2ab2ebcbc57f1066b8b31,4bf58dd8d48988d117951735,4bf58dd8d48988d1f9941735,52f2ab2ebcbc57f1066b8b1c,52f2ab2ebcbc57f1066b8b2c,52f2ab2ebcbc57f1066b8b41"
        case .generalShop, .generalFood, .generalDrinks, .generalCoffee, .generalArts, .generalOutdoors, .trending: return ""
        case .recipes, .american: return "American"
        case .italian: return "Italian"
        case .vegetarian: return "Vegetarian"
        case .mexican: return "Mexican"
        case .breakfast: return "Breakfast"
        case .dessert: return "Dessert"
        case .music: return "Music"
        case .sports: return "Sports"
        case .artstheatre: return "Arts & Theatre"
        case .family: return "Family"
        case .film: return "Film"
        case .miscellaneous: return "Miscellaneous"
        case .quick: return "short"
        case .hiit: return "hiit"
        case .cardio: return "cardio"
        case .yoga: return "yoga"
        case .medium: return "medium"
        case .workout, .strength: return "work_out"
        case .search: return "Search"
        case .event: return "Event"
        case .transactionCategories, .transactionTopLevelCategories, .transactionGroups, .transactions, .incomeStatement, .balanceSheet, .financialAccounts, .cashFlow, .balancesFinances: return "Finance"
        case .financialIssues: return "Issues"
        }
    }
    
    var image: String {
        switch self {
        case .custom, .search, .ingredients, .groceryItems, .restaurantItems, .customTransaction, .customFinancialAccount, .customWorkout, .customMeal, .customTransactionRule, .activitySummary, .calendarMix, .calendarSummary, .cashFlowSummary, .spendingMix, .sleep, .work, .mood, .mindfulness, .investments, .investment, .generalHealth, .templates, .allTemplates, .summaryPrompt, .planPrompt: return ""
        case .food, .cheapEats, .americanFood, .asianFood, .breakfastFood, .bakeryFood, .coffeeFood, .dessertFood, .fastFood, .frenchFood, .indianFood, .italianFood, .mexicanFood, .middleeastFood, .seafoodFood, .vegetarianFood, .comfortFood, .spanishFood, .generalFood, .generalCoffee, .topFood: return "food"
        case .nightlife, .topDrinks, .club, .beachBar, .beerBar, .beerGarden, .cocktailBar, .diveBar, .pub, .karaokeBar, .sportsBar, .whiskeyBar, .wineBar, .brewery, .generalDrinks: return "nightlife"
        case .recreation, .topRec, .games, .recreationThemeParks, .active, .parks, .water, .land, .generalOutdoors: return "recreation"
        case .shopping, .topShop, .clothes, .consumerables, .generalShop: return "shopping"
        case .events, .music, .sports, .artstheatre, .family, .film, .miscellaneous: return "event"
        case .sightseeing, .topSights, .museums, .artGalleries, .publicArt, .historicalSites, .memorialSites, .sightseeingThemeParks, .generalArts: return "sightseeing"
        case .workout, .quick, .hiit, .cardio, .yoga, .medium, .strength: return "workout"
        case .recipes, .american, .italian, .vegetarian, .mexican, .breakfast, .dessert: return "recipe"
        case .trending: return "trending"
        case .event: return "event"
        case .transactionCategories, .transactionTopLevelCategories, .transactionGroups, .incomeStatement, .transactions, .balanceSheet, .financialAccounts, .cashFlow, .balancesFinances: return "finance"
        case .financialIssues: return "issues"
        case .calendar, .time: return "calendar"
        case .health: return "heart"
        case .finances: return "money"
        case .task: return "task"
        case .tasks: return "tasks"
        case .goals: return "goal"
        case .myLists, .lists, .presetLists: return "list"
        }
    }
}
