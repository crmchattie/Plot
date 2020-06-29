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
class SygicToursSearchResult: Codable {
    
    let statusCode: Int?
    let data: TourData?
    let serverTimestamp: Date?
    
    enum CodingKeys: String, CodingKey {
        case statusCode = "status_code"
        case data
        case serverTimestamp = "server_timestamp"
    }
    
    init(statusCode: Int?, data: TourData?, serverTimestamp: Date?) {
        self.statusCode = statusCode
        self.data = data
        self.serverTimestamp = serverTimestamp
    }
}

// MARK: SygicTour convenience initializers and mutators

extension SygicToursSearchResult {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(SygicToursSearchResult.self, from: data)
        self.init(statusCode: me.statusCode, data: me.data, serverTimestamp: me.serverTimestamp)
    }
    
    convenience init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
    
    convenience init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }
    
    func with(
        statusCode: Int?? = nil,
        data: TourData?? = nil,
        serverTimestamp: Date?? = nil
    ) -> SygicToursSearchResult {
        return SygicToursSearchResult(
            statusCode: statusCode ?? self.statusCode,
            data: data ?? self.data,
            serverTimestamp: serverTimestamp ?? self.serverTimestamp
        )
    }
    
    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }
    
    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - TourData
class TourData: Codable {
    let trip: Trip?
    
    init(trip: Trip?) {
        self.trip = trip
    }
}

// MARK: TourData convenience initializers and mutators

extension TourData {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(TourData.self, from: data)
        self.init(trip: me.trip)
    }
    
    convenience init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
    
    convenience init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }
    
    func with(
        trip: Trip?? = nil
    ) -> TourData {
        return TourData(
            trip: trip ?? self.trip
        )
    }
    
    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }
    
    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Trip
class Trip: Codable {
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

// MARK: Trip convenience initializers and mutators

extension Trip {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Trip.self, from: data)
        self.init(id: me.id, ownerID: me.ownerID, name: me.name, version: me.version, url: me.url, updatedAt: me.updatedAt, isDeleted: me.isDeleted, privacyLevel: me.privacyLevel, privileges: me.privileges, startsOn: me.startsOn, endsOn: me.endsOn, media: me.media, dayCount: me.dayCount, userIsSubscribed: me.userIsSubscribed, days: me.days, destinations: me.destinations)
    }
    
    convenience init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
    
    convenience init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }
    
    func with(
        id: String,
        ownerID: String?? = nil,
        name: String?? = nil,
        version: Int?? = nil,
        url: String?? = nil,
        updatedAt: Date?? = nil,
        isDeleted: Bool?? = nil,
        privacyLevel: String?? = nil,
        privileges: Privileges?? = nil,
        startsOn: String?? = nil,
        endsOn: String?? = nil,
        media: TourMedia?? = nil,
        dayCount: Int?? = nil,
        userIsSubscribed: Bool?? = nil,
        days: [Day]?? = nil,
        destinations: [String]?? = nil
    ) -> Trip {
        return Trip(
            id: id,
            ownerID: ownerID ?? self.ownerID,
            name: name ?? self.name,
            version: version ?? self.version,
            url: url ?? self.url,
            updatedAt: updatedAt ?? self.updatedAt,
            isDeleted: isDeleted ?? self.isDeleted,
            privacyLevel: privacyLevel ?? self.privacyLevel,
            privileges: privileges ?? self.privileges,
            startsOn: startsOn ?? self.startsOn,
            endsOn: endsOn ?? self.endsOn,
            media: media ?? self.media,
            dayCount: dayCount ?? self.dayCount,
            userIsSubscribed: userIsSubscribed ?? self.userIsSubscribed,
            days: days ?? self.days,
            destinations: destinations ?? self.destinations
        )
    }
    
    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }
    
    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Day
class Day: Codable {
    let itinerary: [Itinerary]?
    let note: JSONNull?
    
    init(itinerary: [Itinerary]?, note: JSONNull?) {
        self.itinerary = itinerary
        self.note = note
    }
}

// MARK: Day convenience initializers and mutators

extension Day {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Day.self, from: data)
        self.init(itinerary: me.itinerary, note: me.note)
    }
    
    convenience init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
    
    convenience init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }
    
    func with(
        itinerary: [Itinerary]?? = nil,
        note: JSONNull?? = nil
    ) -> Day {
        return Day(
            itinerary: itinerary ?? self.itinerary,
            note: note ?? self.note
        )
    }
    
    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }
    
    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Itinerary
