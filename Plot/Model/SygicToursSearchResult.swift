//
//  SygicToursSearchResult.swift
//  Plot
//
//  Created by Cory McHattie on 6/17/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let sygicToursSearchResult = try SygicToursSearchResult(json)

import Foundation

// MARK: - SygicToursSearchResult
struct SygicToursSearchResult: Codable, Equatable, Hashable {
    
    let statusCode: Int?
    let data: TourData?
    let serverTimestamp: String?
    
    enum CodingKeys: String, CodingKey {
        case statusCode = "status_code"
        case data
        case serverTimestamp = "server_timestamp"
    }
    
    init(statusCode: Int?, data: TourData?, serverTimestamp: String?) {
        self.statusCode = statusCode
        self.data = data
        self.serverTimestamp = serverTimestamp
    }
}

// MARK: - TourData
struct TourData: Codable, Equatable, Hashable {
    let trip: Trip?
    
    init(trip: Trip?) {
        self.trip = trip
    }
}

// MARK: - Trip
struct Trip: Codable, Equatable, Hashable {
    let id: String
    let ownerID, name: String?
    let version: Int?
    let url: String?
    let updatedAt: Date?
    let isDeleted: Bool?
    let privacyLevel: String?
    let privileges: Privileges?
    let startsOn, endsOn: String?
    let media: TourMedia?
    let dayCount: Int?
    let userIsSubscribed: Bool?
    let days: [Day]?
    let destinations: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case ownerID = "owner_id"
        case name, version, url
        case updatedAt = "updated_at"
        case isDeleted = "is_deleted"
        case privacyLevel = "privacy_level"
        case privileges
        case startsOn = "starts_on"
        case endsOn = "ends_on"
        case media
        case dayCount = "day_count"
        case userIsSubscribed = "user_is_subscribed"
        case days, destinations
    }
    
    init(id: String, ownerID: String?, name: String?, version: Int?, url: String?, updatedAt: Date?, isDeleted: Bool?, privacyLevel: String?, privileges: Privileges?, startsOn: String?, endsOn: String?, media: TourMedia?, dayCount: Int?, userIsSubscribed: Bool?, days: [Day]?, destinations: [String]?) {
        self.id = id
        self.ownerID = ownerID
        self.name = name
        self.version = version
        self.url = url
        self.updatedAt = updatedAt
        self.isDeleted = isDeleted
        self.privacyLevel = privacyLevel
        self.privileges = privileges
        self.startsOn = startsOn
        self.endsOn = endsOn
        self.media = media
        self.dayCount = dayCount
        self.userIsSubscribed = userIsSubscribed
        self.days = days
        self.destinations = destinations
    }
}

func ==(lhs: Trip, rhs: Trip) -> Bool {
    return lhs.id == rhs.id
}

// MARK: - Day
struct Day: Codable, Equatable, Hashable {
    let itinerary: [Itinerary]?
    let note: String?
    
    init(itinerary: [Itinerary]?, note: String?) {
        self.itinerary = itinerary
        self.note = note
    }
}

// MARK: - Itinerary
struct Itinerary: Codable, Equatable, Hashable {
    let placeID: String?
    let startTime, duration: Int?
    let note: String?
    let transportFromPrevious: TransportFromPrevious?
    
    enum CodingKeys: String, CodingKey {
        case placeID = "place_id"
        case startTime = "start_time"
        case duration, note
        case transportFromPrevious = "transport_from_previous"
    }
    
    init(placeID: String?, startTime: Int?, duration: Int?, note: String?, transportFromPrevious: TransportFromPrevious?) {
        self.placeID = placeID
        self.startTime = startTime
        self.duration = duration
        self.note = note
        self.transportFromPrevious = transportFromPrevious
    }
}

// MARK: - TransportFromPrevious
struct TransportFromPrevious: Codable, Equatable, Hashable {
    let mode: [String]?
    let avoid: [String]?
    let startTime, duration: Int?
    let note: String?
    let waypoints: [Waypoint]?
    let routeID: String?

    enum CodingKeys: String, CodingKey {
        case mode, avoid
        case startTime = "start_time"
        case duration, note, waypoints
        case routeID = "route_id"
    }
}

// MARK: - Waypoint
struct Waypoint: Codable, Equatable, Hashable {
    let place_id: String?
    let location: TripLocation?
}

// MARK: - TripLocation
struct TripLocation: Codable, Equatable, Hashable {
    let lat: Double?
    let lng: Double?
}

// MARK: - TourMedia
struct TourMedia: Codable, Equatable, Hashable {
    let square, landscape, portrait: Landscape?
    
    enum CodingKeys: String, CodingKey {
        case square, landscape, portrait
    }
    
    init(square: Landscape?, landscape: Landscape?, portrait: Landscape?) {
        self.square = square
        self.landscape = landscape
        self.portrait = portrait
    }
}

// MARK: - Landscape
struct Landscape: Codable, Equatable, Hashable {
    let id, urlTemplate: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case urlTemplate = "url_template"
    }
    
    init(id: String?, urlTemplate: String?) {
        self.id = id
        self.urlTemplate = urlTemplate
    }
}

// MARK: - Privileges
struct Privileges: Codable, Equatable, Hashable {
    let edit, manage, delete, join: Bool?
    
    init(edit: Bool?, manage: Bool?, delete: Bool?, join: Bool?) {
        self.edit = edit
        self.manage = manage
        self.delete = delete
        self.join = join
    }
}
