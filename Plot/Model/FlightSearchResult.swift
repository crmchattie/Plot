// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let flightSearchResult = try FlightSearchResult(json)

import Foundation

// MARK: - FlightSearchResult
struct FlightSearchResult: Codable, Equatable, Hashable {
    let pagination: Pagination?
    let data: [Datum]?

    init(pagination: Pagination?, data: [Datum]?) {
        self.pagination = pagination
        self.data = data
    }
}

// MARK: - Datum
struct Datum: Codable, Equatable, Hashable {
    let flightDate, flightStatus: String?
    let departure, arrival: Arrival?
    let airline: Airline?
    let flight: Flight?
    let aircraft: Aircraft?
    let live: Live?

    enum CodingKeys: String, CodingKey {
        case flightDate = "flight_date"
        case flightStatus = "flight_status"
        case departure, arrival, airline, flight, aircraft, live
    }

    init(flightDate: String?, flightStatus: String?, departure: Arrival?, arrival: Arrival?, airline: Airline?, flight: Flight?, aircraft: Aircraft?, live: Live?) {
        self.flightDate = flightDate
        self.flightStatus = flightStatus
        self.departure = departure
        self.arrival = arrival
        self.airline = airline
        self.flight = flight
        self.aircraft = aircraft
        self.live = live
    }
}

// MARK: - Aircraft
struct Aircraft: Codable, Equatable, Hashable {
    let registration, iata, icao, icao24: String?

    init(registration: String?, iata: String?, icao: String?, icao24: String?) {
        self.registration = registration
        self.iata = iata
        self.icao = icao
        self.icao24 = icao24
    }
}

// MARK: - Airline
struct Airline: Codable, Equatable, Hashable {
    let name, iata, icao: String?

    init(name: String?, iata: String?, icao: String?) {
        self.name = name
        self.iata = iata
        self.icao = icao
    }
}

// MARK: - Arrival
struct Arrival: Codable, Equatable, Hashable {
    let airport, timezone, iata, icao: String?
    let terminal, gate, baggage: String?
    let delay: Int?
    let scheduled, estimated: Date?
    let actual, estimatedRunway, actualRunway: Date?

    enum CodingKeys: String, CodingKey {
        case airport, timezone, iata, icao, terminal, gate, baggage, delay, scheduled, estimated, actual
        case estimatedRunway = "estimated_runway"
        case actualRunway = "actual_runway"
    }

    init(airport: String?, timezone: String?, iata: String?, icao: String?, terminal: String?, gate: String?, baggage: String?, delay: Int?, scheduled: Date?, estimated: Date?, actual: Date?, estimatedRunway: Date?, actualRunway: Date?) {
        self.airport = airport
        self.timezone = timezone
        self.iata = iata
        self.icao = icao
        self.terminal = terminal
        self.gate = gate
        self.baggage = baggage
        self.delay = delay
        self.scheduled = scheduled
        self.estimated = estimated
        self.actual = actual
        self.estimatedRunway = estimatedRunway
        self.actualRunway = actualRunway
    }
}

// MARK: - Flight
struct Flight: Codable, Equatable, Hashable {
    let number, iata, icao: String?

    init(number: String?, iata: String?, icao: String?) {
        self.number = number
        self.iata = iata
        self.icao = icao
    }
}

// MARK: - Live
struct Live: Codable, Equatable, Hashable {
    let updated: Date?
    let latitude, longitude, altitude, direction: Double?
    let speedHorizontal, speedVertical: Double?
    let isGround: Bool?

    enum CodingKeys: String, CodingKey {
        case updated, latitude, longitude, altitude, direction
        case speedHorizontal = "speed_horizontal"
        case speedVertical = "speed_vertical"
        case isGround = "is_ground"
    }

    init(updated: Date?, latitude: Double?, longitude: Double?, altitude: Double?, direction: Double?, speedHorizontal: Double?, speedVertical: Double?, isGround: Bool?) {
        self.updated = updated
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.direction = direction
        self.speedHorizontal = speedHorizontal
        self.speedVertical = speedVertical
        self.isGround = isGround
    }
}

// MARK: - Pagination
struct Pagination: Codable, Equatable, Hashable {
    let limit, offset, count, total: Int?

    init(limit: Int?, offset: Int?, count: Int?, total: Int?) {
        self.limit = limit
        self.offset = offset
        self.count = count
        self.total = total
    }
}
