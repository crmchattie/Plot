//
//  Filter.swift
//  Plot
//
//  Created by Cory McHattie on 1/30/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

enum filter: String {
    //recipes
    case cuisine, excludeCuisine, diet, intolerances, recipeType
    //ticketmaster
    case eventType, eventStartDate, eventEndDate, location
    //workouts
    case workoutType, muscles, duration, equipment, equipmentLevel
    //foursquare
    case fsOpenNow, fsPrice, fsFoodCategoryId, fsNightlifeCategoryId, fsSightseeingCategoryId, fsRecreationCategoryId, fsShoppingCategoryId
    
    var activity: String {
        switch self {
        case .cuisine: return "Recipes"
        case .excludeCuisine: return "Recipes"
        case .diet: return "Recipes"
        case .intolerances: return "Recipes"
        case .recipeType: return "Recipes"
        case .eventType: return "Events"
        case .eventStartDate: return "Events"
        case .eventEndDate: return "Events"
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
            
        }
    }
    
    var typeOfSection: String {
        switch self {
        case .cuisine: return "multiple"
        case .excludeCuisine: return "multiple"
        case .diet: return "single"
        case .intolerances: return "multiple"
        case .recipeType: return "single"
        case .eventType: return "single"
        case .eventStartDate: return "date"
        case .eventEndDate: return "date"
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
        }
    }
    
    var titleText: String {
        switch self {
        case .cuisine: return "Cuisines"
        case .excludeCuisine: return "Exclude Cuisines"
        case .diet: return "Diet"
        case .intolerances: return "Intolerances"
        case .recipeType: return "Type"
        case .eventType: return "Type"
        case .eventStartDate: return "Start Date"
        case .eventEndDate: return "End Date"
        case .location: return "Location"
        case .workoutType: return "Type"
        case .muscles: return "Muscles"
        case .duration: return "Duration"
        case .equipment: return "Equipment"
        case .equipmentLevel: return "Level of Equipment"
        case .fsOpenNow: return "Open Now"
        case .fsPrice: return "Price"
        case .fsFoodCategoryId, .fsNightlifeCategoryId, .fsSightseeingCategoryId, .fsRecreationCategoryId, .fsShoppingCategoryId: return "Category of Places"
        }
    }
    
    var descriptionText: String {
        switch self {
        case .cuisine: return "Choose one or more cuisines"
        case .excludeCuisine: return "Exclude one or more cuisines"
        case .diet: return "Choose a diet"
        case .intolerances: return "Exclude one or more intolerances"
        case .recipeType: return "Choose type of recipe"
        case .eventType: return "Choose type of event"
        case .eventStartDate: return "Filter events with a start date after this date"
        case .eventEndDate: return "Filter events with an end date before this date"
        case .location: return "Filter events via location"
        case .workoutType: return "Workout includes type e.g. has cardio component"
        case .muscles: return "Workout includes one or more muscles"
        case .duration: return "Duration of Workout"
        case .equipment: return "Filter based on equipment you want to use"
        case .equipmentLevel: return "Filter based on necessary level of equipment"
        case .fsOpenNow: return "Filter based on whether places are open now or not"
        case .fsPrice: return "Filter based on price"
        case .fsFoodCategoryId, .fsNightlifeCategoryId, .fsSightseeingCategoryId, .fsRecreationCategoryId, .fsShoppingCategoryId: return "Filter based on categories"

        }
    }
    
