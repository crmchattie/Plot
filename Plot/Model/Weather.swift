// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let dailyWeather = try DailyWeather(json)

import Foundation

// MARK: - DailyWeatherElement
struct DailyWeatherElement: Codable {
    let lon, lat: Double?
    let observationTime: ObservationTime?
    let precipitation: [Precipitation]?

    enum CodingKeys: String, CodingKey {
        case lon, lat
        case observationTime = "observation_time"
        case precipitation
    }
}

// MARK: DailyWeatherElement convenience initializers and mutators

extension DailyWeatherElement {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(DailyWeatherElement.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        lon: Double?? = nil,
        lat: Double?? = nil,
        observationTime: ObservationTime?? = nil,
        precipitation: [Precipitation]?? = nil
    ) -> DailyWeatherElement {
        return DailyWeatherElement(
            lon: lon ?? self.lon,
            lat: lat ?? self.lat,
            observationTime: observationTime ?? self.observationTime,
            precipitation: precipitation ?? self.precipitation
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - ObservationTime
struct ObservationTime: Codable {
    let value: String?
}

// MARK: ObservationTime convenience initializers and mutators

extension ObservationTime {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(ObservationTime.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        value: String?? = nil
    ) -> ObservationTime {
        return ObservationTime(
            value: value ?? self.value
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Precipitation
struct Precipitation: Codable {
    let observationTime: Date?
    let max: Max?

    enum CodingKeys: String, CodingKey {
        case observationTime = "observation_time"
        case max
    }
}

// MARK: Precipitation convenience initializers and mutators

extension Precipitation {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Precipitation.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        observationTime: Date?? = nil,
        max: Max?? = nil
    ) -> Precipitation {
        return Precipitation(
            observationTime: observationTime ?? self.observationTime,
            max: max ?? self.max
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Max
struct Max: Codable {
    let value: Int?
    let units: String?
}

// MARK: Max convenience initializers and mutators

extension Max {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Max.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        value: Int?? = nil,
        units: String?? = nil
    ) -> Max {
        return Max(
            value: value ?? self.value,
            units: units ?? self.units
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

typealias DailyWeather = [DailyWeatherElement]

extension Array where Element == DailyWeather.Element {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(DailyWeather.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Helper functions for creating encoders and decoders

func newJSONDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        decoder.dateDecodingStrategy = .iso8601
    }
    return decoder
}

func newJSONEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        encoder.dateEncodingStrategy = .iso8601
    }
    return encoder
}

// MARK: - WeatherElement
struct WeatherElement: Codable {
    let lon, lat: Double?
    let observationTime: ObservationTime?
    let windGust, precipitation: Precipitation?

    enum CodingKeys: String, CodingKey {
        case lon, lat
        case observationTime = "observation_time"
        case windGust = "wind_gust"
        case precipitation
    }
}
