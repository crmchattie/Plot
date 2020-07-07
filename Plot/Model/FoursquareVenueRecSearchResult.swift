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
struct FoursquareRecVenueSearchResult: Codable, Equatable, Hashable {
    let meta: Meta?
    let response: RecResponse?

    init(meta: Meta?, response: RecResponse?) {
        self.meta = meta
        self.response = response
    }
}

// MARK: - Meta
struct Meta: Codable, Equatable, Hashable {
    let code: Int?
    let requestID: String?

    enum CodingKeys: String, CodingKey {
        case code
        case requestID = "requestId"
    }
}

// MARK: - Response
struct RecResponse: Codable, Equatable, Hashable {
    let suggestedFilters: SuggestedFilters?
    let suggestedRadius: Int?
    let headerLocation, headerFullLocation, headerLocationGranularity, query: String?
    let totalResults: Int?
    let suggestedBounds: SuggestedBounds?
    let groups: [Group]?
}

// MARK: - Group
struct Group: Codable, Equatable, Hashable {
    let type, name: String?
    let items: [GroupItem]?
}

// MARK: - GroupItem
struct GroupItem: Codable, Equatable, Hashable {
    let reasons: Reasons?
    let venue: FSVenue?
    let referralID: String?

    enum CodingKeys: String, CodingKey {
        case reasons, venue
        case referralID = "referralId"
    }
}

// MARK: - Reasons
struct Reasons: Codable, Equatable, Hashable {
    let count: Int?
    let items: [ReasonsItem]?
}

// MARK: - ReasonsItem
struct ReasonsItem: Codable, Equatable, Hashable {
    let summary: String?
    let type: String?
    let reasonName: String?
}

// MARK: - Category
struct Category: Codable, Equatable, Hashable {
    let id, name, pluralName, shortName: String?
    let icon: CategoryIcon?
    let primary: Bool?
}

// MARK: - CategoryIcon
struct CategoryIcon: Codable, Equatable, Hashable {
    let iconPrefix: String?
    let suffix: String?

    enum CodingKeys: String, CodingKey {
        case iconPrefix = "prefix"
        case suffix
    }
}

// MARK: - Delivery
struct Delivery: Codable, Equatable, Hashable {
    let id: String?
    let url: String?
    let provider: Provider?
}

// MARK: - Provider
struct Provider: Codable, Equatable, Hashable {
    let name: String?
    let icon: ProviderIcon?
}

// MARK: - ProviderIcon
struct ProviderIcon: Codable, Equatable, Hashable {
    let iconPrefix: String?
    let sizes: [Int]?
    let name: String?

    enum CodingKeys: String, CodingKey {
        case iconPrefix = "prefix"
        case sizes, name
    }
}

// MARK: - Location
struct FSLocation: Codable, Equatable, Hashable {
    let address, crossStreet: String?
    let lat, lng: Double?
    let labeledLatLngs: [LabeledLatLng]?
    let distance: Int?
    let postalCode: String?
    let cc: String?
    let city: String?
    let state: String?
    let country: String?
    let formattedAddress: [String]?
    let neighborhood: String?
}

// MARK: - LabeledLatLng
struct LabeledLatLng: Codable, Equatable, Hashable {
    let label: String?
    let lat, lng: Double?
}

// MARK: - Photos
struct Photos: Codable, Equatable, Hashable {
    let count: Int?
    let groups: [ListedGroup]?
}

// MARK: - VenuePage
struct VenuePage: Codable, Equatable, Hashable {
    let id: String?
}

// MARK: - SuggestedBounds
struct SuggestedBounds: Codable, Equatable, Hashable {
    let ne, sw: Ne?
}

// MARK: - Ne
struct Ne: Codable, Equatable, Hashable {
    let lat, lng: Double?
}

// MARK: - SuggestedFilters
struct SuggestedFilters: Codable, Equatable, Hashable {
    let header: String?
    let filters: [Filter]?
}

// MARK: - Filter
struct Filter: Codable, Equatable, Hashable {
    let name, key: String?
}

// MARK: - FSVenue
struct FSVenue: Codable, Equatable, Hashable {
    let uuid = UUID().uuidString
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
        case timeZone, listed, phrases, hours, popular, pageUpdates, inbox, attributes, bestPhoto
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}

func ==(lhs: FSVenue, rhs: FSVenue) -> Bool {
    return lhs.uuid == rhs.uuid
}

// MARK: - Attributes
struct Attributes: Codable, Equatable, Hashable {
    let groups: [ListedGroup]?

