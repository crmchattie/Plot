//
//  FoursquareVenueRecSearchResult.swift
//  Plot
//
//  Created by Cory McHattie on 6/17/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let foursquareRecVenueSearchResult = try FoursquareRecVenueSearchResult(json)

import Foundation

// MARK: - FoursquareRecVenueSearchResult
class FoursquareRecVenueSearchResult: Codable {
    let meta: Meta?
    let response: RecResponse?

    init(meta: Meta?, response: RecResponse?) {
        self.meta = meta
        self.response = response
    }
}

// MARK: FoursquareRecVenueSearchResult convenience initializers and mutators

extension FoursquareRecVenueSearchResult {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(FoursquareRecVenueSearchResult.self, from: data)
        self.init(meta: me.meta, response: me.response)
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
        meta: Meta?? = nil,
        response: RecResponse?? = nil
    ) -> FoursquareRecVenueSearchResult {
        return FoursquareRecVenueSearchResult(
            meta: meta ?? self.meta,
            response: response ?? self.response
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Meta
class Meta: Codable {
    let code: Int?
    let requestID: String?

    enum CodingKeys: String, CodingKey {
        case code
        case requestID = "requestId"
    }

    init(code: Int?, requestID: String?) {
        self.code = code
        self.requestID = requestID
    }
}

// MARK: Meta convenience initializers and mutators

extension Meta {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Meta.self, from: data)
        self.init(code: me.code, requestID: me.requestID)
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
        code: Int?? = nil,
        requestID: String?? = nil
    ) -> Meta {
        return Meta(
            code: code ?? self.code,
            requestID: requestID ?? self.requestID
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - RecResponse
class RecResponse: Codable {
    let suggestedFilters: SuggestedFilters?
    let geocode: Geocode?
    let headerLocation, headerFullLocation: String?
    let headerLocationGranularity: String?
    let totalResults: Int?
    let suggestedBounds: Bounds?
    let groups: [GroupItem]?

    init(suggestedFilters: SuggestedFilters?, geocode: Geocode?, headerLocation: String?, headerFullLocation: String?, headerLocationGranularity: String?, totalResults: Int?, suggestedBounds: Bounds?, groups: [GroupItem]?) {
        self.suggestedFilters = suggestedFilters
        self.geocode = geocode
        self.headerLocation = headerLocation
        self.headerFullLocation = headerFullLocation
        self.headerLocationGranularity = headerLocationGranularity
        self.totalResults = totalResults
        self.suggestedBounds = suggestedBounds
        self.groups = groups
    }
}

// MARK: RecResponse convenience initializers and mutators

extension RecResponse {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(RecResponse.self, from: data)
        self.init(suggestedFilters: me.suggestedFilters, geocode: me.geocode, headerLocation: me.headerLocation, headerFullLocation: me.headerFullLocation, headerLocationGranularity: me.headerLocationGranularity, totalResults: me.totalResults, suggestedBounds: me.suggestedBounds, groups: me.groups)
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
        suggestedFilters: SuggestedFilters?? = nil,
        geocode: Geocode?? = nil,
        headerLocation: String?? = nil,
        headerFullLocation: String?? = nil,
        headerLocationGranularity: String?? = nil,
        totalResults: Int?? = nil,
        suggestedBounds: Bounds?? = nil,
        groups: [GroupItem]?? = nil
    ) -> RecResponse {
        return RecResponse(
            suggestedFilters: suggestedFilters ?? self.suggestedFilters,
            geocode: geocode ?? self.geocode,
            headerLocation: headerLocation ?? self.headerLocation,
            headerFullLocation: headerFullLocation ?? self.headerFullLocation,
            headerLocationGranularity: headerLocationGranularity ?? self.headerLocationGranularity,
            totalResults: totalResults ?? self.totalResults,
            suggestedBounds: suggestedBounds ?? self.suggestedBounds,
            groups: groups ?? self.groups
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Geocode
class Geocode: Codable {
    let what, geocodeWhere: String?
    let center: Center?
    let displayString: String?
    let cc: Cc?
    let geometry: Geometry?
    let slug, longID: String?

    enum CodingKeys: String, CodingKey {
        case what
        case geocodeWhere = "where"
        case center, displayString, cc, geometry, slug
        case longID = "longId"
    }

    init(what: String?, geocodeWhere: String?, center: Center?, displayString: String?, cc: Cc?, geometry: Geometry?, slug: String?, longID: String?) {
        self.what = what
        self.geocodeWhere = geocodeWhere
        self.center = center
        self.displayString = displayString
        self.cc = cc
        self.geometry = geometry
        self.slug = slug
        self.longID = longID
    }
}

// MARK: Geocode convenience initializers and mutators

extension Geocode {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Geocode.self, from: data)
        self.init(what: me.what, geocodeWhere: me.geocodeWhere, center: me.center, displayString: me.displayString, cc: me.cc, geometry: me.geometry, slug: me.slug, longID: me.longID)
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
        what: String?? = nil,
        geocodeWhere: String?? = nil,
        center: Center?? = nil,
        displayString: String?? = nil,
        cc: Cc?? = nil,
        geometry: Geometry?? = nil,
        slug: String?? = nil,
        longID: String?? = nil
    ) -> Geocode {
        return Geocode(
            what: what ?? self.what,
            geocodeWhere: geocodeWhere ?? self.geocodeWhere,
            center: center ?? self.center,
            displayString: displayString ?? self.displayString,
            cc: cc ?? self.cc,
            geometry: geometry ?? self.geometry,
            slug: slug ?? self.slug,
            longID: longID ?? self.longID
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

enum Cc: String, Codable {
    case us = "US"
}

// MARK: - Center
class Center: Codable {
    let lat, lng: Double?

    init(lat: Double?, lng: Double?) {
        self.lat = lat
        self.lng = lng
    }
}

// MARK: Center convenience initializers and mutators

extension Center {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Center.self, from: data)
        self.init(lat: me.lat, lng: me.lng)
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
        lat: Double?? = nil,
        lng: Double?? = nil
    ) -> Center {
        return Center(
            lat: lat ?? self.lat,
            lng: lng ?? self.lng
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Geometry
class Geometry: Codable {
    let bounds: Bounds?

    init(bounds: Bounds?) {
        self.bounds = bounds
    }
}

// MARK: Geometry convenience initializers and mutators

extension Geometry {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Geometry.self, from: data)
        self.init(bounds: me.bounds)
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
        bounds: Bounds?? = nil
    ) -> Geometry {
        return Geometry(
            bounds: bounds ?? self.bounds
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Bounds
class Bounds: Codable {
    let ne, sw: Center?

    init(ne: Center?, sw: Center?) {
        self.ne = ne
        self.sw = sw
    }
}

// MARK: Bounds convenience initializers and mutators

extension Bounds {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Bounds.self, from: data)
        self.init(ne: me.ne, sw: me.sw)
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
        ne: Center?? = nil,
        sw: Center?? = nil
    ) -> Bounds {
        return Bounds(
            ne: ne ?? self.ne,
            sw: sw ?? self.sw
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - GroupItem
class GroupItem: Codable {
    let reasons: Reasons?
    let venue: FSVenue?
    let referralID: String?

    enum CodingKeys: String, CodingKey {
        case reasons, venue
        case referralID = "referralId"
    }

    init(reasons: Reasons?, venue: FSVenue?, referralID: String?) {
        self.reasons = reasons
        self.venue = venue
        self.referralID = referralID
    }
}

// MARK: GroupItem convenience initializers and mutators

extension GroupItem {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(GroupItem.self, from: data)
        self.init(reasons: me.reasons, venue: me.venue, referralID: me.referralID)
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
        reasons: Reasons?? = nil,
        venue: FSVenue?? = nil,
        referralID: String?? = nil
    ) -> GroupItem {
        return GroupItem(
            reasons: reasons ?? self.reasons,
            venue: venue ?? self.venue,
            referralID: referralID ?? self.referralID
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Reasons
class Reasons: Codable {
    let count: Int?
    let items: [ReasonsItem]?

    init(count: Int?, items: [ReasonsItem]?) {
        self.count = count
        self.items = items
    }
}

// MARK: Reasons convenience initializers and mutators

extension Reasons {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Reasons.self, from: data)
        self.init(count: me.count, items: me.items)
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
        count: Int?? = nil,
        items: [ReasonsItem]?? = nil
    ) -> Reasons {
        return Reasons(
            count: count ?? self.count,
            items: items ?? self.items
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - ReasonsItem
class ReasonsItem: Codable {
    let summary: Summary?
    let type: TypeEnum?
    let reasonName: ReasonName?

    init(summary: Summary?, type: TypeEnum?, reasonName: ReasonName?) {
        self.summary = summary
        self.type = type
        self.reasonName = reasonName
    }
}

// MARK: ReasonsItem convenience initializers and mutators

extension ReasonsItem {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(ReasonsItem.self, from: data)
        self.init(summary: me.summary, type: me.type, reasonName: me.reasonName)
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
        summary: Summary?? = nil,
        type: TypeEnum?? = nil,
        reasonName: ReasonName?? = nil
    ) -> ReasonsItem {
        return ReasonsItem(
            summary: summary ?? self.summary,
            type: type ?? self.type,
            reasonName: reasonName ?? self.reasonName
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

enum ReasonName: String, Codable {
    case globalInteractionReason = "globalInteractionReason"
}

enum Summary: String, Codable {
    case thisSpotIsPopular = "This spot is popular"
}

enum TypeEnum: String, Codable {
    case general = "general"
}

// MARK: - FSVenue
class FSVenue: Codable {
    let id: String
    let name: String?
    let contact: Contact?
    let location: FSLocation?
    let canonicalURL: String?
    let categories: [Category]?
    let verified: Bool?
    let stats: Stats?
    let url: String?
    let likes: Likes?
    let rating: Double?
    let ratingColor: String?
    let ratingSignals: Int?
    let beenHere: BeenHere?
    let photos: Listed?
    let venueDescription, storeID: String?
    let page: FSPage?
    let hereNow: HereNow?
    let createdAt: Int?
    let tips: Listed?
    let shortURL: String?
    let timeZone: String?
    let listed: Listed?
    let phrases: [Phrase]?
    let hours, popular: Hours?
    let pageUpdates, inbox: Inbox?
    let venueChains: [JSONAny]?
    let attributes: Attributes?
    let bestPhoto: BestPhotoClass?

    enum CodingKeys: String, CodingKey {
        case id, name, contact, location
        case canonicalURL = "canonicalUrl"
        case categories, verified, stats, url, likes, rating, ratingColor, ratingSignals, beenHere, photos
        case venueDescription = "description"
        case storeID = "storeId"
        case page, hereNow, createdAt, tips
        case shortURL = "shortUrl"
        case timeZone, listed, phrases, hours, popular, pageUpdates, inbox, venueChains, attributes, bestPhoto
    }

    init(id: String, name: String?, contact: Contact?, location: FSLocation?, canonicalURL: String?, categories: [Category]?, verified: Bool?, stats: Stats?, url: String?, likes: Likes?, rating: Double?, ratingColor: String?, ratingSignals: Int?, beenHere: BeenHere?, photos: Listed?, venueDescription: String?, storeID: String?, page: FSPage?, hereNow: HereNow?, createdAt: Int?, tips: Listed?, shortURL: String?, timeZone: String?, listed: Listed?, phrases: [Phrase]?, hours: Hours?, popular: Hours?, pageUpdates: Inbox?, inbox: Inbox?, venueChains: [JSONAny]?, attributes: Attributes?, bestPhoto: BestPhotoClass?) {
        self.id = id
        self.name = name
        self.contact = contact
        self.location = location
        self.canonicalURL = canonicalURL
        self.categories = categories
        self.verified = verified
        self.stats = stats
        self.url = url
        self.likes = likes
        self.rating = rating
        self.ratingColor = ratingColor
        self.ratingSignals = ratingSignals
        self.beenHere = beenHere
        self.photos = photos
        self.venueDescription = venueDescription
        self.storeID = storeID
        self.page = page
        self.hereNow = hereNow
        self.createdAt = createdAt
        self.tips = tips
        self.shortURL = shortURL
        self.timeZone = timeZone
        self.listed = listed
        self.phrases = phrases
        self.hours = hours
        self.popular = popular
        self.pageUpdates = pageUpdates
        self.inbox = inbox
        self.venueChains = venueChains
        self.attributes = attributes
        self.bestPhoto = bestPhoto
    }
}

// MARK: FSVenue convenience initializers and mutators

extension FSVenue {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(FSVenue.self, from: data)
        self.init(id: me.id, name: me.name, contact: me.contact, location: me.location, canonicalURL: me.canonicalURL, categories: me.categories, verified: me.verified, stats: me.stats, url: me.url, likes: me.likes, rating: me.rating, ratingColor: me.ratingColor, ratingSignals: me.ratingSignals, beenHere: me.beenHere, photos: me.photos, venueDescription: me.venueDescription, storeID: me.storeID, page: me.page, hereNow: me.hereNow, createdAt: me.createdAt, tips: me.tips, shortURL: me.shortURL, timeZone: me.timeZone, listed: me.listed, phrases: me.phrases, hours: me.hours, popular: me.popular, pageUpdates: me.pageUpdates, inbox: me.inbox, venueChains: me.venueChains, attributes: me.attributes, bestPhoto: me.bestPhoto)
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
        name: String?? = nil,
        contact: Contact?? = nil,
        location: FSLocation?? = nil,
        canonicalURL: String?? = nil,
        categories: [Category]?? = nil,
        verified: Bool?? = nil,
        stats: Stats?? = nil,
        url: String?? = nil,
        likes: Likes?? = nil,
        rating: Double?? = nil,
        ratingColor: String?? = nil,
        ratingSignals: Int?? = nil,
        beenHere: BeenHere?? = nil,
        photos: Listed?? = nil,
        venueDescription: String?? = nil,
        storeID: String?? = nil,
        page: FSPage?? = nil,
        hereNow: HereNow?? = nil,
        createdAt: Int?? = nil,
        tips: Listed?? = nil,
        shortURL: String?? = nil,
        timeZone: String?? = nil,
        listed: Listed?? = nil,
        phrases: [Phrase]?? = nil,
        hours: Hours?? = nil,
        popular: Hours?? = nil,
        pageUpdates: Inbox?? = nil,
        inbox: Inbox?? = nil,
        venueChains: [JSONAny]?? = nil,
        attributes: Attributes?? = nil,
        bestPhoto: BestPhotoClass?? = nil
    ) -> FSVenue {
        return FSVenue(
            id: id,
            name: name ?? self.name,
            contact: contact ?? self.contact,
            location: location ?? self.location,
            canonicalURL: canonicalURL ?? self.canonicalURL,
            categories: categories ?? self.categories,
            verified: verified ?? self.verified,
            stats: stats ?? self.stats,
            url: url ?? self.url,
            likes: likes ?? self.likes,
            rating: rating ?? self.rating,
            ratingColor: ratingColor ?? self.ratingColor,
            ratingSignals: ratingSignals ?? self.ratingSignals,
            beenHere: beenHere ?? self.beenHere,
            photos: photos ?? self.photos,
            venueDescription: venueDescription ?? self.venueDescription,
            storeID: storeID ?? self.storeID,
            page: page ?? self.page,
            hereNow: hereNow ?? self.hereNow,
            createdAt: createdAt ?? self.createdAt,
            tips: tips ?? self.tips,
            shortURL: shortURL ?? self.shortURL,
            timeZone: timeZone ?? self.timeZone,
            listed: listed ?? self.listed,
            phrases: phrases ?? self.phrases,
            hours: hours ?? self.hours,
            popular: popular ?? self.popular,
            pageUpdates: pageUpdates ?? self.pageUpdates,
            inbox: inbox ?? self.inbox,
            venueChains: venueChains ?? self.venueChains,
            attributes: attributes ?? self.attributes,
            bestPhoto: bestPhoto ?? self.bestPhoto
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Attributes
class Attributes: Codable {
    let groups: [Group]?

    init(groups: [Group]?) {
        self.groups = groups
    }
}

// MARK: Attributes convenience initializers and mutators

extension Attributes {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Attributes.self, from: data)
        self.init(groups: me.groups)
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
        groups: [Group]?? = nil
    ) -> Attributes {
        return Attributes(
            groups: groups ?? self.groups
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - HereNow
class HereNow: Codable {
    let count: Int?
    let groups: [Group]?
    let summary: String?

    init(count: Int?, groups: [Group]?, summary: String?) {
        self.count = count
        self.groups = groups
        self.summary = summary
    }
}

// MARK: HereNow convenience initializers and mutators

extension HereNow {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(HereNow.self, from: data)
        self.init(count: me.count, groups: me.groups, summary: me.summary)
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
        count: Int?? = nil,
        groups: [Group]?? = nil,
        summary: String?? = nil
    ) -> HereNow {
        return HereNow(
            count: count ?? self.count,
            groups: groups ?? self.groups,
            summary: summary ?? self.summary
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Item
class Item: Codable {
    let displayName, displayValue, id, name: String?
    let itemDescription, type: String?
    let user: BestPhotoUser?
    let editable, itemPublic, collaborative: Bool?
    let url: String?
    let canonicalURL: String?
    let createdAt, updatedAt: Int?
    let photo: BestPhotoClass?
    let followers: Tips?
    let listItems: Inbox?
    let source: FSSource?
    let itemPrefix: String?
    let suffix: String?
    let width, height: Int?
    let visibility, text: String?
    let photourl: String?
    let lang: String?
    let likes: HereNow?
    let logView: Bool?
    let agreeCount, disagreeCount: Int?
    let todo: Tips?
    let editedAt: Int?
    let authorInteractionType: String?

    enum CodingKeys: String, CodingKey {
        case displayName, displayValue, id, name
        case itemDescription = "description"
        case type, user, editable
        case itemPublic = "public"
        case collaborative, url
        case canonicalURL = "canonicalUrl"
        case createdAt, updatedAt, photo, followers, listItems, source
        case itemPrefix = "prefix"
        case suffix, width, height, visibility, text, photourl, lang, likes, logView, agreeCount, disagreeCount, todo, editedAt, authorInteractionType
    }

    init(displayName: String?, displayValue: String?, id: String?, name: String?, itemDescription: String?, type: String?, user: BestPhotoUser?, editable: Bool?, itemPublic: Bool?, collaborative: Bool?, url: String?, canonicalURL: String?, createdAt: Int?, updatedAt: Int?, photo: BestPhotoClass?, followers: Tips?, listItems: Inbox?, source: FSSource?, itemPrefix: String?, suffix: String?, width: Int?, height: Int?, visibility: String?, text: String?, photourl: String?, lang: String?, likes: HereNow?, logView: Bool?, agreeCount: Int?, disagreeCount: Int?, todo: Tips?, editedAt: Int?, authorInteractionType: String?) {
        self.displayName = displayName
        self.displayValue = displayValue
        self.id = id
        self.name = name
        self.itemDescription = itemDescription
        self.type = type
        self.user = user
        self.editable = editable
        self.itemPublic = itemPublic
        self.collaborative = collaborative
        self.url = url
        self.canonicalURL = canonicalURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.photo = photo
        self.followers = followers
        self.listItems = listItems
        self.source = source
        self.itemPrefix = itemPrefix
        self.suffix = suffix
        self.width = width
        self.height = height
        self.visibility = visibility
        self.text = text
        self.photourl = photourl
        self.lang = lang
        self.likes = likes
        self.logView = logView
        self.agreeCount = agreeCount
        self.disagreeCount = disagreeCount
        self.todo = todo
        self.editedAt = editedAt
        self.authorInteractionType = authorInteractionType
    }
}

// MARK: Item convenience initializers and mutators

extension Item {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Item.self, from: data)
        self.init(displayName: me.displayName, displayValue: me.displayValue, id: me.id, name: me.name, itemDescription: me.itemDescription, type: me.type, user: me.user, editable: me.editable, itemPublic: me.itemPublic, collaborative: me.collaborative, url: me.url, canonicalURL: me.canonicalURL, createdAt: me.createdAt, updatedAt: me.updatedAt, photo: me.photo, followers: me.followers, listItems: me.listItems, source: me.source, itemPrefix: me.itemPrefix, suffix: me.suffix, width: me.width, height: me.height, visibility: me.visibility, text: me.text, photourl: me.photourl, lang: me.lang, likes: me.likes, logView: me.logView, agreeCount: me.agreeCount, disagreeCount: me.disagreeCount, todo: me.todo, editedAt: me.editedAt, authorInteractionType: me.authorInteractionType)
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
        displayName: String?? = nil,
        displayValue: String?? = nil,
        id: String?? = nil,
        name: String?? = nil,
        itemDescription: String?? = nil,
        type: String?? = nil,
        user: BestPhotoUser?? = nil,
        editable: Bool?? = nil,
        itemPublic: Bool?? = nil,
        collaborative: Bool?? = nil,
        url: String?? = nil,
        canonicalURL: String?? = nil,
        createdAt: Int?? = nil,
        updatedAt: Int?? = nil,
        photo: BestPhotoClass?? = nil,
        followers: Tips?? = nil,
        listItems: Inbox?? = nil,
        source: FSSource?? = nil,
        itemPrefix: String?? = nil,
        suffix: String?? = nil,
        width: Int?? = nil,
        height: Int?? = nil,
        visibility: String?? = nil,
        text: String?? = nil,
        photourl: String?? = nil,
        lang: String?? = nil,
        likes: HereNow?? = nil,
        logView: Bool?? = nil,
        agreeCount: Int?? = nil,
        disagreeCount: Int?? = nil,
        todo: Tips?? = nil,
        editedAt: Int?? = nil,
        authorInteractionType: String?? = nil
    ) -> Item {
        return Item(
            displayName: displayName ?? self.displayName,
            displayValue: displayValue ?? self.displayValue,
            id: id ?? self.id,
            name: name ?? self.name,
            itemDescription: itemDescription ?? self.itemDescription,
            type: type ?? self.type,
            user: user ?? self.user,
            editable: editable ?? self.editable,
            itemPublic: itemPublic ?? self.itemPublic,
            collaborative: collaborative ?? self.collaborative,
            url: url ?? self.url,
            canonicalURL: canonicalURL ?? self.canonicalURL,
            createdAt: createdAt ?? self.createdAt,
            updatedAt: updatedAt ?? self.updatedAt,
            photo: photo ?? self.photo,
            followers: followers ?? self.followers,
            listItems: listItems ?? self.listItems,
            source: source ?? self.source,
            itemPrefix: itemPrefix ?? self.itemPrefix,
            suffix: suffix ?? self.suffix,
            width: width ?? self.width,
            height: height ?? self.height,
            visibility: visibility ?? self.visibility,
            text: text ?? self.text,
            photourl: photourl ?? self.photourl,
            lang: lang ?? self.lang,
            likes: likes ?? self.likes,
            logView: logView ?? self.logView,
            agreeCount: agreeCount ?? self.agreeCount,
            disagreeCount: disagreeCount ?? self.disagreeCount,
            todo: todo ?? self.todo,
            editedAt: editedAt ?? self.editedAt,
            authorInteractionType: authorInteractionType ?? self.authorInteractionType
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Group
class Group: Codable {
    let type, name, summary: String?
    let count: Int?
    let items: [Item]?

    init(type: String?, name: String?, summary: String?, count: Int?, items: [Item]?) {
        self.type = type
        self.name = name
        self.summary = summary
        self.count = count
        self.items = items
    }
}

// MARK: Group convenience initializers and mutators

extension Group {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Group.self, from: data)
        self.init(type: me.type, name: me.name, summary: me.summary, count: me.count, items: me.items)
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
        type: String?? = nil,
        name: String?? = nil,
        summary: String?? = nil,
        count: Int?? = nil,
        items: [Item]?? = nil
    ) -> Group {
        return Group(
            type: type ?? self.type,
            name: name ?? self.name,
            summary: summary ?? self.summary,
            count: count ?? self.count,
            items: items ?? self.items
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Tips
class Tips: Codable {
    let count: Int?

    init(count: Int?) {
        self.count = count
    }
}

// MARK: Tips convenience initializers and mutators

extension Tips {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Tips.self, from: data)
        self.init(count: me.count)
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
        count: Int?? = nil
    ) -> Tips {
        return Tips(
            count: count ?? self.count
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Inbox
class Inbox: Codable {
    let count: Int?
    let items: [InboxItem]?

    init(count: Int?, items: [InboxItem]?) {
        self.count = count
        self.items = items
    }
}

// MARK: Inbox convenience initializers and mutators

extension Inbox {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Inbox.self, from: data)
        self.init(count: me.count, items: me.items)
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
        count: Int?? = nil,
        items: [InboxItem]?? = nil
    ) -> Inbox {
        return Inbox(
            count: count ?? self.count,
            items: items ?? self.items
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - InboxItem
class InboxItem: Codable {
    let id: String?
    let createdAt: Int?
    let photo: BestPhotoClass?
    let url: String?

    init(id: String?, createdAt: Int?, photo: BestPhotoClass?, url: String?) {
        self.id = id
        self.createdAt = createdAt
        self.photo = photo
        self.url = url
    }
}

// MARK: InboxItem convenience initializers and mutators

extension InboxItem {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(InboxItem.self, from: data)
        self.init(id: me.id, createdAt: me.createdAt, photo: me.photo, url: me.url)
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
        createdAt: Int?? = nil,
        photo: BestPhotoClass?? = nil,
        url: String?? = nil
    ) -> InboxItem {
        return InboxItem(
            id: id ?? self.id,
            createdAt: createdAt ?? self.createdAt,
            photo: photo ?? self.photo,
            url: url ?? self.url
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - BestPhotoClass
class BestPhotoClass: Codable {
    let id: String?
    let createdAt: Int?
    let source: FSSource?
    let photoPrefix: String?
    let suffix: String?
    let width, height: Int?
    let visibility: String?
    let user: BestPhotoUser?

    enum CodingKeys: String, CodingKey {
        case id, createdAt, source
        case photoPrefix = "prefix"
        case suffix, width, height, visibility, user
    }

    init(id: String?, createdAt: Int?, source: FSSource?, photoPrefix: String?, suffix: String?, width: Int?, height: Int?, visibility: String?, user: BestPhotoUser?) {
        self.id = id
        self.createdAt = createdAt
        self.source = source
        self.photoPrefix = photoPrefix
        self.suffix = suffix
        self.width = width
        self.height = height
        self.visibility = visibility
        self.user = user
    }
}

// MARK: BestPhotoClass convenience initializers and mutators

extension BestPhotoClass {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(BestPhotoClass.self, from: data)
        self.init(id: me.id, createdAt: me.createdAt, source: me.source, photoPrefix: me.photoPrefix, suffix: me.suffix, width: me.width, height: me.height, visibility: me.visibility, user: me.user)
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
        createdAt: Int?? = nil,
        source: FSSource?? = nil,
        photoPrefix: String?? = nil,
        suffix: String?? = nil,
        width: Int?? = nil,
        height: Int?? = nil,
        visibility: String?? = nil,
        user: BestPhotoUser?? = nil
    ) -> BestPhotoClass {
        return BestPhotoClass(
            id: id ?? self.id,
            createdAt: createdAt ?? self.createdAt,
            source: source ?? self.source,
            photoPrefix: photoPrefix ?? self.photoPrefix,
            suffix: suffix ?? self.suffix,
            width: width ?? self.width,
            height: height ?? self.height,
            visibility: visibility ?? self.visibility,
            user: user ?? self.user
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - FSSource
class FSSource: Codable {
    let name: String?
    let url: String?

    init(name: String?, url: String?) {
        self.name = name
        self.url = url
    }
}

// MARK: Source convenience initializers and mutators

extension FSSource {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(FSSource.self, from: data)
        self.init(name: me.name, url: me.url)
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
        name: String?? = nil,
        url: String?? = nil
    ) -> FSSource {
        return FSSource(
            name: name ?? self.name,
            url: url ?? self.url
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - BestPhotoUser
class BestPhotoUser: Codable {
    let id, firstName: String?
    let photo: IconClass?
    let type, lastName: String?

    init(id: String?, firstName: String?, photo: IconClass?, type: String?, lastName: String?) {
        self.id = id
        self.firstName = firstName
        self.photo = photo
        self.type = type
        self.lastName = lastName
    }
}

// MARK: BestPhotoUser convenience initializers and mutators

extension BestPhotoUser {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(BestPhotoUser.self, from: data)
        self.init(id: me.id, firstName: me.firstName, photo: me.photo, type: me.type, lastName: me.lastName)
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
        firstName: String?? = nil,
        photo: IconClass?? = nil,
        type: String?? = nil,
        lastName: String?? = nil
    ) -> BestPhotoUser {
        return BestPhotoUser(
            id: id ?? self.id,
            firstName: firstName ?? self.firstName,
            photo: photo ?? self.photo,
            type: type ?? self.type,
            lastName: lastName ?? self.lastName
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - IconClass
class IconClass: Codable {
    let photoPrefix: String?
    let suffix: String?

    enum CodingKeys: String, CodingKey {
        case photoPrefix = "prefix"
        case suffix
    }

    init(photoPrefix: String?, suffix: String?) {
        self.photoPrefix = photoPrefix
        self.suffix = suffix
    }
}

// MARK: IconClass convenience initializers and mutators

extension IconClass {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(IconClass.self, from: data)
        self.init(photoPrefix: me.photoPrefix, suffix: me.suffix)
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
        photoPrefix: String?? = nil,
        suffix: String?? = nil
    ) -> IconClass {
        return IconClass(
            photoPrefix: photoPrefix ?? self.photoPrefix,
            suffix: suffix ?? self.suffix
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - BeenHere
class BeenHere: Codable {
    let count, unconfirmedCount: Int?
    let marked: Bool?
    let lastCheckinExpiredAt: Int?

    init(count: Int?, unconfirmedCount: Int?, marked: Bool?, lastCheckinExpiredAt: Int?) {
        self.count = count
        self.unconfirmedCount = unconfirmedCount
        self.marked = marked
        self.lastCheckinExpiredAt = lastCheckinExpiredAt
    }
}

// MARK: BeenHere convenience initializers and mutators

extension BeenHere {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(BeenHere.self, from: data)
        self.init(count: me.count, unconfirmedCount: me.unconfirmedCount, marked: me.marked, lastCheckinExpiredAt: me.lastCheckinExpiredAt)
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
        count: Int?? = nil,
        unconfirmedCount: Int?? = nil,
        marked: Bool?? = nil,
        lastCheckinExpiredAt: Int?? = nil
    ) -> BeenHere {
        return BeenHere(
            count: count ?? self.count,
            unconfirmedCount: unconfirmedCount ?? self.unconfirmedCount,
            marked: marked ?? self.marked,
            lastCheckinExpiredAt: lastCheckinExpiredAt ?? self.lastCheckinExpiredAt
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Category
class Category: Codable {
    let id, name, pluralName, shortName: String?
    let icon: IconClass?
    let primary: Bool?

    init(id: String?, name: String?, pluralName: String?, shortName: String?, icon: IconClass?, primary: Bool?) {
        self.id = id
        self.name = name
        self.pluralName = pluralName
        self.shortName = shortName
        self.icon = icon
        self.primary = primary
    }
}

// MARK: Category convenience initializers and mutators

extension Category {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Category.self, from: data)
        self.init(id: me.id, name: me.name, pluralName: me.pluralName, shortName: me.shortName, icon: me.icon, primary: me.primary)
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
        name: String?? = nil,
        pluralName: String?? = nil,
        shortName: String?? = nil,
        icon: IconClass?? = nil,
        primary: Bool?? = nil
    ) -> Category {
        return Category(
            id: id ?? self.id,
            name: name ?? self.name,
            pluralName: pluralName ?? self.pluralName,
            shortName: shortName ?? self.shortName,
            icon: icon ?? self.icon,
            primary: primary ?? self.primary
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Contact
class Contact: Codable {
    let phone, formattedPhone, twitter, instagram: String?
    let facebook, facebookUsername, facebookName: String?

    init(phone: String?, formattedPhone: String?, twitter: String?, instagram: String?, facebook: String?, facebookUsername: String?, facebookName: String?) {
        self.phone = phone
        self.formattedPhone = formattedPhone
        self.twitter = twitter
        self.instagram = instagram
        self.facebook = facebook
        self.facebookUsername = facebookUsername
        self.facebookName = facebookName
    }
}

// MARK: Contact convenience initializers and mutators

extension Contact {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Contact.self, from: data)
        self.init(phone: me.phone, formattedPhone: me.formattedPhone, twitter: me.twitter, instagram: me.instagram, facebook: me.facebook, facebookUsername: me.facebookUsername, facebookName: me.facebookName)
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
        phone: String?? = nil,
        formattedPhone: String?? = nil,
        twitter: String?? = nil,
        instagram: String?? = nil,
        facebook: String?? = nil,
        facebookUsername: String?? = nil,
        facebookName: String?? = nil
    ) -> Contact {
        return Contact(
            phone: phone ?? self.phone,
            formattedPhone: formattedPhone ?? self.formattedPhone,
            twitter: twitter ?? self.twitter,
            instagram: instagram ?? self.instagram,
            facebook: facebook ?? self.facebook,
            facebookUsername: facebookUsername ?? self.facebookUsername,
            facebookName: facebookName ?? self.facebookName
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Hours
class Hours: Codable {
    let status: String?
    let isOpen, isLocalHoliday: Bool?
    let timeframes: [Timeframe]?

    init(status: String?, isOpen: Bool?, isLocalHoliday: Bool?, timeframes: [Timeframe]?) {
        self.status = status
        self.isOpen = isOpen
        self.isLocalHoliday = isLocalHoliday
        self.timeframes = timeframes
    }
}

// MARK: Hours convenience initializers and mutators

extension Hours {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Hours.self, from: data)
        self.init(status: me.status, isOpen: me.isOpen, isLocalHoliday: me.isLocalHoliday, timeframes: me.timeframes)
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
        status: String?? = nil,
        isOpen: Bool?? = nil,
        isLocalHoliday: Bool?? = nil,
        timeframes: [Timeframe]?? = nil
    ) -> Hours {
        return Hours(
            status: status ?? self.status,
            isOpen: isOpen ?? self.isOpen,
            isLocalHoliday: isLocalHoliday ?? self.isLocalHoliday,
            timeframes: timeframes ?? self.timeframes
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Timeframe
class Timeframe: Codable {
    let days: String?
    let includesToday: Bool?
    let timeframeOpen: [Open]?
    let segments: [JSONAny]?

    enum CodingKeys: String, CodingKey {
        case days, includesToday
        case timeframeOpen = "open"
        case segments
    }

    init(days: String?, includesToday: Bool?, timeframeOpen: [Open]?, segments: [JSONAny]?) {
        self.days = days
        self.includesToday = includesToday
        self.timeframeOpen = timeframeOpen
        self.segments = segments
    }
}

// MARK: Timeframe convenience initializers and mutators

extension Timeframe {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Timeframe.self, from: data)
        self.init(days: me.days, includesToday: me.includesToday, timeframeOpen: me.timeframeOpen, segments: me.segments)
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
        days: String?? = nil,
        includesToday: Bool?? = nil,
        timeframeOpen: [Open]?? = nil,
        segments: [JSONAny]?? = nil
    ) -> Timeframe {
        return Timeframe(
            days: days ?? self.days,
            includesToday: includesToday ?? self.includesToday,
            timeframeOpen: timeframeOpen ?? self.timeframeOpen,
            segments: segments ?? self.segments
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Open
class Open: Codable {
    let renderedTime: String?

    init(renderedTime: String?) {
        self.renderedTime = renderedTime
    }
}

// MARK: Open convenience initializers and mutators

extension Open {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Open.self, from: data)
        self.init(renderedTime: me.renderedTime)
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
        renderedTime: String?? = nil
    ) -> Open {
        return Open(
            renderedTime: renderedTime ?? self.renderedTime
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Likes
class Likes: Codable {
    let count: Int?
    let summary: String?

    init(count: Int?, summary: String?) {
        self.count = count
        self.summary = summary
    }
}

// MARK: Likes convenience initializers and mutators

extension Likes {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Likes.self, from: data)
        self.init(count: me.count, summary: me.summary)
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
        count: Int?? = nil,
        summary: String?? = nil
    ) -> Likes {
        return Likes(
            count: count ?? self.count,
            summary: summary ?? self.summary
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Listed
class Listed: Codable {
    let count: Int?
    let groups: [Group]?

    init(count: Int?, groups: [Group]?) {
        self.count = count
        self.groups = groups
    }
}

// MARK: Listed convenience initializers and mutators

extension Listed {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Listed.self, from: data)
        self.init(count: me.count, groups: me.groups)
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
        count: Int?? = nil,
        groups: [Group]?? = nil
    ) -> Listed {
        return Listed(
            count: count ?? self.count,
            groups: groups ?? self.groups
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - FSLocation
class FSLocation: Codable {
    let address, crossStreet: String?
    let lat, lng: Double?
    let postalCode, cc, city, state: String?
    let country: String?
    let formattedAddress: [String]?

    init(address: String?, crossStreet: String?, lat: Double?, lng: Double?, postalCode: String?, cc: String?, city: String?, state: String?, country: String?, formattedAddress: [String]?) {
        self.address = address
        self.crossStreet = crossStreet
        self.lat = lat
        self.lng = lng
        self.postalCode = postalCode
        self.cc = cc
        self.city = city
        self.state = state
        self.country = country
        self.formattedAddress = formattedAddress
    }
}

// MARK: FSLocation convenience initializers and mutators

extension FSLocation {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(FSLocation.self, from: data)
        self.init(address: me.address, crossStreet: me.crossStreet, lat: me.lat, lng: me.lng, postalCode: me.postalCode, cc: me.cc, city: me.city, state: me.state, country: me.country, formattedAddress: me.formattedAddress)
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
        address: String?? = nil,
        crossStreet: String?? = nil,
        lat: Double?? = nil,
        lng: Double?? = nil,
        postalCode: String?? = nil,
        cc: String?? = nil,
        city: String?? = nil,
        state: String?? = nil,
        country: String?? = nil,
        formattedAddress: [String]?? = nil
    ) -> FSLocation {
        return FSLocation(
            address: address ?? self.address,
            crossStreet: crossStreet ?? self.crossStreet,
            lat: lat ?? self.lat,
            lng: lng ?? self.lng,
            postalCode: postalCode ?? self.postalCode,
            cc: cc ?? self.cc,
            city: city ?? self.city,
            state: state ?? self.state,
            country: country ?? self.country,
            formattedAddress: formattedAddress ?? self.formattedAddress
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - FSPage
class FSPage: Codable {
    let pageInfo: PageInfo?
    let user: PageUser?

    init(pageInfo: PageInfo?, user: PageUser?) {
        self.pageInfo = pageInfo
        self.user = user
    }
}

// MARK: Page convenience initializers and mutators

extension FSPage {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(FSPage.self, from: data)
        self.init(pageInfo: me.pageInfo, user: me.user)
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
        pageInfo: PageInfo?? = nil,
        user: PageUser?? = nil
    ) -> FSPage {
        return FSPage(
            pageInfo: pageInfo ?? self.pageInfo,
            user: user ?? self.user
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - PageInfo
class PageInfo: Codable {
    let pageInfoDescription: String?
    let banner: String?
    let links: Inbox?

    enum CodingKeys: String, CodingKey {
        case pageInfoDescription = "description"
        case banner, links
    }

    init(pageInfoDescription: String?, banner: String?, links: Inbox?) {
        self.pageInfoDescription = pageInfoDescription
        self.banner = banner
        self.links = links
    }
}

// MARK: PageInfo convenience initializers and mutators

extension PageInfo {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(PageInfo.self, from: data)
        self.init(pageInfoDescription: me.pageInfoDescription, banner: me.banner, links: me.links)
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
        pageInfoDescription: String?? = nil,
        banner: String?? = nil,
        links: Inbox?? = nil
    ) -> PageInfo {
        return PageInfo(
            pageInfoDescription: pageInfoDescription ?? self.pageInfoDescription,
            banner: banner ?? self.banner,
            links: links ?? self.links
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - PageUser
class PageUser: Codable {
    let id, firstName: String?
    let photo: IconClass?
    let type: String?
    let tips: Tips?
    let lists: Attributes?
    let bio: String?

    init(id: String?, firstName: String?, photo: IconClass?, type: String?, tips: Tips?, lists: Attributes?, bio: String?) {
        self.id = id
        self.firstName = firstName
        self.photo = photo
        self.type = type
        self.tips = tips
        self.lists = lists
        self.bio = bio
    }
}

// MARK: PageUser convenience initializers and mutators

extension PageUser {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(PageUser.self, from: data)
        self.init(id: me.id, firstName: me.firstName, photo: me.photo, type: me.type, tips: me.tips, lists: me.lists, bio: me.bio)
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
        firstName: String?? = nil,
        photo: IconClass?? = nil,
        type: String?? = nil,
        tips: Tips?? = nil,
        lists: Attributes?? = nil,
        bio: String?? = nil
    ) -> PageUser {
        return PageUser(
            id: id ?? self.id,
            firstName: firstName ?? self.firstName,
            photo: photo ?? self.photo,
            type: type ?? self.type,
            tips: tips ?? self.tips,
            lists: lists ?? self.lists,
            bio: bio ?? self.bio
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Phrase
class Phrase: Codable {
    let phrase: String?
    let sample: Sample?
    let count: Int?

    init(phrase: String?, sample: Sample?, count: Int?) {
        self.phrase = phrase
        self.sample = sample
        self.count = count
    }
}

// MARK: Phrase convenience initializers and mutators

extension Phrase {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Phrase.self, from: data)
        self.init(phrase: me.phrase, sample: me.sample, count: me.count)
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
        phrase: String?? = nil,
        sample: Sample?? = nil,
        count: Int?? = nil
    ) -> Phrase {
        return Phrase(
            phrase: phrase ?? self.phrase,
            sample: sample ?? self.sample,
            count: count ?? self.count
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Sample
class Sample: Codable {
    let entities: [Entity]?
    let text: String?

    init(entities: [Entity]?, text: String?) {
        self.entities = entities
        self.text = text
    }
}

// MARK: Sample convenience initializers and mutators

extension Sample {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Sample.self, from: data)
        self.init(entities: me.entities, text: me.text)
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
        entities: [Entity]?? = nil,
        text: String?? = nil
    ) -> Sample {
        return Sample(
            entities: entities ?? self.entities,
            text: text ?? self.text
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Entity
class Entity: Codable {
    let indices: [Int]?
    let type: String?

    init(indices: [Int]?, type: String?) {
        self.indices = indices
        self.type = type
    }
}

// MARK: Entity convenience initializers and mutators

extension Entity {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Entity.self, from: data)
        self.init(indices: me.indices, type: me.type)
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
        indices: [Int]?? = nil,
        type: String?? = nil
    ) -> Entity {
        return Entity(
            indices: indices ?? self.indices,
            type: type ?? self.type
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Stats
class Stats: Codable {
    let checkinsCount, usersCount, tipCount, visitsCount: Int?

    init(checkinsCount: Int?, usersCount: Int?, tipCount: Int?, visitsCount: Int?) {
        self.checkinsCount = checkinsCount
        self.usersCount = usersCount
        self.tipCount = tipCount
        self.visitsCount = visitsCount
    }
}

// MARK: Stats convenience initializers and mutators

extension Stats {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Stats.self, from: data)
        self.init(checkinsCount: me.checkinsCount, usersCount: me.usersCount, tipCount: me.tipCount, visitsCount: me.visitsCount)
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
        checkinsCount: Int?? = nil,
        usersCount: Int?? = nil,
        tipCount: Int?? = nil,
        visitsCount: Int?? = nil
    ) -> Stats {
        return Stats(
            checkinsCount: checkinsCount ?? self.checkinsCount,
            usersCount: usersCount ?? self.usersCount,
            tipCount: tipCount ?? self.tipCount,
            visitsCount: visitsCount ?? self.visitsCount
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - SuggestedFilters
class SuggestedFilters: Codable {
    let header: String?
    let filters: [Filter]?

    init(header: String?, filters: [Filter]?) {
        self.header = header
        self.filters = filters
    }
}

// MARK: SuggestedFilters convenience initializers and mutators

extension SuggestedFilters {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(SuggestedFilters.self, from: data)
        self.init(header: me.header, filters: me.filters)
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
        header: String?? = nil,
        filters: [Filter]?? = nil
    ) -> SuggestedFilters {
        return SuggestedFilters(
            header: header ?? self.header,
            filters: filters ?? self.filters
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Filter
class Filter: Codable {
    let name, key: String?

    init(name: String?, key: String?) {
        self.name = name
        self.key = key
    }
}

// MARK: Filter convenience initializers and mutators

extension Filter {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Filter.self, from: data)
        self.init(name: me.name, key: me.key)
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
        name: String?? = nil,
        key: String?? = nil
    ) -> Filter {
        return Filter(
            name: name ?? self.name,
            key: key ?? self.key
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}
