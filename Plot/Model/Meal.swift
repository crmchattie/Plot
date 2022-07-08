//
//  Meal.swift
//  Plot
//
//  Created by Cory McHattie on 10/26/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

let mealsEntity = "meals"
let userMealsEntity = "user-meals"

struct Meal: Codable, Equatable, Hashable {
    var id: String
    var name: String
    var admin: String?
    var type: String?
    var amount: Double?
    var productContainer: [FoodProductContainer]?
    var nutrition: Nutrition?
    var participantsIDs: [String]?
    var lastModifiedDate: Date?
    var createdDate: Date?
    var startDateTime: Date?
    var endDateTime: Date?
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?
    var transactionID: String?
    var activityID: String?
    var healthExport: Bool?
    var user_created: Bool?

}

struct BasicIngredient: Codable, Equatable, Hashable {
    var title: String
    var id: Int
}

func ==(lhs: Meal, rhs: Meal) -> Bool {
    return lhs.id == rhs.id
}
