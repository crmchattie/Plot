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
        
        let defaultParameters = ["diet": "", "excludeIngredients": "snails", "offset": "0", "number": "20", "limitLicense": "true", "instructionsRequired": "true", "apiKey": "\(SpoonacularAPI.apiKey)"]
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
    
    func fetchIngredientInfo(id: Int, completion: @escaping ((ExtendedIngredient?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: "\(SpoonacularAPI.ingredientsString)/\(id)/information")!
        }()
        
        let defaultParameters = ["apiKey": "\(SpoonacularAPI.apiKey)"]
        
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
        var parameters = ["size":"\(size)", "id": "\(id)", "keyword": "\(keyword)", "classificationName": "\(classificationName)", "classificationId": "\(classificationId)"]
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
        var parameters = ["size":"\(size)", "id": "\(id)", "keyword": "\(keyword)", "classificationName": "\(classificationName)", "classificationId": "\(classificationId)", "latlong": "\(lat),\(long)"]
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
    
    func fetchWeatherDaily(startDateTime: String, endDateTime: String, lat: Double, long: Double, unit: String, completion: @escaping (([DailyWeatherElement]?), Error?) -> ()) {
                
        let baseURL: URL = {
            return URL(string: ClimaCellAPI.dailyUrlString)!
        }()
        
        let defaultParameters = ["apikey": "\(ClimaCellAPI.apiKey)", "fields":"temp,weather_code,precipitation_probability"]
        let parameters = ["unit_system":"\(unit)", "start_time":"\(startDateTime)", "end_time":"\(endDateTime)", "lat": "\(lat)", "lon": "\(long)"].merging(defaultParameters, uniquingKeysWith: +)
               
        let urlRequest = URLRequest(url: baseURL)
        let encodedURLRequest = urlRequest.encode(with: parameters)
                                
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    func fetchFSSearchLatLong(limit: String, query: String, radius: String, intent: String, city: String, stateCode: String, countryCode: String, categoryId: String, lat: Double, long: Double, completion: @escaping ((FoursquareVenueSearchResult?), Error?) -> ()) {
            
        let baseURL: URL = {
            return URL(string: FoursquareAPI.searchUrlString)!
        }()
        
        let defaultParameters = ["client_id": "\(FoursquareAPI.clientID)", "client_secret":"\(FoursquareAPI.clientSecret)", "v": "20190425"]
        
        var parameters = ["limit":"\(limit)", "query": "\(query)", "radius": "\(radius)", "intent": "\(intent)", "categoryId": "\(categoryId)", "ll": "\(lat),\(long)"]
        if radius == "" {
            parameters["radius"] = nil
        }
        
        parameters = parameters.merging(defaultParameters, uniquingKeysWith: +)
        
        let urlRequest = URLRequest(url: baseURL)
        let encodedURLRequest = urlRequest.encode(with: parameters)
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    func fetchFSSearch(limit: String, query: String, radius: String, intent: String, city: String, stateCode: String, countryCode: String, categoryId: String, completion: @escaping ((FoursquareVenueSearchResult?), Error?) -> ()) {
            
        let baseURL: URL = {
            return URL(string: FoursquareAPI.searchUrlString)!
        }()
        
        let defaultParameters = ["client_id": "\(FoursquareAPI.clientID)", "client_secret":"\(FoursquareAPI.clientSecret)", "v": "20190425"]
        
        var parameters = ["limit":"\(limit)", "query": "\(query)", "radius": "\(radius)", "intent": "\(intent)", "categoryId": "\(categoryId)"]
        
        if radius == "" {
            parameters["radius"] = nil
        }
        
        parameters = parameters.merging(defaultParameters, uniquingKeysWith: +)
        
        let urlRequest = URLRequest(url: baseURL)
        let encodedURLRequest = urlRequest.encode(with: parameters)
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    func fetchFSExploreLatLong(limit: String, offset: String, time: String, day: String, openNow: Int, sortByDistance: Int, sortByPopularity: Int, price: [Int], query: String, radius: String, city: String, stateCode: String, countryCode: String, categoryId: String, section: String, lat: Double, long: Double, completion: @escaping ((FoursquareRecVenueSearchResult?), Error?) -> ()) {
            
        let baseURL: URL = {
            return URL(string: FoursquareAPI.exploreUrlString)!
        }()
        
        let defaultParameters = ["client_id": "\(FoursquareAPI.clientID)", "client_secret":"\(FoursquareAPI.clientSecret)", "v": "20190425"]
        
        var parameters = ["limit":"\(limit)", "offset":"\(offset)", "time":"\(time)", "day":"\(day)", "openNow":"\(openNow)", "sortByDistance":"\(sortByDistance)", "sortByPopularity":"\(sortByPopularity)", "price":"\(price)", "query": "\(query)", "radius": "\(radius)", "categoryId": "\(categoryId)", "section": "\(section)", "ll": "\(lat),\(long)"]
        
        if radius == "" {
            parameters["radius"] = nil
        }
        if offset == "" {
            parameters["offset"] = nil
        }
        if price.isEmpty {
            parameters["price"] = nil
        } else if let price = parameters["price"] {
            var newPrice = price.replacingOccurrences(of: "[", with: "")
            newPrice = newPrice.replacingOccurrences(of: "]", with: "")
            parameters["price"] = newPrice.replacingOccurrences(of: " ", with: "")
        }
        
        parameters = parameters.merging(defaultParameters, uniquingKeysWith: +)
        
        let urlRequest = URLRequest(url: baseURL)
        let encodedURLRequest = urlRequest.encode(with: parameters)

        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    func fetchFSExplore(limit: String, offset: String, time: String, day: String, openNow: Int, sortByDistance: Int, sortByPopularity: Int, price: [Int], query: String, radius: String, city: String, stateCode: String, countryCode: String, categoryId: String, section: String, completion: @escaping ((FoursquareRecVenueSearchResult?), Error?) -> ()) {
            
        let baseURL: URL = {
            return URL(string: FoursquareAPI.exploreUrlString)!
        }()
        
        let defaultParameters = ["client_id": "\(FoursquareAPI.clientID)", "client_secret":"\(FoursquareAPI.clientSecret)", "v": "20190425"]
        
        var parameters = ["limit":"\(limit)", "offset":"\(offset)", "time":"\(time)", "day":"\(day)", "openNow":"\(openNow)", "sortByDistance":"\(sortByDistance)", "sortByPopularity":"\(sortByPopularity)", "price":"\(price)", "query": "\(query)", "radius": "\(radius)", "categoryId": "\(categoryId)", "section": "\(section)"]
        if radius == "" {
            parameters["radius"] = nil
        }
        if offset == "" {
            parameters["offset"] = nil
        }
        if price.isEmpty {
            parameters["price"] = nil
        }
        
        parameters = parameters.merging(defaultParameters, uniquingKeysWith: +)
        
        let urlRequest = URLRequest(url: baseURL)
        let encodedURLRequest = urlRequest.encode(with: parameters)
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    func fetchFSDetails(id: String, completion: @escaping ((FoursquareVenueSearchResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: "\(FoursquareAPI.detailUrlString)/\(id)")!
        }()
        
        let defaultParameters = ["client_id": "\(FoursquareAPI.clientID)", "client_secret":"\(FoursquareAPI.clientSecret)", "v": "20190425"]
        
        let urlRequest = URLRequest(url: baseURL)
        let encodedURLRequest = urlRequest.encode(with: defaultParameters)
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
                        
    }
    
    func fetchSygicCollections(limit: String, query: String, parent_place_id: String, place_ids: String, tags: String, tags_not: String, prefer_unique: String, city: String, stateCode: String, countryCode: String, completion: @escaping ((SygicCollectionsSearchResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: SygicAPI.collectionsUrlString)!
        }()
                
        var parameters = ["limit":"\(limit)", "query": "\(query)", "parent_place_id": "\(parent_place_id)", "place_ids": "\(place_ids)", "tags": "\(tags)", "tags_not": "\(tags_not)", "prefer_unique": "\(prefer_unique)"]
        if query == "" {
            parameters["query"] = nil
        }
                
        let urlRequest = URLRequest(url: baseURL)
        var encodedURLRequest = urlRequest.encode(with: parameters)
        encodedURLRequest.setValue("\(SygicAPI.apiKey)", forHTTPHeaderField: "x-api-key")
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    func fetchSygicCollectionDetails(id: String, completion: @escaping ((SygicCollectionsSearchResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: "\(SygicAPI.collectionsUrlString)/\(id)")!
        }()
        
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.setValue("\(SygicAPI.apiKey)", forHTTPHeaderField: "x-api-key")
        fetchGenericJSONData(encodedURLRequest: urlRequest, completion: completion)
                        
    }
    
    func fetchSygicPlacesLatLong(limit: String, offset: String, query: String, categories: [String], categories_not: [String], parent_place_id: String, place_ids: String, tags: String, tags_not: String, prefer_unique: String, city: String, stateCode: String, countryCode: String, lat: Double, long: Double, radius: String, completion: @escaping ((SygicPlacesSearchResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: SygicAPI.placesUrlString)!
        }()
        
        var categoryString = ""
        if categories.count > 1 {
            for x in 0...categories.count - 1 {
                if x == 0 {
                    categoryString = categories[x]
                    continue
                }
                categoryString += "|" + categories[x]
            }
        } else if categories.count == 1 {
            categoryString = categories[0]
        }
        
        var notCategoryString = ""
        if categories_not.count > 1 {
            for x in 0...categories_not.count - 1 {
                if x == 0 {
                    notCategoryString = categories_not[x]
                    continue
                }
                notCategoryString += "|" + categories_not[x]
            }
        } else if categories_not.count == 1 {
            notCategoryString = categories_not[0]
        }
                
        var parameters = ["limit":"\(limit)", "offset":"\(offset)", "query": "\(query)", "categories": "\(categoryString)", "categories_not": "\(notCategoryString)", "parent_place_id": "\(parent_place_id)", "place_ids": "\(place_ids)", "tags": "\(tags)", "tags_not": "\(tags_not)", "prefer_unique": "\(prefer_unique)", "area": "\(lat),\(long),\(radius)", "location": "\(lat),\(long)"]
        if query == "" {
            parameters["query"] = nil
        }
        if offset == "" {
            parameters["offset"] = nil
        }
        
        
        let urlRequest = URLRequest(url: baseURL)
        var encodedURLRequest = urlRequest.encode(with: parameters)
        encodedURLRequest.setValue("\(SygicAPI.apiKey)", forHTTPHeaderField: "x-api-key")
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    func fetchSygicPlaces(limit: String, offset: String, query: String, categories: [String], categories_not: [String], parent_place_id: String, place_ids: String, tags: String, tags_not: String, prefer_unique: String, city: String, stateCode: String, countryCode: String, radius: String, completion: @escaping ((SygicPlacesSearchResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: SygicAPI.placesUrlString)!
        }()
        
        var categoryString = ""
        if categories.count > 1 {
            for x in 0...categories.count - 1 {
                if x == 0 {
                    categoryString = categories[x]
                    continue
                }
                categoryString += "|" + categories[x]
            }
        } else if categories.count == 1 {
            categoryString = categories[0]
        }
        
        var notCategoryString = ""
        if categories_not.count > 1 {
            for x in 0...categories_not.count - 1 {
                if x == 0 {
                    notCategoryString = categories_not[x]
                    continue
                }
                notCategoryString += "|" + categories_not[x]
            }
        } else if categories_not.count == 1 {
            notCategoryString = categories_not[0]
        }
                
        var parameters = ["limit":"\(limit)", "offset":"\(offset)", "query": "\(query)", "categories": "\(categoryString)", "categories_not": "\(notCategoryString)", "parent_place_id": "\(parent_place_id)", "place_ids": "\(place_ids)", "tags": "\(tags)", "tags_not": "\(tags_not)", "prefer_unique": "\(prefer_unique)"]
        if query == "" {
            parameters["query"] = nil
        }
        if offset == "" {
            parameters["offset"] = nil
        }
                
        let urlRequest = URLRequest(url: baseURL)
        var encodedURLRequest = urlRequest.encode(with: parameters)
        encodedURLRequest.setValue("\(SygicAPI.apiKey)", forHTTPHeaderField: "x-api-key")
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    func fetchSygicPlaceDetails(id: String, completion: @escaping ((SygicPlacesSearchResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: "\(SygicAPI.placeDetailsUrlString)/\(id)")!
        }()
        
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.setValue("\(SygicAPI.apiKey)", forHTTPHeaderField: "x-api-key")
        fetchGenericJSONData(encodedURLRequest: urlRequest, completion: completion)
                        
    }
    
    func fetchSygicTours(parent_place_id: String, completion: @escaping ((SygicToursSearchResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: SygicAPI.tripTemplatesUrlString)!
        }()
                
        let parameters = ["parent_place_id": "\(parent_place_id)"]
                
        let urlRequest = URLRequest(url: baseURL)
        var encodedURLRequest = urlRequest.encode(with: parameters)
        encodedURLRequest.setValue("\(SygicAPI.apiKey)", forHTTPHeaderField: "x-api-key")
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    func fetchSygicTourDetails(id: String, completion: @escaping ((SygicToursSearchResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: "\(SygicAPI.tripDetailsUrlString)/\(id)")!
        }()
        
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.setValue("\(SygicAPI.apiKey)", forHTTPHeaderField: "x-api-key")
        fetchGenericJSONData(encodedURLRequest: urlRequest, completion: completion)
                        
    }
    
    func fetchFlight(flight_date: String, flight_status: String, dep_iata: String, arr_iata: String, dep_icao: String, arr_icao: String, airline_name: String, airline_iata: String, airline_icao: String, flight_number: String, flight_iata: String, flight_icao: String, completion: @escaping ((FlightSearchResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: AviationAPI.flightsUrlString)!
        }()
        
        let defaultParameters = ["access_key": "\(AviationAPI.apiKey)"]
                
        var parameters = ["flight_date":"\(flight_date)", "flight_status":"\(flight_status)", "dep_iata": "\(dep_iata)", "arr_iata": "\(arr_iata)", "dep_icao": "\(dep_icao)", "arr_icao": "\(arr_icao)", "airline_name": "\(airline_name)", "airline_iata": "\(airline_iata)", "airline_icao": "\(airline_icao)", "flight_number": "\(flight_number)", "flight_iata": "\(flight_iata)", "flight_icao": "\(flight_icao)"]
        
        parameters = parameters.merging(defaultParameters, uniquingKeysWith: +)
        
        let urlRequest = URLRequest(url: baseURL)
        let encodedURLRequest = urlRequest.encode(with: parameters)
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
                        
    }
    
    // declare my generic json function here
    func fetchGenericJSONData<T: Decodable>(encodedURLRequest: URLRequest, completion: @escaping (T?, Error?) -> ()) {
//        print("encodedURLRequest \(encodedURLRequest)")
        URLSession.shared.dataTask(with: encodedURLRequest) { (data, resp, err) in
            if let err = err {
                print("err \(err)")
                completion(nil, err)
                return
            }
            do {
                let objects = try JSONDecoder().decode(T.self, from: data!)
                // success
//                print("objects \(objects)")
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
    static let ingredientsString = "https://api.spoonacular.com/food/ingredients/"
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

struct ClimaCellAPI {
    static fileprivate let apiKey = "pEDT4UvIaMtu2agpiPZZh0Hl1QLhxyTL"
    static let realTimeUrlString = "https://api.climacell.co/v3/weather/realtime"
    static let nowCastUrlString = "https://api.climacell.co/v3/weather/nowcast"
    static let hourlyUrlString = "https://api.climacell.co/v3/weather/forecast/hourly"
    static let dailyUrlString = "https://api.climacell.co/v3/weather/forecast/daily"
}

struct AviationAPI {
    static let flightsUrlString = "https://api.aviationstack.com/v1/flights"
    static fileprivate let apiKey = "0688f6631e1872f04adea3f86b67e6c1"
}

struct FoursquareAPI {
    static let exploreUrlString = "https://api.foursquare.com/v2/venues/explore"
    static let searchUrlString = "https://api.foursquare.com/v2/venues/search"
    static let detailUrlString = "https://api.foursquare.com/v2/venues"
    static fileprivate let clientID = "DZCYSAUK2HVJECX4AIKHLUWBPOYDAEK5PDVTLEKWJVB1HT4F"
    static fileprivate let clientSecret = "2KYITTACKGXAJZ3COBVRRCVTTLVGVF1UPWD2RLUJWRMGB2IA"
}

struct SygicAPI {
    static let placesUrlString = "https://api.sygictravelapi.com/1.1/en/places/list"
    static let placeDetailsUrlString = "https://api.sygictravelapi.com/1.1/en/places"
    static let collectionsUrlString = "https://api.sygictravelapi.com/1.1/en/collections"
    static let tripTemplatesUrlString = "https://api.sygictravelapi.com/1.1/en/trips/templates"
    static let tripDetailsUrlString = "https://api.sygictravelapi.com/1.1/en/trips"
    static fileprivate let apiKey = "gLr9XJrFQB3picSrsJoC1nSCUyIsMQQ8rr4meHN1"
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


