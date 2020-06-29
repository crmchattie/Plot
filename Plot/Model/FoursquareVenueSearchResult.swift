//
//  FoursquareFSVenueSearch.swift
//  Plot
//
//  Created by Cory McHattie on 6/17/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let foursquareRecFSVenueSearchResult = try FoursquareRecFSVenueSearchResult(json)

import Foundation

// MARK: - FoursquareVenueSearchResult
class FoursquareVenueSearchResult: Codable {
    let meta: Meta?
    let response: Response?

    init(meta: Meta?, response: Response?) {
        self.meta = meta
        self.response = response
    }
}

// MARK: FoursquareVenueSearchResult convenience initializers and mutators

extension FoursquareVenueSearchResult {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(FoursquareVenueSearchResult.self, from: data)
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
        response: Response?? = nil
    ) -> FoursquareVenueSearchResult {
        return FoursquareVenueSearchResult(
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

// MARK: - Response
class Response: Codable {
    let venue: FSVenue?
    let venues: [FSVenue]?

    init(venue: FSVenue?, venues: [FSVenue]?) {
        self.venue = venue
        self.venues = venues
    }
}

// MARK: Response convenience initializers and mutators

extension Response {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Response.self, from: data)
        self.init(venue: me.venue, venues: me.venues)
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
        venue: FSVenue?? = nil,
        venues: [FSVenue]?? = nil
    ) -> Response {
        return Response(
            venue: venue ?? self.venue,
            venues: venues ?? self.venues
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}
