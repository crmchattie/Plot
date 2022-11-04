//
//  Filter.swift
//  Plot
//
//  Created by Cory McHattie on 1/30/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import HealthKit

enum filter: String {
    case search, startDate, endDate, date
    //recipes
    case cuisine, excludeCuisine, diet, intolerances, recipeType
    //ticketmaster
    case eventType, location
    //workouts
    case workoutType, muscles, duration, equipment, equipmentLevel
    //foursquare
    case fsOpenNow, fsPrice, fsFoodCategoryId, fsNightlifeCategoryId, fsSightseeingCategoryId, fsRecreationCategoryId, fsShoppingCategoryId
    //calendar
    case calendarView, calendarCategory
    //health
    case healthCategory, workoutCategory
    //finance
    case financeAccount, financeLevel, showPendingTransactions
    //task
    case taskCategory, showCompletedTasks, showRecurringTasks, taskSort
    
    var activity: String {
        switch self {
        case .search: return ""
        case .cuisine: return "Recipes"
        case .excludeCuisine: return "Recipes"
        case .diet: return "Recipes"
        case .intolerances: return "Recipes"
        case .recipeType: return "Recipes"
        case .eventType: return "Events"
        case .startDate: return ""
        case .endDate: return ""
        case .date: return ""
        case .location: return ""
        case .workoutType: return "Workouts"
        case .muscles: return "Workouts"
        case .duration: return "Workouts"
        case .equipment: return "Workouts"
        case .equipmentLevel: return "Workouts"
        case .fsOpenNow: return "Place"
        case .fsPrice: return "Place"
        case .fsFoodCategoryId: return "Place"
        case .fsNightlifeCategoryId: return "Place"
        case .fsSightseeingCategoryId: return "Place"
        case .fsRecreationCategoryId: return "Place"
        case .fsShoppingCategoryId: return "Place"
        case .calendarView: return "Calendar"
        case .calendarCategory: return "Calendar"
        case .healthCategory: return "Health"
        case .workoutCategory: return "Health"
        case .financeAccount: return "Finance"
        case .financeLevel: return "Finance"
        case .showPendingTransactions: return "Finance"
        case .taskCategory: return "Tasks"
        case .showCompletedTasks: return "Tasks"
        case .showRecurringTasks: return "Tasks"
        case .taskSort: return "Tasks"
        }
    }
    
    var typeOfSection: String {
        switch self {
        case .search: return "search"
        case .cuisine: return "multiple"
        case .excludeCuisine: return "multiple"
        case .diet: return "single"
        case .intolerances: return "multiple"
        case .recipeType: return "single"
        case .eventType: return "single"
        case .startDate: return "date"
        case .endDate: return "date"
        case .date: return "date"
        case .location: return "input"
        case .workoutType: return "single"
        case .muscles: return "multiple"
        case .duration: return "single"
        case .equipment: return "multiple"
        case .equipmentLevel: return "single"
        case .fsOpenNow: return "single"
        case .fsPrice: return "multiple"
        case .fsFoodCategoryId: return "multiple"
        case .fsNightlifeCategoryId: return "multiple"
        case .fsSightseeingCategoryId: return "multiple"
        case .fsRecreationCategoryId: return "multiple"
        case .fsShoppingCategoryId: return "multiple"
        case .calendarView: return "single"
        case .calendarCategory: return "multiple"
        case .healthCategory: return "multiple"
        case .workoutCategory: return "multiple"
        case .financeAccount: return "multiple"
        case .financeLevel: return "single"
        case .showPendingTransactions: return "single"
        case .taskCategory: return "multiple"
        case .showCompletedTasks: return "single"
        case .showRecurringTasks: return "single"
        case .taskSort: return "single"
        }
    }
    
    var titleText: String {
        switch self {
        case .search: return "Search"
        case .cuisine: return "Cuisines"
        case .excludeCuisine: return "Exclude Cuisines"
        case .diet: return "Diet"
        case .intolerances: return "Intolerances"
        case .recipeType: return "Type"
        case .eventType: return "Type"
        case .startDate: return "Start Date"
        case .endDate: return "End Date"
        case .date: return "End Date"
        case .location: return "Location"
        case .workoutType: return "Type"
        case .muscles: return "Muscles"
        case .duration: return "Duration"
        case .equipment: return "Equipment"
        case .equipmentLevel: return "Level of Equipment"
        case .fsOpenNow: return "Open Now"
        case .fsPrice: return "Price"
        case .fsFoodCategoryId, .fsNightlifeCategoryId, .fsSightseeingCategoryId, .fsRecreationCategoryId, .fsShoppingCategoryId: return "Category of Places"
        case .calendarView: return "View"
        case .calendarCategory: return "Categories"
        case .healthCategory: return "Categories"
        case .workoutCategory: return "Categories"
        case .financeAccount: return "Accounts"
        case .financeLevel: return "Level"
        case .showPendingTransactions: return "Show"
        case .taskCategory: return "Categories"
        case .showCompletedTasks: return "Show"
        case .showRecurringTasks: return "Show"
        case .taskSort: return "Sort"
        }
    }
    
