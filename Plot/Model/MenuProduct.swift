//
//  MenuProduct.swift
//  Plot
//
//  Created by Cory McHattie on 10/26/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

// MARK: - MenuProduct
struct MenuProductSearch: Codable {
    let menuItems: [MenuProduct]?
    let totalMenuItems: Int?
    let type: String?
    let offset, number: Int?
}

// MARK: - MenuProduct
struct MenuProduct: Codable, Equatable, Hashable {
    let id: Int
    let title: String
    let restaurantChain: String?
    var nutrition: Nutrition?
    let badges: [String]?
    let breadcrumbs: [String]?
    let generatedText: String?
    let imageType: String?
    let likes: Int?
    let numberOfServings: Int?
    let readableServingSize, servingSize: String?
    let price: Double?
    let spoonacularScore: Int?
    let image: String?
    let amount: Double?
}

func ==(lhs: MenuProduct, rhs: MenuProduct) -> Bool {
    return lhs.id == rhs.id
}