    init(groups: [ListedGroup]?) {
        self.groups = groups
    }
}

// MARK: - HereNow
struct HereNow: Codable, Equatable, Hashable {
    let count: Int?
    let groups: [ListedGroup]?
    let summary: String?

    init(count: Int?, groups: [ListedGroup]?, summary: String?) {
        self.count = count
        self.groups = groups
        self.summary = summary
    }
}

// MARK: - Item
struct Item: Codable, Equatable, Hashable {
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

// MARK: - Group
struct ListedGroup: Codable, Equatable, Hashable {
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

// MARK: - Tips
struct Tips: Codable, Equatable, Hashable {
    let count: Int?

    init(count: Int?) {
        self.count = count
    }
}

// MARK: - Inbox
struct Inbox: Codable, Equatable, Hashable {
    let count: Int?
    let items: [InboxItem]?

    init(count: Int?, items: [InboxItem]?) {
        self.count = count
        self.items = items
    }
}

// MARK: - InboxItem
struct InboxItem: Codable, Equatable, Hashable {
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

// MARK: - BestPhotoClass
struct BestPhotoClass: Codable, Equatable, Hashable {
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

// MARK: - FSSource
struct FSSource: Codable, Equatable, Hashable {
    let name: String?
    let url: String?

    init(name: String?, url: String?) {
        self.name = name
        self.url = url
    }
}

// MARK: - BestPhotoUser
struct BestPhotoUser: Codable, Equatable, Hashable {
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

// MARK: - IconClass
struct IconClass: Codable, Equatable, Hashable {
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

// MARK: - BeenHere
struct BeenHere: Codable, Equatable, Hashable {
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

// MARK: - Contact
struct Contact: Codable, Equatable, Hashable {
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

// MARK: - Hours
struct Hours: Codable, Equatable, Hashable {
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

// MARK: - Timeframe
struct Timeframe: Codable, Equatable, Hashable {
    let days: String?
    let includesToday: Bool?
    let timeframeOpen: [Open]?

    enum CodingKeys: String, CodingKey {
        case days, includesToday
        case timeframeOpen = "open"
    }

    init(days: String?, includesToday: Bool?, timeframeOpen: [Open]?) {
        self.days = days
        self.includesToday = includesToday
        self.timeframeOpen = timeframeOpen
    }
}

// MARK: - Open
struct Open: Codable, Equatable, Hashable {
    let renderedTime: String?

    init(renderedTime: String?) {
        self.renderedTime = renderedTime
    }
}

// MARK: - Likes
struct Likes: Codable, Equatable, Hashable {
    let count: Int?
    let summary: String?

    init(count: Int?, summary: String?) {
        self.count = count
        self.summary = summary
    }
}

// MARK: - Listed
struct Listed: Codable, Equatable, Hashable {
    let count: Int?
    let groups: [ListedGroup]?

    init(count: Int?, groups: [ListedGroup]?) {
        self.count = count
        self.groups = groups
    }
}

// MARK: - FSPage
struct FSPage: Codable, Equatable, Hashable {
    let pageInfo: PageInfo?
    let user: PageUser?

    init(pageInfo: PageInfo?, user: PageUser?) {
        self.pageInfo = pageInfo
        self.user = user
    }
}

// MARK: - PageInfo
struct PageInfo: Codable, Equatable, Hashable {
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

// MARK: - PageUser
struct PageUser: Codable, Equatable, Hashable {
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

// MARK: - Phrase
struct Phrase: Codable, Equatable, Hashable {
    let phrase: String?
    let sample: Sample?
    let count: Int?

    init(phrase: String?, sample: Sample?, count: Int?) {
        self.phrase = phrase
        self.sample = sample
        self.count = count
    }
}

// MARK: - Sample
struct Sample: Codable, Equatable, Hashable {
    let entities: [Entity]?
    let text: String?

    init(entities: [Entity]?, text: String?) {
        self.entities = entities
        self.text = text
    }
}

// MARK: - Entity
struct Entity: Codable, Equatable, Hashable {
    let indices: [Int]?
    let type: String?

    init(indices: [Int]?, type: String?) {
        self.indices = indices
        self.type = type
    }
}

// MARK: - Stats
struct Stats: Codable, Equatable, Hashable {
    let checkinsCount, usersCount, tipCount, visitsCount: Int?

    init(checkinsCount: Int?, usersCount: Int?, tipCount: Int?, visitsCount: Int?) {
        self.checkinsCount = checkinsCount
        self.usersCount = usersCount
        self.tipCount = tipCount
        self.visitsCount = visitsCount
    }
}
