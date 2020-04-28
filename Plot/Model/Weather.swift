// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let dailyWeather = try DailyWeather(json)

import Foundation

// MARK: - DailyWeatherElement
struct DailyWeatherElement: Codable {
    
    let temp: [Temp]?
    let precipitationProbability: PrecipitationProbability?
    let weatherCode, observationTime: ObservationTime?
    let lat, lon: Double?

    enum CodingKeys: String, CodingKey {
        case temp
        case precipitationProbability = "precipitation_probability"
        case weatherCode = "weather_code"
        case observationTime = "observation_time"
        case lat, lon
    }
    
    static func == (lhs: DailyWeatherElement, rhs: DailyWeatherElement) -> Bool {
        if lhs.temp == rhs.temp && lhs.precipitationProbability == rhs.precipitationProbability && lhs.weatherCode == rhs.weatherCode && lhs.observationTime == rhs.observationTime && lhs.lat == rhs.lat && lhs.lon == rhs.lon {
            return true
        } else {
            return false
        }
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
        temp: [Temp]?? = nil,
        precipitationProbability: PrecipitationProbability?? = nil,
        weatherCode: ObservationTime?? = nil,
        observationTime: ObservationTime?? = nil,
        lat: Double?? = nil,
        lon: Double?? = nil
    ) -> DailyWeatherElement {
        return DailyWeatherElement(
            temp: temp ?? self.temp,
            precipitationProbability: precipitationProbability ?? self.precipitationProbability,
            weatherCode: weatherCode ?? self.weatherCode,
            observationTime: observationTime ?? self.observationTime,
            lat: lat ?? self.lat,
            lon: lon ?? self.lon
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

// MARK: - PrecipitationProbability
struct PrecipitationProbability: Codable {
    let value: Double?
    let units: WeatherUnits?
}

// MARK: PrecipitationProbability convenience initializers and mutators

extension PrecipitationProbability {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PrecipitationProbability.self, from: data)
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
        value: Double?? = nil,
        units: WeatherUnits?? = nil
    ) -> PrecipitationProbability {
        return PrecipitationProbability(
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

enum WeatherUnits: String, Codable {
    case empty = "%"
    case f = "F"
}

// MARK: - Temp
struct Temp: Codable, Equatable {
    let observationTime: Date?
    let min, max: PrecipitationProbability?

    enum CodingKeys: String, CodingKey {
        case observationTime = "observation_time"
        case min, max
    }
    
    static func == (lhs: Temp, rhs: Temp) -> Bool {
        if lhs.observationTime == rhs.observationTime && lhs.max == rhs.max && lhs.min == rhs.min {
            return true
        } else {
            return false
        }
    }
}

// MARK: Temp convenience initializers and mutators

extension Temp {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Temp.self, from: data)
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
        min: PrecipitationProbability?? = nil,
        max: PrecipitationProbability?? = nil
    ) -> Temp {
        return Temp(
            observationTime: observationTime ?? self.observationTime,
            min: min ?? self.min,
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
