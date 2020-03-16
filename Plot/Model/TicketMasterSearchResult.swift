//
//  TicketMasterSearchResult.swift
//  Plot
//
//  Created by Cory McHattie on 1/11/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

struct TicketMasterSearchResult: Codable {
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
    struct Embedded: Codable {
        let events: [Event]?
        let attractions: [Attraction]?
    }

    // MARK: - Event
    struct Event: Codable {
        let name: String?
        let type: EventType?
        let id: String?
        let test: Bool?
        let url: String?
        let local: String?
        let images: [Image]?
        let distance: Double?
        let units: Units?
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
        
    }

    // MARK: - Accessibility
    struct Accessibility: Codable {
        let info: String?
    }

    // MARK: - Classification
    struct Classification: Codable {
        let primary: Bool?
        let segment, genre, subGenre, type: Genre?
        let subType: Genre?
        let family: Bool?
    }

    // MARK: - Genre
    struct Genre: Codable {
        let id: String?
        let name: String?
    }

    // MARK: - Dates
    struct Dates: Codable {
        let start: Start?
        let timezone: String?
        let status: StatusUpdate?
        let spanMultipleDays: Bool?
        
    }

    // MARK: - Start
    struct Start: Codable {
        let localDate, localTime: String?
        let dateTime: String?
        let dateTBD, dateTBA, timeTBA, noSpecificTime: Bool?
        
    }

    // MARK: - Status
    struct StatusUpdate: Codable {
        let code: String?
    }

    // MARK: - EventEmbedded
    struct EventEmbedded: Codable {
        let venues: [Venue]?
        let attractions: [Attraction]?
    }

    // MARK: - Attraction
    struct Attraction: Codable {
        let name: String?
        let type: AttractionType?
        let id: String?
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

    // MARK: - Image
    struct Image: Codable {
        let ratio: String?
        let url: String?
        let width, height: Int?
        let fallback: Bool?
        let attribution: String?
    }

    // MARK: - AttractionLinks
    struct AttractionLinks: Codable {
        let linksSelf: First?

        enum CodingKeys: String, CodingKey {
            case linksSelf = "self"
        }
    }

    // MARK: - First
    struct First: Codable {
        let href: String?
    }

    enum AttractionType: String, Codable {
        case attraction = "attraction"
    }

    // MARK: - UpcomingEvents
    struct UpcomingEvents: Codable {
        let total, ticketmaster, tmr: Int?

        enum CodingKeys: String, CodingKey {
            case total = "_total"
            case ticketmaster, tmr
        }
    }

    // MARK: - Venue
    struct Venue: Codable {
        let name: String?
        let type: VenueType?
        let id: String?
        let test: Bool?
        let url: String?
        let local: String?
        let images: [Image]?
        let distance: Double?
        let units: Units?
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
    struct Ada: Codable {
        let adaPhones, adaCustomCopy, adaHours: String?
    }

    // MARK: - Address
    struct Address: Codable {
        let line1: String?
        let line2: String?
    }

    // MARK: - BoxOfficeInfo
    struct BoxOfficeInfo: Codable {
        let phoneNumberDetail, openHoursDetail, acceptedPaymentDetail, willCallDetail: String?
    }

    // MARK: - City
    struct City: Codable {
        let name: String?
    }

    // MARK: - Country
    struct CountryOfEvent: Codable {
        let name: String?
        let countryCode: String?
    }

    // MARK: - DMA
    struct DMA: Codable {
        let id: Int?
    }

    // MARK: - GeneralInfo
    struct GeneralInfo: Codable {
        let generalRule, childRule: String?
    }

    // MARK: - Location
    struct Location: Codable {
        let longitude, latitude: String?
    }

    // MARK: - Social
    struct Social: Codable {
        let twitter: Twitter?
    }

    // MARK: - Twitter
    struct Twitter: Codable {
        let handle: String?
    }

    // MARK: - State
    struct State: Codable {
        let name: String?
        let stateCode: String?
    }

    enum VenueType: String, Codable {
        case venue = "venue"
    }

    enum Units: String, Codable {
        case miles = "MILES"
    }

    // MARK: - EventLinks
    struct EventLinks: Codable {
        let linksSelf: First?
        let attractions, venues: [First]?

        enum CodingKeys: String, CodingKey {
            case linksSelf = "self"
            case attractions, venues
        }
    }

    // MARK: - PriceRange
    struct PriceRange: Codable {
        let type: String?
        let currency: String?
        let min, max: Double?
    }

    // MARK: - Product
    struct Product: Codable {
        let id: String?
        let url: String?
        let type, name: String?
    }

    // MARK: - Promoter
    struct Promoter: Codable {
        let id: String?
        let name: String?
        let promoterDescription: String?

        enum CodingKeys: String, CodingKey {
            case id, name
            case promoterDescription = "description"
        }
    }

    // MARK: - Sales
    struct Sales: Codable {
        let salesPublic: Public?
        let presales: [Presale]?

        enum CodingKeys: String, CodingKey {
            case salesPublic = "public"
            case presales
        }
    }

    // MARK: - Presale
    struct Presale: Codable {
        let startDateTime, endDateTime: String?
        let name: String?
    }

    // MARK: - Public
    struct Public: Codable {
        let startDateTime: String?
        let startTBD: Bool?
        let endDateTime: String?
    }

    // MARK: - Seatmap
    struct Seatmap: Codable {
        let staticURL: String?

        enum CodingKeys: String, CodingKey {
            case staticURL = "staticUrl"
        }
    }

    enum EventType: String, Codable {
        case event = "event"
    }

    // MARK: - WelcomeLinks
    struct WelcomeLinks: Codable {
        let first, linksSelf, next, last: First?

        enum CodingKeys: String, CodingKey {
            case first
            case linksSelf = "self"
            case next, last
        }
    }

    // MARK: - Page
    struct Page: Codable {
        let size, totalElements, totalPages, number: Int?
    }



//    func sortEvents(events: [Event]) -> [Event] {
//        return events.sorted {(
//            ($0.dates?.start?.dateTime!.toDate())! < ($1.dates?.start?.dateTime!.toDate())!
//        )}
//    }

    func sortEvents(events: [Event]) -> [Event] {
        return events.sorted { (event1, event2) -> Bool in
            if let firstDateString = event1.dates?.start?.localDate, let firstDate = firstDateString.toDate(), let secondDateString = event2.dates?.start?.localDate, let secondDate = secondDateString.toDate() {
                return firstDate < secondDate
            } else {
                return false
            }
        }
    }
