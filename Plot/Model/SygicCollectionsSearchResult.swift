// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let sygicCollectionsSearchResult = try SygicCollectionsSearchResult(json)

import Foundation

// MARK: - SygicCollectionsSearchResult
class SygicCollectionsSearchResult: Codable {
    let statusCode: Int?
    let serverTimestamp: Date?
    let data: DataClass?

    enum CodingKeys: String, CodingKey {
        case statusCode = "status_code"
        case serverTimestamp = "server_timestamp"
        case data
    }

    init(statusCode: Int?, serverTimestamp: Date?, data: DataClass?) {
        self.statusCode = statusCode
        self.serverTimestamp = serverTimestamp
        self.data = data
    }
}

// MARK: SygicCollectionsSearchResult convenience initializers and mutators

extension SygicCollectionsSearchResult {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(SygicCollectionsSearchResult.self, from: data)
        self.init(statusCode: me.statusCode, serverTimestamp: me.serverTimestamp, data: me.data)
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
        serverTimestamp: Date?? = nil,
        data: DataClass?? = nil
    ) -> SygicCollectionsSearchResult {
        return SygicCollectionsSearchResult(
            statusCode: statusCode ?? self.statusCode,
            serverTimestamp: serverTimestamp ?? self.serverTimestamp,
            data: data ?? self.data
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - DataClass
class DataClass: Codable {
    let collections: [Collection]?
    let collection: Collection?

    init(collections: [Collection]?, collection: Collection?) {
        self.collections = collections
        self.collection = collection
    }
}

// MARK: DataClass convenience initializers and mutators

extension DataClass {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(DataClass.self, from: data)
        self.init(collections: me.collections, collection: me.collection)
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
        collections: [Collection]?? = nil,
        collection: Collection?? = nil
    ) -> DataClass {
        return DataClass(
            collections: collections ?? self.collections,
            collection: collection ?? self.collection
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Collection
class Collection: Codable {
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

// MARK: Collection convenience initializers and mutators

extension Collection {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Collection.self, from: data)
        self.init(id: me.id, parentPlaceID: me.parentPlaceID, nameLong: me.nameLong, nameShort: me.nameShort, collectionDescription: me.collectionDescription, tags: me.tags, placeIDS: me.placeIDS)
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
        id: Int,
        parentPlaceID: String?? = nil,
        nameLong: String?? = nil,
        nameShort: String?? = nil,
        collectionDescription: String?? = nil,
        tags: [Tag]?? = nil,
        placeIDS: [String]?? = nil
    ) -> Collection {
        return Collection(
            id: id,
            parentPlaceID: parentPlaceID ?? self.parentPlaceID,
            nameLong: nameLong ?? self.nameLong,
            nameShort: nameShort ?? self.nameShort,
            collectionDescription: collectionDescription ?? self.collectionDescription,
            tags: tags ?? self.tags,
            placeIDS: placeIDS ?? self.placeIDS
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}
