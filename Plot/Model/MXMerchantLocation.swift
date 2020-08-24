//
//  MXMerchantLocation.swift
//  Plot
//
//  Created by Cory McHattie on 8/23/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

struct MXMerchantLocationResult: Codable, Equatable {
    let merchantLocation: MXMerchantLocation?
    let merchantLocations: [MXMerchantLocation]?
}

struct MXMerchantLocation: Codable, Equatable {
    let city: String
    let country: String
    let guid: String
    let latitude: Double
    let longitude: Double
    let merchant_guid: String
    let phone_number: String
    let postal_code: String
    let state: String
    let store_number: String?
    let street_address: String
}

func ==(lhs: MXMerchantLocation, rhs: MXMerchantLocation) -> Bool {
    return lhs.guid == rhs.guid
}
