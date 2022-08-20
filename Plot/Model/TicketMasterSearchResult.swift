//
//  TicketMasterSearchResult.swift
//  Plot
//
//  Created by Cory McHattie on 1/11/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

struct TicketMasterSearchResult: Codable, Equatable, Hashable {
    let embedded: Embedded?
    let links: WelcomeLinks?
    let page: Page?
    
    enum CodingKeys: String, CodingKey {
        case embedded = "_embedded"
        case links = "_links"
        case page
    }
}

// MARK: - Embedded
struct Embedded: Codable, Equatable, Hashable {
    let events: [TicketMasterEvent]?
    let attractions: [TicketMasterAttraction]?
}

// MARK: - Event
struct TicketMasterEvent: Codable, Equatable, Hashable {
    let uuid = UUID().uuidString
    var name: String
    let type: EventType?
    let id: String
    let test: Bool?
    let url: String?
    let local: String?
    let images: [Image]?
    let distance: Double?
    let units: TicketUnits?
    let sales: Sales?
    let dates: Dates?
    let classifications: [Classification]?
    let promoter: Promoter?
    let promoters: [Promoter]?
    let pleaseNote: String?
    let priceRanges: [PriceRange]?
    let products: [Product]?
    let seatmap: Seatmap?
    let ticketLimit: Accessibility?
    let links: EventLinks?
    let embedded: EventEmbedded?
    let info: String?
    let accessibility: Accessibility?
    
    enum CodingKeys: String, CodingKey {
        case name, type, id, test, url, images, distance, units, sales, dates, classifications, promoter, promoters, pleaseNote, priceRanges, products, seatmap, ticketLimit
        case links = "_links"
        case embedded = "_embedded"
        case local = "locale"
        case info, accessibility
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
}

func ==(lhs: TicketMasterEvent, rhs: TicketMasterEvent) -> Bool {
    return lhs.uuid == rhs.uuid
}

// MARK: - Accessibility
struct Accessibility: Codable, Equatable, Hashable {
    let info: String?
}

// MARK: - Classification
struct Classification: Codable, Equatable, Hashable {
    let primary: Bool?
    let segment, genre, subGenre, type: Genre?
    let subType: Genre?
    let family: Bool?
}

// MARK: - Genre
struct Genre: Codable, Equatable, Hashable {
    let id: String?
    let name: String?
}

// MARK: - Dates
struct Dates: Codable, Equatable, Hashable {
    let start: Start?
    let timezone: String?
    let status: StatusUpdate?
    let spanMultipleDays: Bool?
    
}

// MARK: - Start
struct Start: Codable, Equatable, Hashable {
    let localDate, localTime: String?
    let dateTime: String?
    let dateTBD, dateTBA, timeTBA, noSpecificTime: Bool?
    
}

// MARK: - Status
struct StatusUpdate: Codable, Equatable, Hashable {
    let code: String?
}

// MARK: - EventEmbedded
struct EventEmbedded: Codable, Equatable, Hashable {
    let venues: [Venue]?
    let attractions: [TicketMasterAttraction]?
}

// MARK: - Attraction
struct TicketMasterAttraction: Codable, Equatable, Hashable {
    let name: String
    let type: String?
    let id: String
    let test: Bool?
    let url: String?
    let local: String?
    let images: [Image]?
    let classifications: [Classification]?
    let upcomingEvents: UpcomingEvents?
    let links: AttractionLinks?
    let aliases: [String]?
    
    enum CodingKeys: String, CodingKey {
        case name, type, id, test, url, images, classifications, upcomingEvents
        case links = "_links"
        case local = "locale"
        case aliases
    }
}

func ==(lhs: TicketMasterAttraction, rhs: TicketMasterAttraction) -> Bool {
    return lhs.id == rhs.id
}

// MARK: - Image
struct Image: Codable, Equatable, Hashable {
    let ratio: String?
    let url: String?
    let width, height: Int?
    let fallback: Bool?
    let attribution: String?
}

// MARK: - AttractionLinks
struct AttractionLinks: Codable, Equatable, Hashable {
    let linksSelf: First?
    
    enum CodingKeys: String, CodingKey {
        case linksSelf = "self"
    }
}

// MARK: - First
struct First: Codable, Equatable, Hashable {
    let href: String?
}

// MARK: - UpcomingEvents
struct UpcomingEvents: Codable, Equatable, Hashable {
    let total, ticketmaster, tmr: Int?
    
