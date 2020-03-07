//
//  TicketMasterSearchResult.swift
//  Plot
//
//  Created by Cory McHattie on 1/11/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

struct TicketMasterSearchResult: Codable {
    let _embedded: [String: [Event]]
    let page: PageResult

    enum CodingKeys: String, CodingKey {
        case _embedded
        case page
    }
}

struct PageResult: Codable {
    let size, totalElements, totalPages, number: Int?
}

struct Event: Codable {
    let id: String
    let type: String
    let name: String
    let url: String
    let locale: String
    let images: [EventImage]
    let sales: EventSales
    let dates: EventDates
    let classifications: [EventClassification]
    let priceRanges: [EventPriceRange]?
    let _links: EventLinks
    let _embedded: [String : [VenueDetails]]
}

struct EventImage: Codable {
    let ratio: String?
    let url: String
    let width, height: Int
    let fallback: Bool
}

struct EventSales: Codable {
    let `public`: EventPublicType
    let presales: [EventPresale]?
}

struct EventPublicType: Codable {
    let startDateTime: String?
    let endDateTime: String?
    let startTBD: Bool?
}

struct EventPresale: Codable {
    let startDateTime: String
    let endDateTime: String
    let name: String
}

struct EventDates: Codable {
    let start: EventStartTime
    let timezone: String?
    let status: [String: String]
    let spanMultipleDays: Bool
}

struct EventStartTime: Codable {
    let localDate: String?
    let localTime: String?
    let dateTime: String?
    let dateTBD: Bool
    let dateTBA: Bool
    let timeTBA: Bool
    let noSpecificTime: Bool
}

struct EventClassification: Codable {
    let primary: Bool
    let segment: [String: String]
    let genre: [String: String]
    let subGenre: [String: String]
    let type: [String: String]?
    let subType: [String: String]?
    let family: Bool

}

struct EventPriceRange: Codable {
    let type: String
    let currency: String
    let min, max: Double
}

struct EventLinks: Codable {
    let `self`: [String: String]
    let attractions: [[String: String]]
    let venues: [[String: String]]
}

struct VenueDetails: Codable {
    let name: String
    let type: String
    let id: String
    let url: String?
    let images: [EventImage]?
    let locale: String?
    let postalCode: String?
    let timezone: String?
    let city: [String: String]?
    let state: [String: String]?
    let country: [String: String]?
    let address: [String: String]?
    let location: [String: String]?
}