    var choices: [String] {
        switch self {
        case .cuisine: return ["African", "American", "British", "Cajun", "Caribbean", "Chinese", "European", "French", "German", "Greek", "Indian", "Irish", "Italian", "Japanese", "Jewish", "Korean", "Latin American", "Mediterranean", "Mexican", "Middle Eastern", "Nordic", "Southern", "Spanish", "Thai", "Vietnamese"]
        case .excludeCuisine: return ["African", "American", "British", "Cajun", "Caribbean", "Chinese", "European", "French", "German", "Greek", "Indian", "Irish", "Italian", "Japanese", "Jewish", "Korean", "Latin American", "Mediterranean", "Mexican", "Middle Eastern", "Nordic", "Southern", "Spanish", "Thai", "Vietnamese"]
        case .diet: return ["Gluten Free", "Ketogenic", "Vegetarian", "Lacto-Vegetarian", "Ovo-Vegetarian", "Vegan", "Pescetarian", "Paleo", "Whole"]
        case .intolerances: return ["Dairy", "Egg", "Gluten", "Grain", "Peanut", "Seafood", "Sesame", "Shellfish", "Soy", "Sulfite", "Tree Nut", "Wheat"]
        case .recipeType: return ["Main Course", "Side Dish", "Dessert", "Appetizer", "Salad", "Bread", "Breakfast", "Soup", "Beverage", "Sauce", "Marinade", "Fingerfood", "Snack", "Drink"]
        case .eventType: return ["Music", "Sports", "Arts & Theatre", "Family", "Film", "Miscellaneous"]
        case .eventStartDate: return []
        case .eventEndDate: return []
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
            //            case .exercise: return ["Medicine Ball Wall Throw", "Hip Circles", "Standing Dumbbell Bicep Hammer Curls", "Bird Dogs / Alternating Reach & Kickbacks", "Reclined Spinal Twist", "Kneeling Hip Flexor Stretch", "Swiss Ball Hand Off / V-Pass", "Corpse", "Samson Stretch / Lunge Stretch", "Seated Leg Curls", "Bosu Ball V-ups", "Reverse Crunch", "Standing Yoga Seal", "Dead Bug", "Dumbbell Overhead Shoulder Press", "Bosu Ball Plank Leg Lifts", "Dumbbell Cuban Press", "Battle Rope Reverse Lunges", "Extended Child's Pose", "TRX Suspension Straps Tricep Extensions", "Resistance Band Side Steps", "Hanging Knee Raises", "Assisted / Machine Seated Tricep Dips", "Medicine Ball Chest Pass", "Toe Taps", "Sumo Dumbbell Squats", "Donkey Kicks", "Single Straight Leg Dumbbell Deadlift", "Standing Overhead Military Barbell Shoulder Press", "Decline Push-ups / Pushups", "Fire Hydrants / Abductor / Adductor Knee Raises", "Crab Toe Touches", "TRX Suspension Straps Chest Press", "Standing Overhead Barbell Triceps Extensions", "Seated Tricep Press / Overhead Extensions", "Agility Ladder Drills", "Leg Pull-In Knee-ups", "Standing Long Jumps", "Decline Barbell Bench Press", "Seal Jacks", "Snap Jumps", "Overhead Triceps Stretch", "Walking High Kicks / Soldier March", "Bosu Ball Squats", "Wide-Grip Lat Pulldowns / Pull Downs / Pullovers", "Barbell Squats", "Bosu Ball Bridges Hip Raises / Glute Bridges", "Side Plank Leg Raises", "Hip Raises / Butt Lift / Bridges", "Dumbbell Squats", "Seated Bench Leg Pull-Ins / Flat Bench Knee-ups", "Standing Quadricep Stretch", "Standing Arm Circles", "Balancing Table", "Upward Cable Wood Chops", "Two-Arm Kettlebell Squat Swings", "Side Lateral Leg / Hip Swings", "Crescent Lunge", "Ab Roller / Wheel Rollout / Kneeling Roll Extensions", "Shadow Boxing", "Standing Dumbbell Bicep Curls", "Lying Leg Raises / Lifts", "Double Crunches", "Wide Stance / Sumo Barbell Squats", "Lying Side Leg Lifts / Lateral Raises / Hip Abductors / Adductors", "Yogic Breathing", "Side Plank", "Cable Core Rotation", "Battle Rope Double Waves", "Kettlebell Thruster / Squat to Clean to Overhead Press", "Body weight Shoulder Presses", "Seated Machine Leg Extensions", "Kettlebell One-Legged Deadlifts", "Downward Facing Dog", "Seated Dumbbell Concentration Curls", "Standing TRX Suspension Strap Ab Rollout", "TRX Suspension Strap Hamstring / Leg Curls", "Bicycles / Elbow-to-Knee Crunches / Cross-body Crunches", "Sprints", "Leg Press / Machine Squat Press", "Plow", "Cow Face", "Dumbbell Weighted Leg Pull-Ins", "Lunge Punches / Lunges", "180 / Twisting Jump Squats", "Headstand / Head stand", "Battle Rope Side-to-Side Swings", "Dumbbell Walking Lunges", "Barbell Curls / Standing Biceps Curls", "Stability / Swiss / Exercise Ball Dumbbell Shoulder Press", "Scorpion Stretch", "Alternating Bodyweight Lunges", "Bench Hops / Box Jumps", "Dumbbell Squat Thrusters / Squat to Overhead Press", "Standing Two-Armed Bent Over Dumbbell Rows", "Alternate Heel Touchers / Lying Oblique Reach", "Battle Rope Double Arm Slams", "Ragdoll / Forward Bend / Fold Stretch / Toe Touches", "Straight-Leg Calf Stretch", "Lunge / Front Kicks", "Barbell Pushups / Push-ups", "Pull-ups", "Resistance Band Bent Over Rows", "Side / Lateral Medicine Ball Throw / Slam", "Sumo Barbell Deadlift", "Jump Squats", "Plank Rolls / Planks", "Step Up with Knee Raises", "Barbell Hip Thrusts", "Bulgarian Split Squats", "Farmers Walk / Carry", "Hindu / Judo Push-up / Dive Bombers", "Medicine Ball V-Ups", "Butt Kicks", "Chair / Bench Tricep Dips", "Foam Roller Quadriceps Stretch", "Dumbbell Bent Over Lateral Rear Delt Raises / Flyes", "Dumbbell Bicep Reverse Curls", "Dumbbell Chops", "Body Weight Sumo / Wide Stance Squats", "Reverse Bench Crunches", "Bent Over Two-Armed Water Bottle Rows", "Single Leg Bench Bodyweight Squats", "Plank Flow", "Seated Dumbbell Bicep Curls", "Bent Over Barbell Rows", "Kettlebell Single Arm Clean and Press", "Rope Jumping / Jump rope / Skipping", "Mountain Climbers / Alternating Knee-ins", "Swaying Palm Tree", "Tree", "Sit-ups", "Resistance Band Shoulder Front Raises", "Kneeling T-Bar Presses/Landmine Presses", "Wide Arm Chest Stretch / Reverse Butterfly Stretch", "Shoulder Stretch", "Weighted Russian / Mason Twists", "High Knees / Front Knee Lifts / Run / Jog on the Spot", "Foam Roller Hamstring Stretch", "Dual / Two Arm Dumbbell Front Shoulder Raises", "Four Limbed Staff", "Barbell Split Squats", "Plank Shoulder Taps / Planks", "Dumbbell Floor Chest Press", "Kettlebell Deadlifts", "Lying Dumbbell Tricep Extensions", "Hanging Leg Raises", "Wall Angles", "Kettlebell Around the Worlds", "Fish", "Bodyweight Side Steps / Lateral Lunges", "Double Side Jackknifes", "Cross Body Mountain Climbers", "Medicine Ball Floor Press / Laying Chest Passes", "Resistance Band Glute Kickbacks", "Chair", "Diamond / Pyramid / Triceps Push-ups / Pushups", "TRX Suspension Strap T Flyes", "Bear Crawls", "Seated / Low Cable Back Rows", "Cable Squat Rows / Row Squats", "Mountain", "Upright Dumbbell Rows", "Static Squat Hold", "Weighted Glute Bridges", "Stability / Swiss / Exercise Ball Hamstring Leg Curl / Hip Raise / Bridge", "Single Leg Glute Bridge / Hip Extension with Leg Lift", "Foam Roller Lower Back Stretch", "Modified / Knee Push-ups / Pushups", "Static Bicep Curls", "Side / Oblique Crunches", "Bodyweight Calf Raises", "Half Monkey / Half Split", "Single-Arm Wall Push Ups / Push-Ups", "Knee Plank", "Upright Kettlebell Front Rows", "Striking Cobra", "Bent Over Double Arm Tricep Kickbacks", "Plate Overhead Walking Lunges", "Bodyweight Squats", "Weighted Pull-Ups / Pullups", "Cable Hammer Bicep Curls", "Palm Tree", "Seated Single Arm Overhead Dumbbell Tricep Extensions", "Tiger", "Single Leg Hops / Jumps", "Resistance Band Deadlifts", "Standing Cable Crossover Press / Flyes", "Foam Roller Upper Back Stretch", "Windshield Wipers", "Water Bottle Floor Chest Presses", "Side / Lateral Shuffles / Hops / Skaters", "Roundhouse / Side Kicks", "Your exercise (placeholder)", "Reverse Plank Kicks / Planks", "Exercise / Swiss Ball Bicep Curls", "Standing Half Forward Bend", "Barbell Push and Press", "Inchworms / Walkouts", "Cat Stretch", "Supermans / Extended Arms & Legs Lifts", "One-Arm Kettlebell Rows", "Chair Squats", "Tuck Jumps", "Dynamic Clap Push-ups / Pushups", "Resistance Band Squat and Overhead Press", "Dumbbell Snatch", "Side to Side Jump Squats", "Downward Cable Wood Chops", "Barbell Clean and Press / Jerk / Overhead Press", "Modified Side Planks", "Decline Bench Dumbbell Press", "Water Bottle Squat Clean and Presses", "Gluteus / Glute / Gluteal Stretch", "Battle Rope Snakes", "Jackknife Sit-up / Crunch / Toe Touches", "Front Barbell Squats", "TRX Suspension Strap Bicep Curls", "Stability / Swiss / Exercise Ball Crunches", "Single-Arm Front Water Bottle Raises", "TRX Suspension Strap Rows", "Stability / Swiss / Exercise Ball Knee Tuck to Chest", "Air Squats", "Captains Chair Leg / Knee / Hip Raises", "Alternate Nostril Breathing", "Pyramid", "Push-ups / Pushups", "Lunge Twists", "Burpees / Squat Thrusts", "Flutter Kicks", "Squats to Side Leg Raises/Lifts", "Standing Water Bottle Bicep Curls", "Surrenders", "Extended Cobra", "Standing Dumbbell Calf Raises", "Piriformis Stretch", "Plank Leg Lifts", "Barbell Box Squats", "Inverted Rows / Reverse Pull-ups", "Standing Dumbbell Overhead Shoulder Press", "Jumping Jacks / Star Jumps", "Hammer Strength Machine / Seated Chest Press", "Explosive Jumping Alternating Lunges", "Bosu Ball Leg Pull-in / Knee Tucks", "Flat Bench Dumbbell Flyes", "Fire Log", "One Arm Kettlebell Swings", "Tricep Cable Rope Push /Pull Downs", "Dumbbell Flat Bench Press", "Battle Rope Jumping Jacks", "Standing Forward Bend", "Bodyweight Walking Lunges", "Crunches", "Standing Reverse Barbell Curls", "Incline Dumbbell Bench Chest Press", "Dumbbell Biceps Curl to Shoulder Press", "Power Skips", "Stability / Swiss / Exercise Ball Dumbbell Chest Flyes", "Back Extensions / Hyperextensions", "Wind Release", "Plank Knee to Elbow", "Shoulder Pole / Broomstick Stretch", "Jumping Calf Press / Raises", "Close Grip Pullups / Chinups", "Stability / Swiss / Exercise Ball Squats", "Foam Roller Outer Thighs Stretch", "Decline Bench Crunches / Sit-ups", "Wall Push-Ups / Pushups / Standing Press Ups", "One-Arm Kettlebell Push and Press", "Bent Over Two-Arm Long Barbell / T-Bar Rows", "Seated Punches", "One-Arm Kettlebell Snatch", "Duck Walks / Squats", "Clamshells / Clams", "Foam Roller Calf / Calves Stretch", "Wall Sit / Squats / Chair", "Supine Lying Down Position / Corpse Pose", "Stability / Swiss / Exercise Ball Back Extensions", "Rack Pulls", "Triceps Dips", "High Box Jumps", "Lateral / Side Shoulder Dumbbell Raises / Power Partials", "Hollow Body Rock Hold", "Battle Rope Squatting Alternating Waves", "Butterfly Stretch", "Dumbbell Deadlifts", "Resistance Band Squats", "Standing Front Shoulder Plate / Dumbbell / Kettlebell Raises", "Weighted Bench Dips", "Forward Leg Hip Swings", "Dumbbell Lunges", "Plank", "Single Arm Medicine Ball Push-Ups / Pushups", "Turkish Get Ups", "Standing Cross-body Crunches", "Medicine Ball Slams", "Handstand Push-ups / Pushups", "Cobra Abdominal Stretch / Old Horse Stretch", "Front Kicks", "Standing Barbell Shoulder Press", "Dumbbell Side Lunges / Lateral Lunges", "Incline Push-ups / Pushups", "Lunging / Lunge with Bicep Hammer Curls", "Kettlebell Squats", "Leg Press Machine Calf Raises", "Medicine Ball Push-Ups", "Single Arm Dumbbell / Suitcase Carry", "Dumbbell Shrugs", "Barbell Bench Press / Chest Press", "Standing Rest / Water Break", "TRX Suspension Straps Atomic Push-ups / Pushups", "Frog Jumps", "Knee-to-Chest Lower Back Stretch", "Goblet Squats", "Hamstring Stretch", "Bosu Ball Push-ups / Pushups", "Dumbbell Squat Clean and Press", "Plank to Push-Up / Pushups / Walking Plank Up-Downs", "Camel", "Lateral Lunges to Floor Touch", "Russian / Mason / V-Sit Twists", "Smith Machine Squats", "Bench Flutter Kicks", "Standing Dumbbell / Kettlebell Side Bends", "Neck Stretch", "Dumbbell Step-Ups", "Barbell Deadlifts", "Alternating Curtsy Lunge", "Foam Roller Glutes / Butt Stretch", "Medicine Ball / Alternating Side Slams", "TRX Suspension Straps Side Step / Lateral Lunges", "Hex / Trap Bar / Cage Deadlifts / Squats", "Renegade / Alternating Plank / Commando Rows", "Cat Back / Backward Camel Stretch"]
            
        }
    }
    
}