    enum CodingKeys: String, CodingKey {
        case total = "_total"
        case ticketmaster, tmr
    }
}

// MARK: - Venue
struct Venue: Codable, Equatable, Hashable {
    let name: String?
    let type: VenueType?
    let id: String?
    let test: Bool?
    let url: String?
    let local: String?
    let images: [Image]?
    let distance: Double?
    let units: TicketUnits?
    let postalCode: String?
    let timezone: String?
    let city: City?
    let state: State?
    let country: CountryOfEvent?
    let address: Address?
    let location: Location?
    let markets: [Genre]?
    let dmas: [DMA]?
    let social: Social?
    let boxOfficeInfo: BoxOfficeInfo?
    let parkingDetail, accessibleSeatingDetail: String?
    let generalInfo: GeneralInfo?
    let upcomingEvents: UpcomingEvents?
    let links: AttractionLinks?
    let ada: Ada?
    let aliases: [String]?
    
    enum CodingKeys: String, CodingKey {
        case name, type, id, test, url, images, distance, units, postalCode, timezone, city, state, country, address, location, markets, dmas, social, boxOfficeInfo, parkingDetail, accessibleSeatingDetail, generalInfo, upcomingEvents
        case links = "_links"
        case local = "locale"
        case ada, aliases
    }
}

// MARK: - Ada
struct Ada: Codable, Equatable, Hashable {
    let adaPhones, adaCustomCopy, adaHours: String?
}

// MARK: - Address
struct Address: Codable, Equatable, Hashable {
    let line1: String?
    let line2: String?
}

// MARK: - BoxOfficeInfo
struct BoxOfficeInfo: Codable, Equatable, Hashable {
    let phoneNumberDetail, openHoursDetail, acceptedPaymentDetail, willCallDetail: String?
}

// MARK: - City
struct City: Codable, Equatable, Hashable {
    let name: String?
}

// MARK: - Country
struct CountryOfEvent: Codable, Equatable, Hashable {
    let name: String?
    let countryCode: String?
}

// MARK: - DMA
struct DMA: Codable, Equatable, Hashable {
    let id: Int?
}

// MARK: - GeneralInfo
struct GeneralInfo: Codable, Equatable, Hashable {
    let generalRule, childRule: String?
}

// MARK: - Location
struct Location: Codable, Equatable, Hashable {
    let longitude, latitude: String?
}

// MARK: - Social
struct Social: Codable, Equatable, Hashable {
    let twitter: Twitter?
}

// MARK: - Twitter
struct Twitter: Codable, Equatable, Hashable {
    let handle: String?
}

// MARK: - State
struct State: Codable, Equatable, Hashable {
    let name: String?
    let stateCode: String?
}

enum VenueType: String, Codable, Equatable, Hashable {
    case venue = "venue"
}

enum TicketUnits: String, Codable, Equatable, Hashable {
    case miles = "MILES"
}

// MARK: - EventLinks
struct EventLinks: Codable, Equatable, Hashable {
    let linksSelf: First?
    let attractions, venues: [First]?
    
    enum CodingKeys: String, CodingKey {
        case linksSelf = "self"
        case attractions, venues
    }
}

// MARK: - PriceRange
struct PriceRange: Codable, Equatable, Hashable {
    let type: String?
    let currency: String?
    let min, max: Double?
}

// MARK: - Product
struct Product: Codable, Equatable, Hashable {
    let id: String?
    let url: String?
    let type, name: String?
}

// MARK: - Promoter
struct Promoter: Codable, Equatable, Hashable {
    let id: String?
    let name: String?
    let promoterDescription: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case promoterDescription = "description"
    }
}

// MARK: - Sales
struct Sales: Codable, Equatable, Hashable {
    let salesPublic: Public?
    let presales: [Presale]?
    
    enum CodingKeys: String, CodingKey {
        case salesPublic = "public"
        case presales
    }
}

// MARK: - Presale
struct Presale: Codable, Equatable, Hashable {
    let startDateTime, endDateTime: String?
    let name: String?
}

// MARK: - Public
struct Public: Codable, Equatable, Hashable {
    let startDateTime: String?
    let startTBD: Bool?
    let endDateTime: String?
}

// MARK: - Seatmap
struct Seatmap: Codable, Equatable, Hashable {
    let staticURL: String?
    
    enum CodingKeys: String, CodingKey {
        case staticURL = "staticUrl"
    }
}

enum EventType: String, Codable, Equatable, Hashable {
    case event = "event"
}

// MARK: - WelcomeLinks
struct WelcomeLinks: Codable, Equatable, Hashable {
    let first, linksSelf, next, last: First?
    
    enum CodingKeys: String, CodingKey {
        case first
        case linksSelf = "self"
        case next, last
    }
}

// MARK: - Page
struct Page: Codable, Equatable, Hashable {
    let size, totalElements, totalPages, number: Int?
}

func sortEvents(events: [TicketMasterEvent]) -> [TicketMasterEvent] {
    return events.sorted { (event1, event2) -> Bool in
        if let firstDateString = event1.dates?.start?.localDate, let firstDate = firstDateString.toDate(), let secondDateString = event2.dates?.start?.localDate, let secondDate = secondDateString.toDate() {
            return firstDate < secondDate
        } else {
            return false
        }
    }
}
