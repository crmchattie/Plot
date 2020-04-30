// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let dailyWeather = try DailyWeather(json)

import Foundation

// MARK: - DailyWeatherElement
struct DailyWeatherElement: Codable, Equatable {
    
    let temp: [Temp]?
    let precipitationProbability: ValueUnits?
    let weatherCode: WeatherCodeDict?
    let observationTime: Val?
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
        precipitationProbability: ValueUnits?? = nil,
        weatherCode: WeatherCodeDict?? = nil,
        observationTime: Val?? = nil,
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
struct Val: Codable, Equatable {
    let value: String?
}

struct ValueUnits: Codable, Equatable {
    let value: Double?
    let units: WeatherUnits?
    
    static func == (lhs: ValueUnits, rhs: ValueUnits) -> Bool {
        if lhs.value == rhs.value && lhs.units == rhs.units {
            return true
        } else {
            return false
        }
    }
}

enum WeatherUnits: String, Codable {
    case empty = "%"
    case f = "F"
}

// MARK: - Temp
struct Temp: Codable, Equatable {
    let observationTime: String?
    let min, max: ValueUnits?

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
        observationTime: String?? = nil,
        min: ValueUnits?? = nil,
        max: ValueUnits?? = nil
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

struct WeatherCodeDict: Codable, Equatable {
    let value: WeatherCode?
}

enum WeatherCode: String, Codable {
    case rain_heavy, rain, rain_light, freezing_rain_heavy, freezing_rain, freezing_rain_light, freezing_drizzle, drizzle, ice_pellets_heavy, ice_pellets, ice_pellets_light, snow_heavy, snow, snow_light, flurries, tstorm, fog_light, fog, cloudy, mostly_cloudy, partly_cloudy, mostly_clear, clear
    
    var description: String {
        switch self {
        case .rain_heavy: return "Substantial Rain"
        case .rain: return "Rain"
        case .rain_light: return "Light Rain"
        case .freezing_rain_heavy: return "Substantial Freezing Rain"
        case .freezing_rain: return "Freezing Rain"
        case .freezing_rain_light: return "Light Freezing Rain"
        case .freezing_drizzle: return "Freezing Drizzle"
        case .drizzle: return "Drizzle"
        case .ice_pellets_heavy: return "Substantial Ice Pellets"
        case .ice_pellets: return "Ice Pellets"
        case .ice_pellets_light: return "Light Ice Pellets"
        case .snow_heavy: return "Substantial Snow"
        case .snow: return "Snow"
        case .snow_light: return "Light Snow"
        case .flurries: return "Flurries"
        case .tstorm: return "Thunderstorm Conditions"
        case .fog_light: return "Light Fog"
        case .fog: return "Fog"
        case .cloudy: return "Cloudy"
        case .mostly_cloudy: return "Mostly Cloudy"
        case .partly_cloudy: return "Partly Cloudy"
        case .mostly_clear: return "Mostly Clear"
        case .clear: return "Clear"
        }
    }
    var image: String {
        switch self {
        case .rain_heavy: return "icons8-torrential_rain"
        case .rain: return "icons8-heavy_rain"
        case .rain_light: return "icons8-moderate_rain"
        case .freezing_rain_heavy: return "icons8-sleet"
        case .freezing_rain: return "icons8-sleet"
        case .freezing_rain_light: return "icons8-sleet"
        case .freezing_drizzle: return "icons8-sleet"
        case .drizzle: return "icons8-light_rain"
        case .ice_pellets_heavy: return "icons8-hail"
        case .ice_pellets: return "icons8-hail"
        case .ice_pellets_light: return "icons8-hail"
        case .snow_heavy: return "icons8-snow_storm"
        case .snow: return "icons8-snow"
        case .snow_light: return "icons8-light_snow"
        case .flurries: return "icons8-light_snow"
        case .tstorm: return "icons8-storm"
        case .fog_light: return "icons8-haze"
        case .fog: return "icons8-haze"
        case .cloudy: return "icons8-clouds"
        case .mostly_cloudy: return "icons8-clouds"
        case .partly_cloudy: return "icons8-partly_cloudy_day"
        case .mostly_clear: return "icons8-partly_cloudy_day"
        case .clear: return "icons8-smiling_sun"
        }
    }
}
