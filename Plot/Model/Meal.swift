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
    var type: String?
    var amount: Double?
    var productContainer: [FoodProductContainer]?
    var nutrition: Nutrition?
    var participantsIDs: [String]?
    var lastModifiedDate: Date?
    var createdDate: Date?
    var startDateTime: Date?
    var endDateTime: Date?
    var admin: String?
    var badge: Int?
    var pinned: Bool?
    var muted: Bool?
    
    init(id: String, name: String, admin: String) {
        self.id = id
        self.name = name
        self.admin = admin
    }
}

struct BasicIngredient: Codable, Equatable, Hashable {
    var title: String
    var id: Int
}

func ==(lhs: Meal, rhs: Meal) -> Bool {
    return lhs.id == rhs.id
}
