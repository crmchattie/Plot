// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let sygicCollectionsSearchResult = try SygicCollectionsSearchResult(json)

import Foundation

// MARK: - SygicCollectionsSearchResult
struct SygicCollectionsSearchResult: Codable, Equatable, Hashable {
    let statusCode: Int?
    let serverTimestamp: String?
    let data: DataClass?

    enum CodingKeys: String, CodingKey {
        case statusCode = "status_code"
        case serverTimestamp = "server_timestamp"
        case data
    }

    init(statusCode: Int?, serverTimestamp: String?, data: DataClass?) {
        self.statusCode = statusCode
        self.serverTimestamp = serverTimestamp
        self.data = data
    }
}


// MARK: - DataClass
struct DataClass: Codable, Equatable, Hashable {
    let collections: [Collection]?
    let collection: Collection?

    init(collections: [Collection]?, collection: Collection?) {
        self.collections = collections
        self.collection = collection
    }
}

// MARK: - Collection
struct Collection: Codable, Equatable, Hashable {
    let id: Int
    let parentPlaceID, nameLong, nameShort, collectionDescription: String?
    let tags: [Tag]?
    let placeIDS: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case parentPlaceID = "parent_place_id"
        case nameLong = "name_long"
        case nameShort = "name_short"
        case collectionDescription = "description"
        case tags
        case placeIDS = "place_ids"
    }

    init(id: Int, parentPlaceID: String?, nameLong: String?, nameShort: String?, collectionDescription: String?, tags: [Tag]?, placeIDS: [String]?) {
        self.id = id
        self.parentPlaceID = parentPlaceID
        self.nameLong = nameLong
        self.nameShort = nameShort
        self.collectionDescription = collectionDescription
        self.tags = tags
        self.placeIDS = placeIDS
    }
}

func ==(lhs: Collection, rhs: Collection) -> Bool {
    return lhs.id == rhs.id
}
