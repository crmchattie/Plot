//
//  MXMerchant.swift
//  Plot
//
//  Created by Cory McHattie on 8/23/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

struct MXMerchantResult: Codable {
    let merchant: MXMerchant?
    let merchants: [MXMerchant]?
    let pagination: MXPagination?
}

struct MXMerchant: Codable, Equatable {
    let created_at: String
    let guid: String
    let logo_url: String?
    let name: String
    let updated_at: String?
    let website_url: String?
}
