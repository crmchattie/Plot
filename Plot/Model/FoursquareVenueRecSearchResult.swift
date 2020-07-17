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
    var name: String
    let contact: Contact?
    let location: FSLocation?
    let canonicalURL: String?
    let categories: [Category]?
    let verified: Bool?
    let stats: Stats?
    let url: String?
    let price: Price?
    let likes: Likes?
    let dislike, ok: Bool?
    let rating: Double?
    let ratingColor: String?
    let ratingSignals: Int?
    let beenHere: BeenHere?
    let photos: Listed?
    let description, storeID: String?
    let page: FSPage?
    let hereNow: HereNow?
    let createdAt: Int?
    let tips: Listed?
    let shortURL: String?
    let timeZone: String?
    let seasonalHours: [SeasonalHour]?
    let defaultHours: Hours?
    let listed: Listed?
    let phrases: [Phrase]?
    let hours, popular: Hours?
    let pageUpdates, inbox: Inbox?
    let attributes: Attributes?
    let bestPhoto: BestPhotoClass?

    enum CodingKeys: String, CodingKey {
        case id, name, contact, location
        case canonicalURL = "canonicalUrl"
        case categories, verified, stats, url, likes, rating, ratingColor, ratingSignals, beenHere, photos, description
        case storeID = "storeId"
        case page, hereNow, createdAt, tips
        case shortURL = "shortUrl"
        case timeZone, listed, phrases, hours, popular, pageUpdates, inbox, attributes, bestPhoto, seasonalHours, defaultHours, price, dislike, ok
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

// MARK: - Price
struct Price: Codable, Equatable, Hashable {
    let tier: Int?
    let message, currency: String?
}

// MARK: - SeasonalHour
struct SeasonalHour: Codable, Equatable, Hashable {
    let seasonalRange: String?
    let timeframes: [Timeframe]?
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

let FoursquareCategoryDictionary: [String: String] = ["Dive Spot": "52e81612bcbc57f1066b7a12", "Outdoor Gym": "58daa1558bbb0b01f18ec203", "Mountain": "4eb1d4d54b900d56c88a45fc", "Park": "4bf58dd8d48988d163941735", "Boxing Gym": "52f2ab2ebcbc57f1066b8b47", "Cave": "56aa371be4b08b9a8d573511", "Wine Bar": "4bf58dd8d48988d123941735", "Hardware Store": "4bf58dd8d48988d112951735", "Fish Market": "4bf58dd8d48988d10e951735", "Shipping Store": "52f2ab2ebcbc57f1066b8b1f", "Botanical Garden": "52e81612bcbc57f1066b7a22", "Pub": "4bf58dd8d48988d11b941735", "Italian Restaurant": "4bf58dd8d48988d110941735", "Yoga Studio": "4bf58dd8d48988d102941735", "Sake Bar": "4bf58dd8d48988d11c941735", "Harbor / Marina": "4bf58dd8d48988d1e0941735", "Whiskey Bar": "4bf58dd8d48988d122941735", "Shopping Mall": "4bf58dd8d48988d1fd941735", "Theme Restaurant": "56aa371be4b08b9a8d573538", "Bistro": "52e81612bcbc57f1066b79f1", "Hockey Field": "4f452cd44b9081a197eba860", "French Restaurant": "4bf58dd8d48988d10c941735", "Pakistani Restaurant": "52e81612bcbc57f1066b79f8", "Korean Restaurant": "4bf58dd8d48988d113941735", "Filipino Restaurant": "4eb1bd1c3b7b55596b4a748f", "Indian Restaurant": "4bf58dd8d48988d10f941735", "Playground": "4bf58dd8d48988d1e7941735", "Buffet": "52e81612bcbc57f1066b79f4", "Organic Grocery": "52f2ab2ebcbc57f1066b8b45", "Skate Park": "4bf58dd8d48988d167941735", "Gastropub": "4bf58dd8d48988d155941735", "Bookstore": "4bf58dd8d48988d114951735", "Middle Eastern Restaurant": "4bf58dd8d48988d115941735", "Tibetan Restaurant": "52af39fb3cf9994f4e043be9", "Clothing Boutique": "4bf58dd8d48988d104951735", "Waterfront": "56aa371be4b08b9a8d5734c3", "Japanese Restaurant": "4bf58dd8d48988d111941735", "Health & Beauty Service": "54541900498ea6ccd0202697", "Palace": "52e81612bcbc57f1066b7a14", "German Restaurant": "4bf58dd8d48988d10d941735", "Pop-Up Shop": "52f2ab2ebcbc57f1066b8b3d", "Bagel Shop": "4bf58dd8d48988d179941735", "Flower Shop": "4bf58dd8d48988d11b951735", "Hotel Bar": "4bf58dd8d48988d1d5941735", "Dive Bar": "4bf58dd8d48988d118941735", "Rock Climbing Spot": "50328a4b91d4c4b30a586d6b", "Beer Store": "5370f356bcbc57f1066c94c2", "Island": "50aaa4314b90af0d42d5de10", "Southern / Soul Food Restaurant": "4bf58dd8d48988d14f941735", "Pizza Place": "4bf58dd8d48988d1ca941735", "Mongolian Restaurant": "4eb1d5724b900d56c88a45fe", "Hot Dog Joint": "4bf58dd8d48988d16f941735", "Ice Cream Shop": "4bf58dd8d48988d1c9941735", "Cuban Restaurant": "4bf58dd8d48988d154941735", "Bakery": "4bf58dd8d48988d16a941735", "Theme Park": "4bf58dd8d48988d182941735", "Dumpling Restaurant": "4bf58dd8d48988d108941735", "Rugby Pitch": "52e81612bcbc57f1066b7a2c", "Poutine Place": "56aa371be4b08b9a8d5734c7", "Belgian Restaurant": "52e81612bcbc57f1066b7a02", "Outlet Mall": "5744ccdfe4b0c0459246b4df", "Volcano": "5032848691d4c4b30a586d61", "River": "4eb1d4dd4b900d56c88a45fd", "Kebab Restaurant": "5283c7b4e4b094cb91ec88d7", "Salad Place": "4bf58dd8d48988d1bd941735", "Pie Shop": "52e81612bcbc57f1066b7a0a", "Exhibit": "56aa371be4b08b9a8d573532", "Chocolate Shop": "52f2ab2ebcbc57f1066b8b31", "Night Market": "53e510b7498ebcb1801b55d4", "Coffee Shop": "4bf58dd8d48988d1e0931735", "Gourmet Shop": "4bf58dd8d48988d1f5941735", "Coffee Roaster": "5e18993feee47d000759b256", "Ski Shop": "56aa371be4b08b9a8d573566", "Food Service": "56aa371be4b08b9a8d573550", "Eastern European Restaurant": "4bf58dd8d48988d109941735", "Golf Course": "4bf58dd8d48988d1e6941735", "Summer Camp": "52e81612bcbc57f1066b7a10", "Cupcake Shop": "4bf58dd8d48988d1bc941735", "Planetarium": "4bf58dd8d48988d192941735", "Afghan Restaurant": "503288ae91d4c4b30a586d67", "Disc Golf": "52e81612bcbc57f1066b79e8", "Bank": "4bf58dd8d48988d10a951735", "Campground": "4bf58dd8d48988d1e4941735", "Spa": "4bf58dd8d48988d1ed941735", "Cheese Shop": "4bf58dd8d48988d11e951735", "Candy Store": "4bf58dd8d48988d117951735", "Grocery Store": "4bf58dd8d48988d118951735", "Seafood Restaurant": "4bf58dd8d48988d1ce941735", "Gun Range": "52e81612bcbc57f1066b7a11", "Creperie": "52e81612bcbc57f1066b79f2", "Dairy Store": "58daa1558bbb0b01f18ec1ca", "Austrian Restaurant": "52e81612bcbc57f1066b7a01", "Arcade": "4bf58dd8d48988d1e1931735", "Floating Market": "56aa371be4b08b9a8d573505", "Climbing Gym": "503289d391d4c4b30a586d6a", "Sausage Shop": "56aa371be4b08b9a8d573564", "Beer Garden": "4bf58dd8d48988d117941735", "Butcher": "4bf58dd8d48988d11d951735", "Zoo": "4bf58dd8d48988d17b941735", "Vineyard": "4bf58dd8d48988d1de941735", "Fruit & Vegetable Store": "52f2ab2ebcbc57f1066b8b1c", "Cycle Studio": "52f2ab2ebcbc57f1066b8b49", "Gas Station": "4bf58dd8d48988d113951735", "Leather Goods Store": "52f2ab2ebcbc57f1066b8b2b", "Martial Arts Dojo": "4bf58dd8d48988d101941735", "Clothing Accessories Store": "4bf58dd8d48988d102951735", "Champagne Bar": "52e81612bcbc57f1066b7a0e", "Cosmetics Shop": "4bf58dd8d48988d10c951735", "Bubble Tea Shop": "52e81612bcbc57f1066b7a0c", "Outlet Store": "52f2ab2ebcbc57f1066b8b35", "Water Park": "4bf58dd8d48988d193941735", "Forest": "52e81612bcbc57f1066b7a23", "Garden Center": "4eb1c0253b7b52c0e1adc2e9", "Science Museum": "4bf58dd8d48988d191941735", "Shopping Plaza": "5744ccdfe4b0c0459246b4dc", "Halal Restaurant": "52e81612bcbc57f1066b79ff", "Food Stand": "56aa371be4b08b9a8d57350b", "Convenience Store": "4d954b0ea243a5684a65b473", "Karaoke Bar": "4bf58dd8d48988d120941735", "Waterfall": "56aa371be4b08b9a8d573560", "Clothing - Kids Store": "4bf58dd8d48988d105951735", "Luggage Store": "52f2ab2ebcbc57f1066b8b29", "Hockey Rink": "56aa371be4b08b9a8d57352c", "Nail Salon": "4f04aa0c2fb6e1c99f3db0b8", "Art Museum": "4bf58dd8d48988d18f941735", "Hungarian Restaurant": "52e81612bcbc57f1066b79fa", "Russian Restaurant": "5293a7563cf9994f4e043a44", "Turkish Restaurant": "4f04af1f2fb6e1c99f3db0bb", "Greek Restaurant": "4bf58dd8d48988d10e941735", "Skate Shop": "5bae9231bedf3950379f89d2", "Caribbean Restaurant": "4bf58dd8d48988d144941735", "Tree": "52e81612bcbc57f1066b7a24", "Skating Rink": "4bf58dd8d48988d168941735", "Volleyball Court": "4eb1bf013b7b6f98df247e07", "Tiki Bar": "56aa371be4b08b9a8d57354d", "English Restaurant": "52e81612bcbc57f1066b7a05", "Curling Ice": "56aa371be4b08b9a8d57351a", "Swiss Restaurant": "4bf58dd8d48988d158941735", "Steakhouse": "4bf58dd8d48988d1cc941735", "Bike Trail": "56aa371be4b08b9a8d57355e", "Farmers Market": "4bf58dd8d48988d1fa941735", "Electronics Store": "4bf58dd8d48988d122951735", "Dog Run": "4bf58dd8d48988d1e5941735", "African Restaurant": "4bf58dd8d48988d1c8941735", "Squash Court": "52e81612bcbc57f1066b7a2d", "Beer Bar": "56aa371ce4b08b9a8d57356c", "Windmill": "5bae9231bedf3950379f89c7", "Czech Restaurant": "52f2ae52bcbc57f1066b8b81", "Modern European Restaurant": "52e81612bcbc57f1066b79f9", "Drugstore": "5745c2e4498e11e7bccabdbd", "Truck Stop": "57558b36e4b065ecebd306dd", "Wings Joint": "4bf58dd8d48988d14c941735", "Shoe Store": "4bf58dd8d48988d107951735", "Thrift / Vintage Store": "4bf58dd8d48988d101951735", "Amphitheater": "56aa371be4b08b9a8d5734db", "Toy / Game Store": "4bf58dd8d48988d1f3941735", "Go Kart Track": "52e81612bcbc57f1066b79ea", "Donut Shop": "4bf58dd8d48988d148941735", "Basketball Court": "4bf58dd8d48988d1e1941735", "Bangladeshi Restaurant": "5e179ee74ae8e90006e9a746", "Cafe": "4bf58dd8d48988d16d941735", "Health Food Store": "50aa9e744b90af0d42d5de0e", "Fishing Spot": "52e81612bcbc57f1066b7a0f", "Jewish Restaurant": "52e81612bcbc57f1066b79fd", "Paintball Field": "5032829591d4c4b30a586d5e", "Hill": "5bae9231bedf3950379f89cd", "Caucasian Restaurant": "5293a7d53cf9994f4e043a45", "Big Box Store": "52f2ab2ebcbc57f1066b8b42", "Australian Restaurant": "4bf58dd8d48988d169941735", "ATM": "52f2ab2ebcbc57f1066b8b56", "Lighthouse": "4bf58dd8d48988d15d941735", "Street Food Gathering": "53e0feef498e5aac066fd8a9", "Lounge": "4bf58dd8d48988d121941735", "Performing Arts Venue": "4bf58dd8d48988d1f2931735", "Cajun / Creole Restaurant": "4bf58dd8d48988d17a941735", "Irish Pub": "52e81612bcbc57f1066b7a06", "Fountain": "56aa371be4b08b9a8d573547", "Memorial Site": "5642206c498e4bfca532186c", "Stadium": "4bf58dd8d48988d184941735", "Food Truck": "4bf58dd8d48988d1cb941735", "Clothing - Men's Store": "4bf58dd8d48988d106951735", "Vegetarian / Vegan Restaurant": "4bf58dd8d48988d1d3941735", "Sporting Goods Shop": "4bf58dd8d48988d1f2941735", "Pilates Studio": "5744ccdfe4b0c0459246b4b2", "Internet Cafe": "4bf58dd8d48988d1f0941735", "Malay Restaurant": "4bf58dd8d48988d156941735", "Burger Joint": "4bf58dd8d48988d16c941735", "Farm": "4bf58dd8d48988d15b941735", "Rafting": "52e81612bcbc57f1066b7a29", "Art Gallery": "4bf58dd8d48988d1e2931735", "Furniture / Home Store": "4bf58dd8d48988d1f8941735", "Asian Restaurant": "4bf58dd8d48988d142941735", "Spanish Restaurant": "4bf58dd8d48988d150941735", "Trail": "4bf58dd8d48988d159941735", "State / Provincial Park": "5bae9231bedf3950379f89d0", "Fried Chicken Joint": "4d4ae6fc7a7b7dea34424761", "Pastry Shop": "5744ccdfe4b0c0459246b4e2", "Sri Lankan Restaurant": "5413605de4b0ae91d18581a9", "Chinese Restaurant": "4bf58dd8d48988d145941735", "Tea Room": "4bf58dd8d48988d1dc931735", "Bike Shop": "4bf58dd8d48988d115951735", "Ethiopian Restaurant": "4bf58dd8d48988d10a941735", "Aquarium": "4fceea171983d5d06c3e9823", "Golf Driving Range": "58daa1558bbb0b01f18ec1b0", "Frozen Yogurt Shop": "512e7cae91d4cbb4e5efe0af", "Fondue Restaurant": "52e81612bcbc57f1066b7a09", "Gymnastics Gym": "52f2ab2ebcbc57f1066b8b48", "Fish & Chips Shop": "4edd64a0c7ddd24ca188df1a", "Soccer Field": "4cce455aebf7b749d5e191f5", "Used Bookstore": "52f2ab2ebcbc57f1066b8b30", "Noodle House": "4bf58dd8d48988d1d1941735", "Liquor Store": "4bf58dd8d48988d186941735", "Hotpot Restaurant": "52af0bd33cf9994f4e043bdd", "Castle": "50aaa49e4b90af0d42d5de11", "Pharmacy": "4bf58dd8d48988d10f951735", "Latin American Restaurant": "4bf58dd8d48988d1be941735", "Recreation Center": "52e81612bcbc57f1066b7a26", "Mexican Restaurant": "4bf58dd8d48988d1c1941735", "Poke Place": "5bae9231bedf3950379f89d4", "Sports Bar": "4bf58dd8d48988d11d941735", "Pet Cafe": "56aa371be4b08b9a8d573508", "Currency Exchange": "5744ccdfe4b0c0459246b4be", "Burmese Restaurant": "56aa371be4b08b9a8d573568", "Baseball Field": "4bf58dd8d48988d1e8941735", "Himalayan Restaurant": "52e81612bcbc57f1066b79fb", "Laser Tag": "52e81612bcbc57f1066b79e6", "Camera Store": "4eb1bdf03b7b55596b4a7491", "Flea Market": "4bf58dd8d48988d1f7941735", "National Park": "52e81612bcbc57f1066b7a21", "Pool": "4bf58dd8d48988d15e941735", "Speakeasy": "4bf58dd8d48988d1d4941735", "Snack Place": "4bf58dd8d48988d1c7941735", "Tennis Court": "4e39a956bd410d7aed40cbc3", "Scandinavian Restaurant": "4bf58dd8d48988d1c6941735", "Salon / Barbershop": "4bf58dd8d48988d110951735", "Antique Shop": "4bf58dd8d48988d116951735", "Market": "50be8ee891d4fa8dcc7199a7", "Watch Shop": "52f2ab2ebcbc57f1066b8b2e", "Record Shop": "4bf58dd8d48988d10d951735", "Indoor Play Area": "5744ccdfe4b0c0459246b4b5", "Clothing - Women's Store": "4bf58dd8d48988d108951735", "Beach Bar": "52e81612bcbc57f1066b7a0d", "Concert Hall": "5032792091d4c4b30a586d5c", "Cocktail Bar": "4bf58dd8d48988d11e941735", "Polish Restaurant": "52e81612bcbc57f1066b7a04", "Falafel Restaurant": "4bf58dd8d48988d10b941735", "Scottish Restaurant": "5744ccdde4b0c0459246b4a3", "Cemetery": "4bf58dd8d48988d15c941735", "Lake": "4bf58dd8d48988d161941735", "Breakfast Spot": "4bf58dd8d48988d143941735", "Thai Restaurant": "4bf58dd8d48988d149941735", "Field": "4bf58dd8d48988d15f941735", "Wine Shop": "4bf58dd8d48988d119951735", "Nature Preserve": "52e81612bcbc57f1066b7a13", "Dessert Shop": "4bf58dd8d48988d1d0941735", "Mini Golf": "52e81612bcbc57f1066b79eb", "Beach": "4bf58dd8d48988d1e2941735", "Brewery": "50327c8591d4c4b30a586d5d", "Food Court": "4bf58dd8d48988d120951735", "Indonesian Restaurant": "4deefc054765f83613cdba6f", "Portuguese Restaurant": "4def73e84765ae376e57713a", "Ski Area": "4bf58dd8d48988d1e9941735", "Dutch Restaurant": "5744ccdfe4b0c0459246b4d0", "Stables": "4eb1baf03b7b2c5b1d4306ca", "Arts & Crafts Store": "4bf58dd8d48988d127951735", "Track": "4bf58dd8d48988d106941735", "Fishing Store": "52f2ab2ebcbc57f1066b8b16", "Fast Food Restaurant": "4bf58dd8d48988d16e941735", "Street Art": "52e81612bcbc57f1066b79ee", "Supermarket": "52f2ab2ebcbc57f1066b8b46", "Gluten-free Restaurant": "4c2cd86ed066bed06c3c5209", "Bowling Alley": "4bf58dd8d48988d1e4931735", "Reservoir": "56aa371be4b08b9a8d573541", "Sports Club": "52e81612bcbc57f1066b7a2e", "Sculpture Garden": "4bf58dd8d48988d166941735", "Deli / Bodega": "4bf58dd8d48988d146941735", "Hot Spring": "4bf58dd8d48988d160941735", "Mediterranean Restaurant": "4bf58dd8d48988d1c0941735", "Badminton Court": "52e81612bcbc57f1066b7a2b", "Sandwich Place": "4bf58dd8d48988d1c5941735", "Slovak Restaurant": "56aa371be4b08b9a8d57355a", "Diner": "4bf58dd8d48988d147941735", "Soup Place": "4bf58dd8d48988d1dd931735", "Vietnamese Restaurant": "4bf58dd8d48988d14a941735", "Friterie": "55d25775498e9f6a0816a37a", "Jewelry Store": "4bf58dd8d48988d111951735", "Comfort Food Restaurant": "52e81612bcbc57f1066b7a00", "Public Bathroom": "5744ccdfe4b0c0459246b4c4", "Cambodian Restaurant": "52e81612bcbc57f1066b7a03", "Nightclub": "4bf58dd8d48988d11f941735", "Pool Hall": "4bf58dd8d48988d1e3931735", "Satay Restaurant": "56aa371be4b08b9a8d57350e", "Bay": "56aa371be4b08b9a8d573544", "Fireworks Store": "52f2ab2ebcbc57f1066b8b3a", "Garden": "4bf58dd8d48988d15a941735", "Outdoor Sculpture": "52e81612bcbc57f1066b79ed", "Department Store": "4bf58dd8d48988d1f6941735", "Ukrainian Restaurant": "52e928d0bcbc57f1066b7e96", "Historic Site": "4deefb944765f83613cdba6e", "American Restaurant": "4bf58dd8d48988d14e941735", "Mac & Cheese Joint": "4bf58dd8d48988d1bf941735", "Herbs & Spices Store": "52f2ab2ebcbc57f1066b8b2c", "Juice Bar": "4bf58dd8d48988d112941735", "Gift Shop": "4bf58dd8d48988d128951735", "BBQ Joint": "4bf58dd8d48988d1df931735", "Molecular Gastronomy Restaurant": "4bf58dd8d48988d1c2941735", "History Museum": "4bf58dd8d48988d190941735", "Cafeteria": "4bf58dd8d48988d128941735", "Hawaiian Restaurant": "52e81612bcbc57f1066b79fe", "Scenic Lookout": "4bf58dd8d48988d165941735"]
