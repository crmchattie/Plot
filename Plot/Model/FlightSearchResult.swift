// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let flightSearchResult = try FlightSearchResult(json)

import Foundation

// MARK: - FlightSearchResult
class FlightSearchResult: Codable {
    let pagination: Pagination?
    let data: [Datum]?

    init(pagination: Pagination?, data: [Datum]?) {
        self.pagination = pagination
        self.data = data
    }
}

// MARK: FlightSearchResult convenience initializers and mutators

extension FlightSearchResult {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(FlightSearchResult.self, from: data)
        self.init(pagination: me.pagination, data: me.data)
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
        pagination: Pagination?? = nil,
        data: [Datum]?? = nil
    ) -> FlightSearchResult {
        return FlightSearchResult(
            pagination: pagination ?? self.pagination,
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

// MARK: - Datum
class Datum: Codable {
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

// MARK: Datum convenience initializers and mutators

extension Datum {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Datum.self, from: data)
        self.init(flightDate: me.flightDate, flightStatus: me.flightStatus, departure: me.departure, arrival: me.arrival, airline: me.airline, flight: me.flight, aircraft: me.aircraft, live: me.live)
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
        flightDate: String?? = nil,
        flightStatus: String?? = nil,
        departure: Arrival?? = nil,
        arrival: Arrival?? = nil,
        airline: Airline?? = nil,
        flight: Flight?? = nil,
        aircraft: Aircraft?? = nil,
        live: Live?? = nil
    ) -> Datum {
        return Datum(
            flightDate: flightDate ?? self.flightDate,
            flightStatus: flightStatus ?? self.flightStatus,
            departure: departure ?? self.departure,
            arrival: arrival ?? self.arrival,
            airline: airline ?? self.airline,
            flight: flight ?? self.flight,
            aircraft: aircraft ?? self.aircraft,
            live: live ?? self.live
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Aircraft
class Aircraft: Codable {
    let registration, iata, icao, icao24: String?

    init(registration: String?, iata: String?, icao: String?, icao24: String?) {
        self.registration = registration
        self.iata = iata
        self.icao = icao
        self.icao24 = icao24
    }
}

// MARK: Aircraft convenience initializers and mutators

extension Aircraft {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Aircraft.self, from: data)
        self.init(registration: me.registration, iata: me.iata, icao: me.icao, icao24: me.icao24)
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
        registration: String?? = nil,
        iata: String?? = nil,
        icao: String?? = nil,
        icao24: String?? = nil
    ) -> Aircraft {
        return Aircraft(
            registration: registration ?? self.registration,
            iata: iata ?? self.iata,
            icao: icao ?? self.icao,
            icao24: icao24 ?? self.icao24
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Airline
class Airline: Codable {
    let name, iata, icao: String?

    init(name: String?, iata: String?, icao: String?) {
        self.name = name
        self.iata = iata
        self.icao = icao
    }
}

// MARK: Airline convenience initializers and mutators

extension Airline {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Airline.self, from: data)
        self.init(name: me.name, iata: me.iata, icao: me.icao)
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
        iata: String?? = nil,
        icao: String?? = nil
    ) -> Airline {
        return Airline(
            name: name ?? self.name,
            iata: iata ?? self.iata,
            icao: icao ?? self.icao
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Arrival
class Arrival: Codable {
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

// MARK: Arrival convenience initializers and mutators

extension Arrival {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Arrival.self, from: data)
        self.init(airport: me.airport, timezone: me.timezone, iata: me.iata, icao: me.icao, terminal: me.terminal, gate: me.gate, baggage: me.baggage, delay: me.delay, scheduled: me.scheduled, estimated: me.estimated, actual: me.actual, estimatedRunway: me.estimatedRunway, actualRunway: me.actualRunway)
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
        airport: String?? = nil,
        timezone: String?? = nil,
        iata: String?? = nil,
        icao: String?? = nil,
        terminal: String?? = nil,
        gate: String?? = nil,
        baggage: String?? = nil,
        delay: Int?? = nil,
        scheduled: Date?? = nil,
        estimated: Date?? = nil,
        actual: Date?? = nil,
        estimatedRunway: Date?? = nil,
        actualRunway: Date?? = nil
    ) -> Arrival {
        return Arrival(
            airport: airport ?? self.airport,
            timezone: timezone ?? self.timezone,
            iata: iata ?? self.iata,
            icao: icao ?? self.icao,
            terminal: terminal ?? self.terminal,
            gate: gate ?? self.gate,
            baggage: baggage ?? self.baggage,
            delay: delay ?? self.delay,
            scheduled: scheduled ?? self.scheduled,
            estimated: estimated ?? self.estimated,
            actual: actual ?? self.actual,
            estimatedRunway: estimatedRunway ?? self.estimatedRunway,
            actualRunway: actualRunway ?? self.actualRunway
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Flight
class Flight: Codable {
    let number, iata, icao: String?

    init(number: String?, iata: String?, icao: String?) {
        self.number = number
        self.iata = iata
        self.icao = icao
    }
}

// MARK: Flight convenience initializers and mutators

extension Flight {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Flight.self, from: data)
        self.init(number: me.number, iata: me.iata, icao: me.icao)
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
        number: String?? = nil,
        iata: String?? = nil,
        icao: String?? = nil
    ) -> Flight {
        return Flight(
            number: number ?? self.number,
            iata: iata ?? self.iata,
            icao: icao ?? self.icao
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Live
class Live: Codable {
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

// MARK: Live convenience initializers and mutators

extension Live {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Live.self, from: data)
        self.init(updated: me.updated, latitude: me.latitude, longitude: me.longitude, altitude: me.altitude, direction: me.direction, speedHorizontal: me.speedHorizontal, speedVertical: me.speedVertical, isGround: me.isGround)
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
        updated: Date?? = nil,
        latitude: Double?? = nil,
        longitude: Double?? = nil,
        altitude: Double?? = nil,
        direction: Double?? = nil,
        speedHorizontal: Double?? = nil,
        speedVertical: Double?? = nil,
        isGround: Bool?? = nil
    ) -> Live {
        return Live(
            updated: updated ?? self.updated,
            latitude: latitude ?? self.latitude,
            longitude: longitude ?? self.longitude,
            altitude: altitude ?? self.altitude,
            direction: direction ?? self.direction,
            speedHorizontal: speedHorizontal ?? self.speedHorizontal,
            speedVertical: speedVertical ?? self.speedVertical,
            isGround: isGround ?? self.isGround
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Pagination
class Pagination: Codable {
    let limit, offset, count, total: Int?

    init(limit: Int?, offset: Int?, count: Int?, total: Int?) {
        self.limit = limit
        self.offset = offset
        self.count = count
        self.total = total
    }
}

// MARK: Pagination convenience initializers and mutators

extension Pagination {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(Pagination.self, from: data)
        self.init(limit: me.limit, offset: me.offset, count: me.count, total: me.total)
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
        limit: Int?? = nil,
        offset: Int?? = nil,
        count: Int?? = nil,
        total: Int?? = nil
    ) -> Pagination {
        return Pagination(
            limit: limit ?? self.limit,
            offset: offset ?? self.offset,
            count: count ?? self.count,
            total: total ?? self.total
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}