    var descriptionText: String {
        switch self {
        case .search: return ""
        case .cuisine: return "Choose one or more cuisines"
        case .excludeCuisine: return "Exclude one or more cuisines"
        case .diet: return "Choose a diet"
        case .intolerances: return "Exclude one or more intolerances"
        case .recipeType: return "Choose type of recipe"
        case .eventType: return "Choose type of event"
        case .startDate: return "Filter with a start date after this date"
        case .endDate: return "Filter with an end date before this date"
        case .date: return "Filter based on this date"
        case .location: return "Filter events via location"
        case .workoutType: return "Workout includes type e.g. has cardio component"
        case .muscles: return "Workout includes one or more muscles"
        case .duration: return "Duration of Workout"
        case .equipment: return "Filter based on equipment you want to use"
        case .equipmentLevel: return "Filter based on necessary level of equipment"
        case .fsOpenNow: return "Filter based on whether places are open now or not"
        case .fsPrice: return "Filter based on price"
        case .fsFoodCategoryId, .fsNightlifeCategoryId, .fsSightseeingCategoryId, .fsRecreationCategoryId, .fsShoppingCategoryId: return "Filter based on categories"
        case .calendarView: return "Update view of calendar"
        case .calendarCategory: return "Filter based on categories"
        case .healthCategory: return "Filter based on categories"
        case .workoutCategory: return "Filter based on workout categories"
        case .financeAccount: return "Filter based on account(s) included"
        case .financeLevel: return "Filter cash flow/balances sections based on level of detail shown"
        case .showPendingTransactions: return "Show Pending Transactions or Not"
        case .taskCategory: return "Filter based on categories"
        case .showCompletedTasks: return "Show Completed Tasks or Not"
        case .showRecurringTasks: return "Show Recurring Tasks or Not"
        case .taskSort: return "Sort Tasks"
        }
    }
    