class Itinerary: Codable {
    let placeID: String?
    let startTime, duration: Int?
    let note, transportFromPrevious: JSONNull?
    
    enum CodingKeys: String, CodingKey {
        case placeID = "place_id"
        case startTime = "start_time"
        case duration, note
        case transportFromPrevious = "transport_from_previous"
    }
    
    init(placeID: String?, startTime: Int?, duration: Int?, note: JSONNull?, transportFromPrevious: JSONNull?) {
        self.placeID = placeID
        self.startTime = startTime
        self.duration = duration
        self.note = note
        self.transportFromPrevious = transportFromPrevious
    }
}

// MARK: Itinerary convenience initializers and mutators

extension Itinerary {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Itinerary.self, from: data)
        self.init(placeID: me.placeID, startTime: me.startTime, duration: me.duration, note: me.note, transportFromPrevious: me.transportFromPrevious)
    }
    
    convenience init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
    
    convenience init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }
    
    func with(
        placeID: String?? = nil,
        startTime: Int?? = nil,
        duration: Int?? = nil,
        note: JSONNull?? = nil,
        transportFromPrevious: JSONNull?? = nil
    ) -> Itinerary {
        return Itinerary(
            placeID: placeID ?? self.placeID,
            startTime: startTime ?? self.startTime,
            duration: duration ?? self.duration,
            note: note ?? self.note,
            transportFromPrevious: transportFromPrevious ?? self.transportFromPrevious
        )
    }
    
    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }
    
    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - TourMedia
class TourMedia: Codable {
    let square, landscape, portrait: Landscape?
    let videoPreview: JSONNull?
    
    enum CodingKeys: String, CodingKey {
        case square, landscape, portrait
        case videoPreview = "video_preview"
    }
    
    init(square: Landscape?, landscape: Landscape?, portrait: Landscape?, videoPreview: JSONNull?) {
        self.square = square
        self.landscape = landscape
        self.portrait = portrait
        self.videoPreview = videoPreview
    }
}

// MARK: TourMedia convenience initializers and mutators

extension TourMedia {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(TourMedia.self, from: data)
        self.init(square: me.square, landscape: me.landscape, portrait: me.portrait, videoPreview: me.videoPreview)
    }
    
    convenience init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
    
    convenience init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }
    
    func with(
        square: Landscape?? = nil,
        landscape: Landscape?? = nil,
        portrait: Landscape?? = nil,
        videoPreview: JSONNull?? = nil
    ) -> TourMedia {
        return TourMedia(
            square: square ?? self.square,
            landscape: landscape ?? self.landscape,
            portrait: portrait ?? self.portrait,
            videoPreview: videoPreview ?? self.videoPreview
        )
    }
    
    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }
    
    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Landscape
class Landscape: Codable {
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

// MARK: Landscape convenience initializers and mutators

extension Landscape {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Landscape.self, from: data)
        self.init(id: me.id, urlTemplate: me.urlTemplate)
    }
    
    convenience init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
    
    convenience init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }
    
    func with(
        id: String?? = nil,
        urlTemplate: String?? = nil
    ) -> Landscape {
        return Landscape(
            id: id ?? self.id,
            urlTemplate: urlTemplate ?? self.urlTemplate
        )
    }
    
    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }
    
    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Privileges
class Privileges: Codable {
    let edit, manage, delete, join: Bool?
    
    init(edit: Bool?, manage: Bool?, delete: Bool?, join: Bool?) {
        self.edit = edit
        self.manage = manage
        self.delete = delete
        self.join = join
    }
}

// MARK: Privileges convenience initializers and mutators

extension Privileges {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Privileges.self, from: data)
        self.init(edit: me.edit, manage: me.manage, delete: me.delete, join: me.join)
    }
    
    convenience init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
    
    convenience init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }
    
    func with(
        edit: Bool?? = nil,
        manage: Bool?? = nil,
        delete: Bool?? = nil,
        join: Bool?? = nil
    ) -> Privileges {
        return Privileges(
            edit: edit ?? self.edit,
            manage: manage ?? self.manage,
            delete: delete ?? self.delete,
            join: join ?? self.join
        )
    }
    
    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }
    
    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}
