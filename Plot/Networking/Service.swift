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
        print(encodedURLRequest)
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
        print(encodedURLRequest)
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    func fetchEvents(segmentId: String, completion: @escaping ((TicketMasterSearchResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: TicketMasterAPI.baseUrlString)!
        }()
        
        let defaultParameters = ["apikey": "\(TicketMasterAPI.apiKey)", "locale":"*"]
        let parameters = ["segmentId": "\(segmentId)"].merging(defaultParameters, uniquingKeysWith: +)
        
        let urlRequest = URLRequest(url: baseURL)
        let encodedURLRequest = urlRequest.encode(with: parameters)
        print(encodedURLRequest)
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    
    func fetchEventsLatLong(segmentId: String, lat: Double, long: Double, completion: @escaping ((TicketMasterSearchResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: TicketMasterAPI.baseUrlString)!
        }()
        
        let defaultParameters = ["apikey": "\(TicketMasterAPI.apiKey)", "locale":"*"]
        let parameters = ["segmentId": "\(segmentId)", "latlong": "\(lat),\(long)"].merging(defaultParameters, uniquingKeysWith: +)
        
        let urlRequest = URLRequest(url: baseURL)
        let encodedURLRequest = urlRequest.encode(with: parameters)
        print(encodedURLRequest)
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
    static let apiKey = "7c1e8c9cd7fc48718c4d903c53aa99d9"
}

struct WorkoutAPI {
//    static let baseUrlString = "https://api.spoonacular.com/"
//    static let apiKey = "7c1e8c9cd7fc48718c4d903c53aa99d9"
}

struct TicketMasterAPI {
    static let baseUrlString = "https://app.ticketmaster.com/discovery/v2/events"
    static let apiKey = "Tgi7g8YEZC5tFpMTPUd9IfrxzXLxJnK0"
}

struct StubHubAPI {
    static let baseUrlString = "https://api.stubhub.com/sellers/search/events/v3"
    static let apiKey = "xVBMj11niDRbEux46AZ5piTO7305GkPY"
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


