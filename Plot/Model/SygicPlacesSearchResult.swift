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
struct SygicPlacesSearchResult: Codable, Equatable, Hashable {
    let statusCode: Int?
    let data: PlaceData?
    let serverTimestamp: String?

    enum CodingKeys: String, CodingKey {
        case statusCode = "status_code"
        case data
        case serverTimestamp = "server_timestamp"
    }

    init(statusCode: Int?, data: PlaceData?, serverTimestamp: String?) {
        self.statusCode = statusCode
        self.data = data
        self.serverTimestamp = serverTimestamp
    }
}

// MARK: - PlaceData
struct PlaceData: Codable, Equatable, Hashable {
    let places: [SygicPlace]?
    let place: SygicPlace?

    init(places: [SygicPlace]?, place: SygicPlace?) {
        self.places = places
        self.place = place
    }
}

// MARK: - Place
struct SygicPlace: Codable, Equatable, Hashable {
    let uuid = UUID().uuidString
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
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}

func ==(lhs: SygicPlace, rhs: SygicPlace) -> Bool {
    return lhs.uuid == rhs.uuid
}

// MARK: - BoundingBox
struct BoundingBox: Codable, Equatable, Hashable {
    let south, west, north, east: Double?

    init(south: Double?, west: Double?, north: Double?, east: Double?) {
        self.south = south
        self.west = west
        self.north = north
        self.east = east
    }
}

// MARK: - ExternalID
struct ExternalID: Codable, Equatable, Hashable {
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

// MARK: - SygicLocation
struct SygicLocation: Codable, Equatable, Hashable {
    let lat, lng: Double?

    init(lat: Double?, lng: Double?) {
        self.lat = lat
        self.lng = lng
    }
}

// MARK: - MainMedia
struct MainMedia: Codable, Equatable, Hashable {
    let usage: Usage?
    let media: [PlaceMedia]?

    init(usage: Usage?, media: [PlaceMedia]?) {
        self.usage = usage
        self.media = media
    }
}

// MARK: - PlaceMedia
struct PlaceMedia: Codable, Equatable, Hashable {
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

// MARK: - Attribution
struct Attribution: Codable, Equatable, Hashable {
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

// MARK: - Original
struct Original: Codable, Equatable, Hashable {
    let size: Int?
    let width, height: Int?

    init(size: Int?, width: Int?, height: Int?) {
        self.size = size
        self.width = width
        self.height = height
    }
}

// MARK: - Source
struct Source: Codable, Equatable, Hashable {
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

// MARK: - Usage
struct Usage: Codable, Equatable, Hashable {
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

// MARK: - Description
struct Description: Codable, Equatable, Hashable {
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

// MARK: - Reference
struct Reference: Codable, Equatable, Hashable {
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

// MARK: - Tag
struct Tag: Codable, Equatable, Hashable {
    let key, name: String?

    init(key: String?, name: String?) {
        self.key = key
        self.name = name
    }
}
