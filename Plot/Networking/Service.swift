//
//  Service.swift
//  Plot
//
//  Created by Cory McHattie on 1/5/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

class Service {
    
    static let shared = Service() // singleton
    
    func fetchRecipesSimple(query: String, cuisine: String, completion: @escaping ((RecipeSearchResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: SpoonacularAPI.baseUrlString)!
        }()
        
        let defaultParameters = ["diet": "", "excludeIngredients": "", "offset": "0", "number": "20", "limitLicense": "true", "instructionsRequired": "true", "apiKey": "\(SpoonacularAPI.apiKey)"]
        let parameters = ["query": "\(query)", "cuisine": "\(cuisine)"].merging(defaultParameters, uniquingKeysWith: +)
    
        
        let urlRequest = URLRequest(url: baseURL)
        let encodedURLRequest = urlRequest.encode(with: parameters)
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    func fetchRecipesComplex(query: String, cuisine: [String], excludeCuisine: [String], diet: String, intolerances: [String], type: String, completion: @escaping ((RecipeSearchResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: SpoonacularAPI.complexUrlString)!
        }()
        
        let defaultParameters = ["diet": "", "excludeIngredients": "", "offset": "0", "number": "20", "limitLicense": "true", "instructionsRequired": "true", "addRecipeInformation": "true", "apiKey": "\(SpoonacularAPI.apiKey)"]
        let parameters = ["query": "\(query)", "cuisine": "\(cuisine)", "excludeCuisine": "\(excludeCuisine)", "diet": "\(diet)", "intolerances": "\(intolerances)", "type": "\(type)"].merging(defaultParameters, uniquingKeysWith: +)
    
        
        let urlRequest = URLRequest(url: baseURL)
        let encodedURLRequest = urlRequest.encode(with: parameters)
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    func fetchRecipesInfo(id: Int, completion: @escaping ((Recipe?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: "\(SpoonacularAPI.infoUrlString)/\(id)/information")!
        }()
        
        let defaultParameters = ["includeNutrition": "true", "apiKey": "\(SpoonacularAPI.apiKey)"]
        
        let urlRequest = URLRequest(url: baseURL)
        let encodedURLRequest = urlRequest.encode(with: defaultParameters)
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    func fetchEventsSegment(size: String, id: String, keyword: String, attractionId: String, venueId: String, postalCode: String, radius: String, unit: String, startDateTime: String, endDateTime: String, city: String, stateCode: String, countryCode: String, classificationName: String, classificationId: String, completion: @escaping ((TicketMasterSearchResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: TicketMasterAPI.eventsUrlString)!
        }()
        
        let defaultParameters = ["apikey": "\(TicketMasterAPI.apiKey)", "locale":"*"]
        
        var parameters = ["size":"\(size)", "id": "\(id)", "keyword": "\(keyword)", "attractionId": "\(attractionId)", "venueId": "\(venueId)", "postalCode": "\(postalCode)", "radius": "\(radius)", "unit": "\(unit)", "startDateTime": "\(startDateTime)", "endDateTime": "\(endDateTime)", "city": "\(city)", "stateCode": "\(stateCode)", "countryCode": "\(countryCode)", "classificationName": "\(classificationName)", "classificationId": "\(classificationId)"]
        if attractionId == "" {
            parameters["attractionId"] = nil
        }
        if venueId == "" {
            parameters["venueId"] = nil
        }
//        if city.isEmpty {
//            parameters["city"] = nil
//        }
//        if classificationName.isEmpty {
//            parameters["classificationName"] = nil
//        }
//        if classificationId.isEmpty {
//            parameters["classificationId"] = nil
//        }
        parameters = parameters.merging(defaultParameters, uniquingKeysWith: +)
        
        let urlRequest = URLRequest(url: baseURL)
        let encodedURLRequest = urlRequest.encode(with: parameters)
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    
    func fetchEventsSegmentLatLong(size: String, id: String, keyword: String, attractionId: String, venueId: String, postalCode: String, radius: String, unit: String, startDateTime: String, endDateTime: String, city: String, stateCode: String, countryCode: String, classificationName: String, classificationId: String, lat: Double, long: Double, completion: @escaping ((TicketMasterSearchResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: TicketMasterAPI.eventsUrlString)!
        }()
        
        let defaultParameters = ["apikey": "\(TicketMasterAPI.apiKey)", "locale":"*"]
        
        var parameters = ["size":"\(size)", "id": "\(id)", "keyword": "\(keyword)", "attractionId": "\(attractionId)", "venueId": "\(venueId)", "postalCode": "\(postalCode)", "radius": "\(radius)", "unit": "\(unit)", "startDateTime": "\(startDateTime)", "endDateTime": "\(endDateTime)", "city": "\(city)", "stateCode": "\(stateCode)", "countryCode": "\(countryCode)", "classificationName": "\(classificationName)", "classificationId": "\(classificationId)", "latlong": "\(lat),\(long)"]
        if attractionId == "" {
            parameters["attractionId"] = nil
        }
        if venueId == "" {
            parameters["venueId"] = nil
        }
//        if city.isEmpty {
//            parameters["city"] = nil
//        }
//        if classificationName.isEmpty {
//            parameters["classificationName"] = nil
//        }
//        if classificationId.isEmpty {
//            parameters["classificationId"] = nil
//        }
        parameters = parameters.merging(defaultParameters, uniquingKeysWith: +)
        
        let urlRequest = URLRequest(url: baseURL)
        let encodedURLRequest = urlRequest.encode(with: parameters)
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    func fetchSuggestSegment(resource: String, size: String, keyword: String,radius: String, unit: String, startDateTime: String, endDateTime: String, segmentId: String, completion: @escaping ((TicketMasterSearchResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: TicketMasterAPI.suggestUrlString)!
        }()
        
        let defaultParameters = ["apikey": "\(TicketMasterAPI.apiKey)", "locale":"*"]
        let parameters = ["resource": "\(resource)", "size":"\(size)", "keyword": "\(keyword)", "radius": "\(radius)", "unit": "\(unit)", "segmentId": "\(segmentId)"].merging(defaultParameters, uniquingKeysWith: +)
        
        let urlRequest = URLRequest(url: baseURL)
        let encodedURLRequest = urlRequest.encode(with: parameters)
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    
    func fetchSuggestSegmentLatLong(resource: String, size: String, keyword: String,radius: String, unit: String, startDateTime: String, endDateTime: String, segmentId: String, lat: Double, long: Double, completion: @escaping ((TicketMasterSearchResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: TicketMasterAPI.suggestUrlString)!
        }()
        
        let defaultParameters = ["apikey": "\(TicketMasterAPI.apiKey)", "locale":"*"]
        let parameters = ["resource": "\(resource)", "size":"\(size)", "keyword": "\(keyword)", "radius": "\(radius)", "unit": "\(unit)", "segmentId": "\(segmentId)", "latlong": "\(lat),\(long)"].merging(defaultParameters, uniquingKeysWith: +)
        
        let urlRequest = URLRequest(url: baseURL)
        let encodedURLRequest = urlRequest.encode(with: parameters)
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    func fetchAttractionsSegment(size: String, id: String, keyword: String, classificationName: String, classificationId: String, completion: @escaping ((TicketMasterSearchResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: TicketMasterAPI.attractionsUrlString)!
        }()
        
        let defaultParameters = ["apikey": "\(TicketMasterAPI.apiKey)", "locale":"*"]
        var parameters = ["size":"\(size)", "id": "\(id)", "keyword": "\(keyword)", "classificationName": "\(classificationName)", "classificationId": "\(classificationId)"].merging(defaultParameters, uniquingKeysWith: +)
//        if classificationName.isEmpty {
//            parameters["classificationName"] = nil
//        }
//        if classificationId.isEmpty {
//            parameters["classificationId"] = nil
//        }
        parameters = parameters.merging(defaultParameters, uniquingKeysWith: +)
        
        let urlRequest = URLRequest(url: baseURL)
        let encodedURLRequest = urlRequest.encode(with: parameters)
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    func fetchAttractionsSegmentLatLong(size: String, id: String, keyword: String, classificationName: [String], classificationId: [String], lat: Double, long: Double, completion: @escaping ((TicketMasterSearchResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: TicketMasterAPI.attractionsUrlString)!
        }()
        
        let defaultParameters = ["apikey": "\(TicketMasterAPI.apiKey)", "locale":"*"]
        var parameters = ["size":"\(size)", "id": "\(id)", "keyword": "\(keyword)", "classificationName": "\(classificationName)", "classificationId": "\(classificationId)", "latlong": "\(lat),\(long)"].merging(defaultParameters, uniquingKeysWith: +)
        if classificationName.isEmpty {
            parameters["classificationName"] = nil
        }
        if classificationId.isEmpty {
            parameters["classificationId"] = nil
        }
        parameters = parameters.merging(defaultParameters, uniquingKeysWith: +)
        
        let urlRequest = URLRequest(url: baseURL)
        let encodedURLRequest = urlRequest.encode(with: parameters)
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    // declare my generic json function here
    func fetchGenericJSONData<T: Decodable>(encodedURLRequest: URLRequest, completion: @escaping (T?, Error?) -> ()) {
        
        URLSession.shared.dataTask(with: encodedURLRequest) { (data, resp, err) in
            if let err = err {
                print(err)
                completion(nil, err)
                return
            }
            do {
                let objects = try JSONDecoder().decode(T.self, from: data!)
                // success
                print("completion")
//                print(objects)
                completion(objects, nil)
            } catch {
                print("error \(error)")
                completion(nil, error)
            }
            }.resume()
    }
    
}

struct SpoonacularAPI {
    static let baseUrlString = "https://api.spoonacular.com/recipes/search"
    static let complexUrlString = "https://api.spoonacular.com/recipes/complexSearch"
    static let infoUrlString = "https://api.spoonacular.com/recipes/"
    static fileprivate let apiKey = "7c1e8c9cd7fc48718c4d903c53aa99d9"
}

struct TicketMasterAPI {
    static let eventsUrlString = "https://app.ticketmaster.com/discovery/v2/events"
    static let suggestUrlString = "https://app.ticketmaster.com/discovery/v2/suggest"
    static let attractionsUrlString = "https://app.ticketmaster.com/discovery/v2/attractions"
    static fileprivate let apiKey = "Tgi7g8YEZC5tFpMTPUd9IfrxzXLxJnK0"
}

struct StubHubAPI {
    static let baseUrlString = "https://api.stubhub.com/sellers/search/events/v3"
    static fileprivate let apiKey = "xVBMj11niDRbEux46AZ5piTO7305GkPY"
}

extension URLRequest {
    
    typealias Parameters = [String: String]
    
    func encode(with parameters: Parameters?) -> URLRequest {
        guard let parameters = parameters else {
            return self
        }
        
        var encodedURLRequest = self
        
        if let url = self.url,
            let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
            !parameters.isEmpty {
            var newUrlComponents = urlComponents
            let queryItems = parameters.map { key, value in
                URLQueryItem(name: key, value: value)
            }
            newUrlComponents.queryItems = queryItems
            encodedURLRequest.url = newUrlComponents.url
            return encodedURLRequest
        } else {
            return self
        }
    }
}

/*
 API
 
 */