    var choices: [String] {
        switch self {
        case .search: return []
        case .cuisine: return ["African", "American", "British", "Cajun", "Caribbean", "Chinese", "European", "French", "German", "Greek", "Indian", "Irish", "Italian", "Japanese", "Jewish", "Korean", "Latin American", "Mediterranean", "Mexican", "Middle Eastern", "Nordic", "Southern", "Spanish", "Thai", "Vietnamese"]
        case .excludeCuisine: return ["African", "American", "British", "Cajun", "Caribbean", "Chinese", "European", "French", "German", "Greek", "Indian", "Irish", "Italian", "Japanese", "Jewish", "Korean", "Latin American", "Mediterranean", "Mexican", "Middle Eastern", "Nordic", "Southern", "Spanish", "Thai", "Vietnamese"]
        case .diet: return ["Gluten Free", "Ketogenic", "Vegetarian", "Lacto-Vegetarian", "Ovo-Vegetarian", "Vegan", "Pescetarian", "Paleo", "Whole"]
        case .intolerances: return ["Dairy", "Egg", "Gluten", "Grain", "Peanut", "Seafood", "Sesame", "Shellfish", "Soy", "Sulfite", "Tree Nut", "Wheat"]
        case .recipeType: return ["Main Course", "Side Dish", "Dessert", "Appetizer", "Salad", "Bread", "Breakfast", "Soup", "Beverage", "Sauce", "Marinade", "Fingerfood", "Snack", "Drink"]
        case .eventType: return ["Music", "Sports", "Arts & Theatre", "Family", "Film", "Miscellaneous"]
        case .startDate: return []
        case .endDate: return []
        case .date: return []
        case .location: return []
        case .workoutType: return ["Yoga", "Stretch", "Cardio", "Strength", "HIIT"]
        case .muscles: return ["Biceps", "Knees", "Lower Back", "Shoulders", "Calves", "Middle Back / Lats", "Spine", "Chest", "Glutes & Hip Flexors", "Quadriceps", "Upper Back & Lower Traps", "Hamstrings", "Abs", "Triceps", "Ankles", "Forearms", "Obliques", "Neck & Upper Traps"]
        case .duration: return ["Short", "Medium", "Long"]
        case .equipment: return ["Dumbbells", "Kettlebells", "Barbell", "Dip Station", "Squat Rack", "Bench", "pull-up bar", "TRX", "pulley machine", "Cable Station", "Hex / Trap Bar / Cage", "Stability / Swiss / Exercise Ball", "Medicine Ball", "Cross Trainer / Crosstrainer Machine", "Box", "Hyper Extension Bench", "Jump Rope", "Captains Chair", "T-bar", "Leg Press Machine", "Leg Extension Machine", "Battle Rope", "Bosu Ball", "Ab Roller", "Leg Curl Machine", "Hammer Strength Machine", "Chair", "Water Bottle", "Plate", "Platform", "Power Rack", "Bike", "Rowing Machine", "Elliptical Machine", "Resistance Bands", "Foam Roller", "Smith Machine", "Tricep Dip Machine"]
        case .equipmentLevel: return ["None", "Minimal", "Full-gym"]
        case .fsOpenNow: return ["Yes", "No"]
        case .fsPrice: return ["$", "$$", "$$$", "$$$$"]
        case .fsFoodCategoryId: return ["Afghan Restaurant", "Ethiopian Restaurant", "African Restaurant", "American Restaurant", "Burmese Restaurant", "Cambodian Restaurant", "Chinese Restaurant", "Filipino Restaurant", "Himalayan Restaurant", "Hotpot Restaurant", "Indonesian Restaurant", "Japanese Restaurant", "Korean Restaurant", "Malay Restaurant", "Mongolian Restaurant", "Noodle House", "Satay Restaurant", "Thai Restaurant", "Tibetan Restaurant", "Vietnamese Restaurant", "Asian Restaurant", "Australian Restaurant", "Austrian Restaurant", "BBQ Joint", "Bagel Shop", "Bakery", "Bangladeshi Restaurant", "Belgian Restaurant", "Bistro", "Breakfast Spot", "Bubble Tea Shop", "Buffet", "Burger Joint", "Cafeteria", "Cafe", "Cajun / Creole Restaurant", "Cuban Restaurant", "Caribbean Restaurant", "Caucasian Restaurant", "Coffee Shop", "Comfort Food Restaurant", "Creperie", "Czech Restaurant", "Deli / Bodega", "Cupcake Shop", "Frozen Yogurt Shop", "Ice Cream Shop", "Pastry Shop", "Pie Shop", "Dessert Shop", "Diner", "Donut Shop", "Dumpling Restaurant", "Dutch Restaurant", "Eastern European Restaurant", "English Restaurant", "Falafel Restaurant", "Fast Food Restaurant", "Fish & Chips Shop", "Fondue Restaurant", "Food Court", "Food Stand", "Food Truck", "French Restaurant", "Fried Chicken Joint", "Friterie", "Gastropub", "German Restaurant", "Gluten-free Restaurant", "Greek Restaurant", "Halal Restaurant", "Poke Place", "Hawaiian Restaurant", "Hot Dog Joint", "Hungarian Restaurant", "Indian Restaurant", "Irish Pub", "Italian Restaurant", "Jewish Restaurant", "Juice Bar", "Kebab Restaurant", "Latin American Restaurant", "Mac & Cheese Joint", "Mediterranean Restaurant", "Mexican Restaurant", "Middle Eastern Restaurant", "Modern European Restaurant", "Molecular Gastronomy Restaurant", "Pakistani Restaurant", "Pet Cafe", "Pizza Place", "Polish Restaurant", "Portuguese Restaurant", "Poutine Place", "Russian Restaurant", "Salad Place", "Sandwich Place", "Scandinavian Restaurant", "Scottish Restaurant", "Seafood Restaurant", "Slovak Restaurant", "Snack Place", "Soup Place", "Southern / Soul Food Restaurant", "Spanish Restaurant", "Sri Lankan Restaurant", "Steakhouse", "Swiss Restaurant", "Tea Room", "Theme Restaurant", "Truck Stop", "Turkish Restaurant", "Ukrainian Restaurant", "Vegetarian / Vegan Restaurant", "Wings Joint"]
        case .fsNightlifeCategoryId: return ["Beach Bar", "Beer Bar", "Beer Garden", "Champagne Bar", "Cocktail Bar", "Dive Bar", "Hotel Bar", "Karaoke Bar", "Pub", "Sake Bar", "Speakeasy", "Sports Bar", "Tiki Bar", "Whiskey Bar", "Wine Bar", "Brewery", "Lounge", "Night Market", "Nightclub"]
        case .fsSightseeingCategoryId: return ["Amphitheater", "Aquarium", "Art Gallery", "Concert Hall", "Exhibit", "Historic Site", "Memorial Site", "Art Museum", "History Museum", "Planetarium", "Science Museum", "Performing Arts Venue", "Outdoor Sculpture", "Street Art", "Stadium", "Theme Park", "Water Park", "Zoo"]
        case .fsRecreationCategoryId: return ["Aquarium", "Arcade", "Badminton Court", "Baseball Field", "Basketball Court", "Curling Ice", "Golf Course", "Golf Driving Range", "Boxing Gym", "Climbing Gym", "Cycle Studio", "Gymnastics Gym", "Martial Arts Dojo", "Outdoor Gym", "Pilates Studio", "Track", "Yoga Studio", "Hockey Field", "Hockey Rink", "Paintball Field", "Rugby Pitch", "Skate Park", "Skating Rink", "Soccer Field", "Sports Club", "Squash Court", "Tennis Court", "Volleyball Court", "Bay", "Beach", "Bike Trail", "Botanical Garden", "Castle", "Cave", "Cemetery", "Dive Spot", "Dog Run", "Farm", "Field", "Fishing Spot", "Forest", "Fountain", "Garden", "Gun Range", "Harbor / Marina", "Hill", "Hot Spring", "Indoor Play Area", "Island", "Lake", "Lighthouse", "Mountain", "National Park", "Nature Preserve", "Palace", "Park", "Playground", "Pool", "Rafting", "Recreation Center", "Reservoir", "River", "Rock Climbing Spot", "Scenic Lookout", "Sculpture Garden", "Ski Area", "Stables", "State / Provincial Park", "Summer Camp", "Trail", "Tree", "Vineyard", "Volcano", "Waterfall", "Waterfront", "Windmill", "Campground", "Bowling Alley", "Disc Golf", "Go Kart Track", "Laser Tag", "Mini Golf", "Pool Hall", "Theme Park", "Water Park", "Zoo"]
        case .fsShoppingCategoryId: return ["ATM", "Antique Shop", "Arts & Crafts Store", "Bank", "Big Box Store", "Bike Shop", "Bookstore", "Camera Store", "Candy Store", "Chocolate Shop", "Clothing Accessories Store", "Clothing Boutique", "Clothing - Kids Store", "Clothing - Men's Store", "Shoe Store", "Clothing - Women's Store", "Convenience Store", "Cosmetics Shop", "Currency Exchange", "Department Store", "Drugstore", "Electronics Store", "Fireworks Store", "Fishing Store", "Flea Market", "Floating Market", "Flower Shop", "Beer Store", "Butcher", "Cheese Shop", "Coffee Roaster", "Dairy Store", "Farmers Market", "Fish Market", "Food Service", "Gourmet Shop", "Grocery Store", "Health Food Store", "Herbs & Spices Store", "Liquor Store", "Organic Grocery", "Sausage Shop", "Street Food Gathering", "Supermarket", "Wine Shop", "Fruit & Vegetable Store", "Furniture / Home Store", "Garden Center", "Gas Station", "Gift Shop", "Hardware Store", "Health & Beauty Service", "Internet Cafe", "Jewelry Store", "Leather Goods Store", "Luggage Store", "Market", "Nail Salon", "Outlet Mall", "Outlet Store", "Pharmacy", "Pop-Up Shop", "Public Bathroom", "Record Shop", "Salon / Barbershop", "Shipping Store", "Shopping Mall", "Shopping Plaza", "Skate Shop", "Ski Shop", "Spa", "Sporting Goods Shop", "Thrift / Vintage Store", "Toy / Game Store", "Used Bookstore", "Watch Shop"]
        case .calendarView: return ["List", "Daily"]
        case .calendarCategory: return []
        case .healthCategory: return []
        case .workoutCategory:
            if #available(iOS 16.0, *) {
                return HKWorkoutActivityType.allCases.map({$0.name})
            } else if #available(iOS 14.0, *) {
                return HKWorkoutActivityType.oldAllCases.map({$0.name})
            } else {
                return HKWorkoutActivityType.oldOldAllCases.map({$0.name})
            }
        case .taskCategory: return []
        case .showCompletedTasks: return ["Yes", "No"]
        case .showRecurringTasks: return ["Yes", "No"]
        case .financeAccount: return []
        case .financeLevel: return ["All", "Top"]
        case .showPendingTransactions: return ["Yes", "No"]
        case .taskSort: return ["Due Date", "Priority", "Title"]
        }
    }
    
}

