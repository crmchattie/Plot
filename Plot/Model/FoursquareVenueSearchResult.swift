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
struct FoursquareVenueSearchResult: Codable, Equatable, Hashable {
    let meta: Meta?
    let response: Response?

    init(meta: Meta?, response: Response?) {
        self.meta = meta
        self.response = response
    }
}

// MARK: - Response
struct Response: Codable, Equatable, Hashable {
    let venue: FSVenue?
    let venues: [FSVenue]?

    init(venue: FSVenue?, venues: [FSVenue]?) {
        self.venue = venue
        self.venues = venues
    }
}
