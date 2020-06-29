//
//  SygicPlacesSearchResult.swift
//  Plot
//
//  Created by Cory McHattie on 6/17/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let sygicPlacesSearchResult = try SygicPlacesSearchResult(json)

import Foundation

// MARK: - SygicPlacesSearchResult
class SygicPlacesSearchResult: Codable {
    let statusCode: Int?
    let data: PlaceData?
    let serverTimestamp: Date?

    enum CodingKeys: String, CodingKey {
        case statusCode = "status_code"
        case data
        case serverTimestamp = "server_timestamp"
    }

    init(statusCode: Int?, data: PlaceData?, serverTimestamp: Date?) {
        self.statusCode = statusCode
        self.data = data
        self.serverTimestamp = serverTimestamp
    }
}

// MARK: SygicPlacesSearchResult convenience initializers and mutators

extension SygicPlacesSearchResult {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(SygicPlacesSearchResult.self, from: data)
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
        data: PlaceData?? = nil,
        serverTimestamp: Date?? = nil
    ) -> SygicPlacesSearchResult {
        return SygicPlacesSearchResult(
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

// MARK: - PlaceData
class PlaceData: Codable {
    let places: [SygicPlace]?
    let place: SygicPlace?

    init(places: [SygicPlace]?, place: SygicPlace?) {
        self.places = places
        self.place = place
    }
}

// MARK: PlaceData convenience initializers and mutators

extension PlaceData {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(PlaceData.self, from: data)
        self.init(places: me.places, place: me.place)
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
        places: [SygicPlace]?? = nil,
        place: SygicPlace?? = nil
    ) -> PlaceData {
        return PlaceData(
            places: places ?? self.places,
            place: place ?? self.place
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Place
class SygicPlace: Codable {
    let id: String
    let level: String?
    let rating, ratingLocal: Double?
    let quadkey: String?
    let location: SygicLocation?
    let boundingBox: BoundingBox?
    let name, nameSuffix, originalName: String?
    let url: String?
    let duration: Int?
    let marker: String?
    let categories, parentIDS: [String]?
    let perex: String?
    let customerRating, starRating, starRatingUnofficial: Double?
    let thumbnailURL: String?
    let tags: [Tag]?
    let area: Int?
    let address: String?
    let addressIsApproximated: Bool?
    let admission: String?
    let email: String?
    let openingHours: String?
    let isDeleted: Bool?
    let phone: String?
    let placeDescription: Description?
    let openingHoursRaw: String?
    let mediaCount: Int?
    let mainMedia: MainMedia?
    let references: [Reference]?
    let externalIDS: [ExternalID]?
    let collectionCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, level, rating
        case ratingLocal = "rating_local"
        case quadkey, location
        case boundingBox = "bounding_box"
        case name
        case nameSuffix = "name_suffix"
        case originalName = "original_name"
        case url, duration, marker, categories
        case parentIDS = "parent_ids"
        case perex
        case customerRating = "customer_rating"
        case starRating = "star_rating"
        case starRatingUnofficial = "star_rating_unofficial"
        case thumbnailURL = "thumbnail_url"
        case tags, area, address
        case addressIsApproximated = "address_is_approximated"
        case admission, email
        case openingHours = "opening_hours"
        case isDeleted = "is_deleted"
        case phone
        case placeDescription = "description"
        case openingHoursRaw = "opening_hours_raw"
        case mediaCount = "media_count"
        case mainMedia = "main_media"
        case references
        case externalIDS = "external_ids"
        case collectionCount = "collection_count"
    }

    init(id: String, level: String?, rating: Double?, ratingLocal: Double?, quadkey: String?, location: SygicLocation?, boundingBox: BoundingBox?, name: String?, nameSuffix: String?, originalName: String?, url: String?, duration: Int?, marker: String?, categories: [String]?, parentIDS: [String]?, perex: String?, customerRating: Double?, starRating: Double?, starRatingUnofficial: Double?, thumbnailURL: String?, tags: [Tag]?, area: Int?, address: String?, addressIsApproximated: Bool?, admission: String?, email: String?, openingHours: String?, isDeleted: Bool?, phone: String?, placeDescription: Description?, openingHoursRaw: String?, mediaCount: Int?, mainMedia: MainMedia?, references: [Reference]?, externalIDS: [ExternalID]?, collectionCount: Int?) {
        self.id = id
        self.level = level
        self.rating = rating
        self.ratingLocal = ratingLocal
        self.quadkey = quadkey
        self.location = location
        self.boundingBox = boundingBox
        self.name = name
        self.nameSuffix = nameSuffix
        self.originalName = originalName
        self.url = url
        self.duration = duration
        self.marker = marker
        self.categories = categories
        self.parentIDS = parentIDS
        self.perex = perex
        self.customerRating = customerRating
        self.starRating = starRating
        self.starRatingUnofficial = starRatingUnofficial
        self.thumbnailURL = thumbnailURL
        self.tags = tags
        self.area = area
        self.address = address
        self.addressIsApproximated = addressIsApproximated
        self.admission = admission
        self.email = email
        self.openingHours = openingHours
        self.isDeleted = isDeleted
        self.phone = phone
        self.placeDescription = placeDescription
        self.openingHoursRaw = openingHoursRaw
        self.mediaCount = mediaCount
        self.mainMedia = mainMedia
        self.references = references
        self.externalIDS = externalIDS
        self.collectionCount = collectionCount
    }
}

// MARK: SygicPlace convenience initializers and mutators

extension SygicPlace {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(SygicPlace.self, from: data)
        self.init(id: me.id, level: me.level, rating: me.rating, ratingLocal: me.ratingLocal, quadkey: me.quadkey, location: me.location, boundingBox: me.boundingBox, name: me.name, nameSuffix: me.nameSuffix, originalName: me.originalName, url: me.url, duration: me.duration, marker: me.marker, categories: me.categories, parentIDS: me.parentIDS, perex: me.perex, customerRating: me.customerRating, starRating: me.starRating, starRatingUnofficial: me.starRatingUnofficial, thumbnailURL: me.thumbnailURL, tags: me.tags, area: me.area, address: me.address, addressIsApproximated: me.addressIsApproximated, admission: me.admission, email: me.email, openingHours: me.openingHours, isDeleted: me.isDeleted, phone: me.phone, placeDescription: me.placeDescription, openingHoursRaw: me.openingHoursRaw, mediaCount: me.mediaCount, mainMedia: me.mainMedia, references: me.references, externalIDS: me.externalIDS, collectionCount: me.collectionCount)
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
        level: String?? = nil,
        rating: Double?? = nil,
        ratingLocal: Double?? = nil,
        quadkey: String?? = nil,
        location: SygicLocation?? = nil,
        boundingBox: BoundingBox?? = nil,
        name: String?? = nil,
        nameSuffix: String?? = nil,
        originalName: String?? = nil,
        url: String?? = nil,
        duration: Int?? = nil,
        marker: String?? = nil,
        categories: [String]?? = nil,
        parentIDS: [String]?? = nil,
        perex: String?? = nil,
        customerRating: Double?? = nil,
        starRating: Double?? = nil,
        starRatingUnofficial: Double?? = nil,
        thumbnailURL: String?? = nil,
        tags: [Tag]?? = nil,
        area: Int?? = nil,
        address: String?? = nil,
        addressIsApproximated: Bool?? = nil,
        admission: String?? = nil,
        email: String?? = nil,
        openingHours: String?? = nil,
        isDeleted: Bool?? = nil,
        phone: String?? = nil,
        placeDescription: Description?? = nil,
        openingHoursRaw: String?? = nil,
        mediaCount: Int?? = nil,
        mainMedia: MainMedia?? = nil,
        references: [Reference]?? = nil,
        externalIDS: [ExternalID]?? = nil,
        collectionCount: Int?? = nil
    ) -> SygicPlace {
        return SygicPlace(
            id: id,
            level: level ?? self.level,
            rating: rating ?? self.rating,
            ratingLocal: ratingLocal ?? self.ratingLocal,
            quadkey: quadkey ?? self.quadkey,
            location: location ?? self.location,
            boundingBox: boundingBox ?? self.boundingBox,
            name: name ?? self.name,
            nameSuffix: nameSuffix ?? self.nameSuffix,
            originalName: originalName ?? self.originalName,
            url: url ?? self.url,
            duration: duration ?? self.duration,
            marker: marker ?? self.marker,
            categories: categories ?? self.categories,
            parentIDS: parentIDS ?? self.parentIDS,
            perex: perex ?? self.perex,
            customerRating: customerRating ?? self.customerRating,
            starRating: starRating ?? self.starRating,
            starRatingUnofficial: starRatingUnofficial ?? self.starRatingUnofficial,
            thumbnailURL: thumbnailURL ?? self.thumbnailURL,
            tags: tags ?? self.tags,
            area: area ?? self.area,
            address: address ?? self.address,
            addressIsApproximated: addressIsApproximated ?? self.addressIsApproximated,
            admission: admission ?? self.admission,
            email: email ?? self.email,
            openingHours: openingHours ?? self.openingHours,
            isDeleted: isDeleted ?? self.isDeleted,
            phone: phone ?? self.phone,
            placeDescription: placeDescription ?? self.placeDescription,
            openingHoursRaw: openingHoursRaw ?? self.openingHoursRaw,
            mediaCount: mediaCount ?? self.mediaCount,
            mainMedia: mainMedia ?? self.mainMedia,
            references: references ?? self.references,
            externalIDS: externalIDS ?? self.externalIDS,
            collectionCount: collectionCount ?? self.collectionCount
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - BoundingBox
class BoundingBox: Codable {
    let south, west, north, east: Double?

    init(south: Double?, west: Double?, north: Double?, east: Double?) {
        self.south = south
        self.west = west
        self.north = north
        self.east = east
    }
}

// MARK: BoundingBox convenience initializers and mutators

extension BoundingBox {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(BoundingBox.self, from: data)
        self.init(south: me.south, west: me.west, north: me.north, east: me.east)
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
        south: Double?? = nil,
        west: Double?? = nil,
        north: Double?? = nil,
        east: Double?? = nil
    ) -> BoundingBox {
        return BoundingBox(
            south: south ?? self.south,
            west: west ?? self.west,
            north: north ?? self.north,
            east: east ?? self.east
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - ExternalID
class ExternalID: Codable {
    let id, type: String?
    let languageID: String?

    enum CodingKeys: String, CodingKey {
        case id, type
        case languageID = "language_id"
    }

    init(id: String?, type: String?, languageID: String?) {
        self.id = id
        self.type = type
        self.languageID = languageID
    }
}

// MARK: ExternalID convenience initializers and mutators

extension ExternalID {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(ExternalID.self, from: data)
        self.init(id: me.id, type: me.type, languageID: me.languageID)
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
        type: String?? = nil,
        languageID: String?? = nil
    ) -> ExternalID {
        return ExternalID(
            id: id ?? self.id,
            type: type ?? self.type,
            languageID: languageID ?? self.languageID
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - SygicLocation
class SygicLocation: Codable {
    let lat, lng: Double?

    init(lat: Double?, lng: Double?) {
        self.lat = lat
        self.lng = lng
    }
}

// MARK: SygicLocation convenience initializers and mutators

extension SygicLocation {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(SygicLocation.self, from: data)
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
    ) -> SygicLocation {
        return SygicLocation(
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

// MARK: - MainMedia
class MainMedia: Codable {
    let usage: Usage?
    let media: [PlaceMedia]?

    init(usage: Usage?, media: [PlaceMedia]?) {
        self.usage = usage
        self.media = media
    }
}

// MARK: MainMedia convenience initializers and mutators

extension MainMedia {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(MainMedia.self, from: data)
        self.init(usage: me.usage, media: me.media)
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
        usage: Usage?? = nil,
        media: [PlaceMedia]?? = nil
    ) -> MainMedia {
        return MainMedia(
            usage: usage ?? self.usage,
            media: media ?? self.media
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - PlaceMedia
class PlaceMedia: Codable {
    let original: Original?
    let suitability: [String]?
    let urlTemplate: String?
    let createdAt: Date?
    let source: Source?
    let type: String?
    let createdBy: String?
    let url: String?
    let quadkey: String?
    let attribution: Attribution?
    let location: SygicLocation?
    let id: String?

    enum CodingKeys: String, CodingKey {
        case original, suitability
        case urlTemplate = "url_template"
        case createdAt = "created_at"
        case source, type
        case createdBy = "created_by"
        case url, quadkey, attribution, location, id
    }

    init(original: Original?, suitability: [String]?, urlTemplate: String?, createdAt: Date?, source: Source?, type: String?, createdBy: String?, url: String?, quadkey: String?, attribution: Attribution?, location: SygicLocation?, id: String?) {
        self.original = original
        self.suitability = suitability
        self.urlTemplate = urlTemplate
        self.createdAt = createdAt
        self.source = source
        self.type = type
        self.createdBy = createdBy
        self.url = url
        self.quadkey = quadkey
        self.attribution = attribution
        self.location = location
        self.id = id
    }
}

// MARK: PlaceMedia convenience initializers and mutators

extension PlaceMedia {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(PlaceMedia.self, from: data)
        self.init(original: me.original, suitability: me.suitability, urlTemplate: me.urlTemplate, createdAt: me.createdAt, source: me.source, type: me.type, createdBy: me.createdBy, url: me.url, quadkey: me.quadkey, attribution: me.attribution, location: me.location, id: me.id)
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
        original: Original?? = nil,
        suitability: [String]?? = nil,
        urlTemplate: String?? = nil,
        createdAt: Date?? = nil,
        source: Source?? = nil,
        type: String?? = nil,
        createdBy: String?? = nil,
        url: String?? = nil,
        quadkey: String?? = nil,
        attribution: Attribution?? = nil,
        location: SygicLocation?? = nil,
        id: String?? = nil
    ) -> PlaceMedia {
        return PlaceMedia(
            original: original ?? self.original,
            suitability: suitability ?? self.suitability,
            urlTemplate: urlTemplate ?? self.urlTemplate,
            createdAt: createdAt ?? self.createdAt,
            source: source ?? self.source,
            type: type ?? self.type,
            createdBy: createdBy ?? self.createdBy,
            url: url ?? self.url,
            quadkey: quadkey ?? self.quadkey,
            attribution: attribution ?? self.attribution,
            location: location ?? self.location,
            id: id ?? self.id
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Attribution
class Attribution: Codable {
    let titleURL: String?
    let license: String?
    let other: String?
    let authorURL: String?
    let author, title: String?
    let licenseURL: String?

    enum CodingKeys: String, CodingKey {
        case titleURL = "title_url"
        case license, other
        case authorURL = "author_url"
        case author, title
        case licenseURL = "license_url"
    }

    init(titleURL: String?, license: String?, other: String?, authorURL: String?, author: String?, title: String?, licenseURL: String?) {
        self.titleURL = titleURL
        self.license = license
        self.other = other
        self.authorURL = authorURL
        self.author = author
        self.title = title
        self.licenseURL = licenseURL
    }
}

// MARK: Attribution convenience initializers and mutators

extension Attribution {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Attribution.self, from: data)
        self.init(titleURL: me.titleURL, license: me.license, other: me.other, authorURL: me.authorURL, author: me.author, title: me.title, licenseURL: me.licenseURL)
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
        titleURL: String?? = nil,
        license: String?? = nil,
        other: String?? = nil,
        authorURL: String?? = nil,
        author: String?? = nil,
        title: String?? = nil,
        licenseURL: String?? = nil
    ) -> Attribution {
        return Attribution(
            titleURL: titleURL ?? self.titleURL,
            license: license ?? self.license,
            other: other ?? self.other,
            authorURL: authorURL ?? self.authorURL,
            author: author ?? self.author,
            title: title ?? self.title,
            licenseURL: licenseURL ?? self.licenseURL
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Original
class Original: Codable {
    let size: Int?
    let width, height: Int?

    init(size: Int?, width: Int?, height: Int?) {
        self.size = size
        self.width = width
        self.height = height
    }
}

// MARK: Original convenience initializers and mutators

extension Original {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Original.self, from: data)
        self.init(size: me.size, width: me.width, height: me.height)
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
        size: Int?? = nil,
        width: Int?? = nil,
        height: Int?? = nil
    ) -> Original {
        return Original(
            size: size ?? self.size,
            width: width ?? self.width,
            height: height ?? self.height
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Source
class Source: Codable {
    let provider: String?
    let name: String?
    let externalID: String?

    enum CodingKeys: String, CodingKey {
        case provider, name
        case externalID = "external_id"
    }

    init(provider: String?, name: String?, externalID: String?) {
        self.provider = provider
        self.name = name
        self.externalID = externalID
    }
}

// MARK: Source convenience initializers and mutators

extension Source {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Source.self, from: data)
        self.init(provider: me.provider, name: me.name, externalID: me.externalID)
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
        provider: String?? = nil,
        name: String?? = nil,
        externalID: String?? = nil
    ) -> Source {
        return Source(
            provider: provider ?? self.provider,
            name: name ?? self.name,
            externalID: externalID ?? self.externalID
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Usage
class Usage: Codable {
    let square, videoPreview, portrait, landscape: String?

    enum CodingKeys: String, CodingKey {
        case square
        case videoPreview = "video_preview"
        case portrait, landscape
    }

    init(square: String?, videoPreview: String?, portrait: String?, landscape: String?) {
        self.square = square
        self.videoPreview = videoPreview
        self.portrait = portrait
        self.landscape = landscape
    }
}

// MARK: Usage convenience initializers and mutators

extension Usage {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Usage.self, from: data)
        self.init(square: me.square, videoPreview: me.videoPreview, portrait: me.portrait, landscape: me.landscape)
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
        square: String?? = nil,
        videoPreview: String?? = nil,
        portrait: String?? = nil,
        landscape: String?? = nil
    ) -> Usage {
        return Usage(
            square: square ?? self.square,
            videoPreview: videoPreview ?? self.videoPreview,
            portrait: portrait ?? self.portrait,
            landscape: landscape ?? self.landscape
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Description
class Description: Codable {
    let text: String?
    let provider, translationProvider: String?
    let link: String?
    let isTranslated: Bool?

    enum CodingKeys: String, CodingKey {
        case text, provider
        case translationProvider = "translation_provider"
        case link
        case isTranslated = "is_translated"
    }

    init(text: String?, provider: String?, translationProvider: String?, link: String?, isTranslated: Bool?) {
        self.text = text
        self.provider = provider
        self.translationProvider = translationProvider
        self.link = link
        self.isTranslated = isTranslated
    }
}

// MARK: Description convenience initializers and mutators

extension Description {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Description.self, from: data)
        self.init(text: me.text, provider: me.provider, translationProvider: me.translationProvider, link: me.link, isTranslated: me.isTranslated)
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
        text: String?? = nil,
        provider: String?? = nil,
        translationProvider: String?? = nil,
        link: String?? = nil,
        isTranslated: Bool?? = nil
    ) -> Description {
        return Description(
            text: text ?? self.text,
            provider: provider ?? self.provider,
            translationProvider: translationProvider ?? self.translationProvider,
            link: link ?? self.link,
            isTranslated: isTranslated ?? self.isTranslated
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Reference
class Reference: Codable {
    let id: Int?
    let title, type: String?
    let languageID: String?
    let url: String?
    let supplier: String?
    let priority: Int?
    let currency: String?
    let price: Double?
    let flags: [String]?

    enum CodingKeys: String, CodingKey {
        case id, title, type
        case languageID = "language_id"
        case url, supplier, priority, currency, price, flags
    }

    init(id: Int?, title: String?, type: String?, languageID: String?, url: String?, supplier: String?, priority: Int?, currency: String?, price: Double?, flags: [String]?) {
        self.id = id
        self.title = title
        self.type = type
        self.languageID = languageID
        self.url = url
        self.supplier = supplier
        self.priority = priority
        self.currency = currency
        self.price = price
        self.flags = flags
    }
}

// MARK: Reference convenience initializers and mutators

extension Reference {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Reference.self, from: data)
        self.init(id: me.id, title: me.title, type: me.type, languageID: me.languageID, url: me.url, supplier: me.supplier, priority: me.priority, currency: me.currency, price: me.price, flags: me.flags)
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
        id: Int?? = nil,
        title: String?? = nil,
        type: String?? = nil,
        languageID: String?? = nil,
        url: String?? = nil,
        supplier: String?? = nil,
        priority: Int?? = nil,
        currency: String?? = nil,
        price: Double?? = nil,
        flags: [String]?? = nil
    ) -> Reference {
        return Reference(
            id: id ?? self.id,
            title: title ?? self.title,
            type: type ?? self.type,
            languageID: languageID ?? self.languageID,
            url: url ?? self.url,
            supplier: supplier ?? self.supplier,
            priority: priority ?? self.priority,
            currency: currency ?? self.currency,
            price: price ?? self.price,
            flags: flags ?? self.flags
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Tag
class Tag: Codable {
    let key, name: String?

    init(key: String?, name: String?) {
        self.key = key
        self.name = name
    }
}

// MARK: Tag convenience initializers and mutators

extension Tag {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Tag.self, from: data)
        self.init(key: me.key, name: me.name)
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
        key: String?? = nil,
        name: String?? = nil
    ) -> Tag {
        return Tag(
            key: key ?? self.key,
            name: name ?? self.name
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}
