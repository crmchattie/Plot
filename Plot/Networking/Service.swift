//
//  Service.swift
//  Plot
//
//  Created by Cory McHattie on 1/5/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import Firebase

class Service {
    
    static let shared = Service() // singleton
    
    func fetchRecipesSimple(query: String, cuisine: String, completion: @escaping ((RecipeSearchResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: SpoonacularAPI.recipeString + "search")!
        }()
        
        let defaultParameters = ["diet": "", "excludeIngredients": "snails", "offset": "0", "number": "20", "limitLicense": "true", "instructionsRequired": "true", "apiKey": "\(SpoonacularAPI.apiKey)"]
        let parameters = ["query": "\(query)", "cuisine": "\(cuisine)"].merging(defaultParameters, uniquingKeysWith: +)
        
        
        let urlRequest = URLRequest(url: baseURL)
        let encodedURLRequest = urlRequest.encode(with: parameters)
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    func fetchRecipesComplex(query: String, cuisine: [String], excludeCuisine: [String], diet: String, intolerances: [String], type: String, completion: @escaping ((RecipeSearchResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: SpoonacularAPI.recipeString + "complexSearch")!
        }()
        
        let defaultParameters = ["diet": "", "excludeIngredients": "", "offset": "0", "number": "20", "limitLicense": "true", "instructionsRequired": "true", "addRecipeInformation": "true", "apiKey": "\(SpoonacularAPI.apiKey)"]
        let parameters = ["query": "\(query)", "cuisine": "\(cuisine)", "excludeCuisine": "\(excludeCuisine)", "diet": "\(diet)", "intolerances": "\(intolerances)", "type": "\(type)"].merging(defaultParameters, uniquingKeysWith: +)
        
        
        let urlRequest = URLRequest(url: baseURL)
        let encodedURLRequest = urlRequest.encode(with: parameters)
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    func fetchRecipesInfo(id: Int, completion: @escaping ((Recipe?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: "\(SpoonacularAPI.recipeString)/\(id)/information")!
        }()
        
        let defaultParameters = ["includeNutrition": "true", "apiKey": "\(SpoonacularAPI.apiKey)"]
        
        let urlRequest = URLRequest(url: baseURL)
        let encodedURLRequest = urlRequest.encode(with: defaultParameters)
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    func fetchIngredientInfo(id: Int, amount: Double?, unit: String?, completion: @escaping ((ExtendedIngredient?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: "\(SpoonacularAPI.ingredientsString)/\(id)/information")!
        }()
        
        var defaultParameters = ["apiKey": "\(SpoonacularAPI.apiKey)","amount": "\(amount ?? 1)"]
        if unit != nil {
            defaultParameters["unit"] = unit
        }
        
        let urlRequest = URLRequest(url: baseURL)
        let encodedURLRequest = urlRequest.encode(with: defaultParameters)
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    func fetchGroceryProducts(query: String, completion: @escaping ((GroceryProductSearch?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: SpoonacularAPI.groceryString + "search")!
        }()
        
        let defaultParameters = [ "offset": "0", "number": "100", "apiKey": "\(SpoonacularAPI.apiKey)"]
        let parameters = ["query": "\(query)"].merging(defaultParameters, uniquingKeysWith: +)
        
        
        let urlRequest = URLRequest(url: baseURL)
        let encodedURLRequest = urlRequest.encode(with: parameters)
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    func fetchGroceryProductInfo(id: Int, completion: @escaping ((GroceryProduct?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: "\(SpoonacularAPI.groceryString)\(id)")!
        }()
        
        let defaultParameters = ["apiKey": "\(SpoonacularAPI.apiKey)"]
        
        let urlRequest = URLRequest(url: baseURL)
        let encodedURLRequest = urlRequest.encode(with: defaultParameters)
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    func fetchGroceryProductInfoUPC(upc: Int, completion: @escaping ((GroceryProduct?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: "\(SpoonacularAPI.groceryString)upc/\(upc)")!
        }()
        
        let defaultParameters = ["apiKey": "\(SpoonacularAPI.apiKey)"]
        
        let urlRequest = URLRequest(url: baseURL)
        let encodedURLRequest = urlRequest.encode(with: defaultParameters)
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    func fetchMenuProducts(query: String, completion: @escaping ((MenuProductSearch?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: SpoonacularAPI.menuString + "search")!
        }()
        
        let defaultParameters = ["offset": "0", "number": "100", "apiKey": "\(SpoonacularAPI.apiKey)"]
        let parameters = ["query": "\(query)"].merging(defaultParameters, uniquingKeysWith: +)
        
        let urlRequest = URLRequest(url: baseURL)
        let encodedURLRequest = urlRequest.encode(with: parameters)
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    func fetchMenuProductInfo(id: Int, completion: @escaping ((MenuProduct?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: "\(SpoonacularAPI.menuString)\(id)")!
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
    
    func createMXUser(id: String, completion: @escaping ((MXUserResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: MXAPI.baseURL+"users")!
        }()
        
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.allHTTPHeaderFields = ["MX-API-Key": "\(MXAPI.apiKey)",
                                          "MX-Client-ID": "\(MXAPI.clientID)",
                                          "Accept": "\(MXAPI.version)",
                                          "Content-Type": "\(MXAPI.contentType)"]
        urlRequest.httpMethod = "POST"
        let parameters = ["user": ["identifier": "\(id)"]]
        let jsonData = try? JSONSerialization.data(withJSONObject: parameters)
        urlRequest.httpBody = jsonData
        fetchGenericJSONData(encodedURLRequest: urlRequest, completion: completion)
        
    }
    
    func updateMXUser(method: String, guid: String, is_disabled: Bool?, completion: @escaping ((MXUserResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: MXAPI.baseURL+"users/"+guid)!
        }()
        
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.allHTTPHeaderFields = ["MX-API-Key": MXAPI.apiKey,
                                          "MX-Client-ID": MXAPI.clientID,
                                          "Accept": MXAPI.version,
                                          "Content-Type": MXAPI.contentType]
        
        var parameters = [String: String]()
        
        if method == "get" {
            urlRequest.httpMethod = "GET"
        }
        else if method == "put" {
            urlRequest.httpMethod = "PUT"
            if let is_disabled = is_disabled {
                parameters = ["is_disabled":"\(is_disabled)"]
            }
        }
        
        let encodedURLRequest = urlRequest.encode(with: parameters)
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    func deleteMXUser(guid: String, completion: @escaping ((String?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: MXAPI.baseURL+"users/"+guid)!
        }()
        
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.allHTTPHeaderFields = ["MX-API-Key": MXAPI.apiKey,
                                          "MX-Client-ID": MXAPI.clientID,
                                          "Accept": MXAPI.version,
                                          "Content-Type": MXAPI.contentType]
        urlRequest.httpMethod = "DELETE"
        
        fetchGenericJSONData(encodedURLRequest: urlRequest, completion: completion)
        
    }
    
    func getMXConnectURL(guid: String, current_member_guid: String?, completion: @escaping ((MXUserResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: MXAPI.baseURL+"users/"+guid+"/connect_widget_url")!
        }()
        
        var parameters = ["is_mobile_webview":"\(true)",
                          "ui_message_version": "\(4)"]
        if UITraitCollection.current.userInterfaceStyle == .light {
            parameters["color_scheme"] = "light"
        } else {
            parameters["color_scheme"] = "dark"
        }
        if let guid = current_member_guid {
            parameters["current_member_guid"] = "\(guid)"
            parameters["disable_institution_search"] = "true"
        }
        
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.allHTTPHeaderFields = ["MX-API-Key": MXAPI.apiKey,
                                          "MX-Client-ID": MXAPI.clientID,
                                          "Accept": MXAPI.version,
                                          "Content-Type": MXAPI.contentType]
        urlRequest.httpMethod = "POST"
        
        let encodedURLRequest = urlRequest.encode(with: parameters)
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    func getMXMembers(guid: String, page: String, records_per_page: String, completion: @escaping ((MXMemberResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: MXAPI.baseURL+"users/"+guid+"/members")!
        }()
        
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.allHTTPHeaderFields = ["MX-API-Key": MXAPI.apiKey,
                                          "MX-Client-ID": MXAPI.clientID,
                                          "Accept": MXAPI.version,
                                          "Content-Type": MXAPI.contentType]
        urlRequest.httpMethod = "GET"
        
        let parameters = ["page":"\(page)",
                          "records_per_page": "\(records_per_page)"]
        let encodedURLRequest = urlRequest.encode(with: parameters)
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
    }
    
    func getMXMember(guid: String, member_guid: String, completion: @escaping ((MXMemberResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: MXAPI.baseURL+"users/"+guid+"/members/"+member_guid)!
        }()
        
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.allHTTPHeaderFields = ["MX-API-Key": MXAPI.apiKey,
                                          "MX-Client-ID": MXAPI.clientID,
                                          "Accept": MXAPI.version,
                                          "Content-Type": MXAPI.contentType]
        urlRequest.httpMethod = "GET"
        fetchGenericJSONData(encodedURLRequest: urlRequest, completion: completion)
    }
    
    func getMXMemberAccounts(guid: String, member_guid: String, page: String, records_per_page: String, completion: @escaping ((MXAccountResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: MXAPI.baseURL+"users/"+guid+"/members/"+member_guid+"/accounts")!
        }()
        
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.allHTTPHeaderFields = ["MX-API-Key": MXAPI.apiKey,
                                          "MX-Client-ID": MXAPI.clientID,
                                          "Accept": MXAPI.version,
                                          "Content-Type": MXAPI.contentType]
        urlRequest.httpMethod = "GET"
        
        let parameters = ["page":"\(page)",
                          "records_per_page": "\(records_per_page)"]
        let encodedURLRequest = urlRequest.encode(with: parameters)
        
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
    }
    
    func aggregateMXMember(guid: String, member_guid: String, completion: @escaping ((MXMemberResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: MXAPI.baseURL+"users/"+guid+"/members/"+member_guid+"/aggregate")!
        }()
        
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.allHTTPHeaderFields = ["MX-API-Key": MXAPI.apiKey,
                                          "MX-Client-ID": MXAPI.clientID,
                                          "Accept": MXAPI.version,
                                          "Content-Type": MXAPI.contentType]
        urlRequest.httpMethod = "POST"
        
        fetchGenericJSONData(encodedURLRequest: urlRequest, completion: completion)
    }
    
    func deleteMXMember(guid: String, member_guid: String, completion: @escaping ((String?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: MXAPI.baseURL+"users/"+guid+"/members/"+member_guid)!
        }()
        
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.allHTTPHeaderFields = ["MX-API-Key": MXAPI.apiKey,
                                          "MX-Client-ID": MXAPI.clientID,
                                          "Accept": MXAPI.version,
                                          "Content-Type": MXAPI.contentType]
        urlRequest.httpMethod = "DELETE"
        
        fetchGenericJSONData(encodedURLRequest: urlRequest, completion: completion)
    }
    
    func getMXAccounts(guid: String, page: String, records_per_page: String, completion: @escaping ((MXAccountResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: MXAPI.baseURL+"users/"+guid+"/accounts")!
        }()
        
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.allHTTPHeaderFields = ["MX-API-Key": MXAPI.apiKey,
                                          "MX-Client-ID": MXAPI.clientID,
                                          "Accept": MXAPI.version,
                                          "Content-Type": MXAPI.contentType]
        urlRequest.httpMethod = "GET"
        
        let parameters = ["page":"\(page)",
                          "records_per_page": "\(records_per_page)"]
        let encodedURLRequest = urlRequest.encode(with: parameters)
        
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
    }
    
    func getMXAccount(guid: String, account_guid: String, completion: @escaping ((MXAccountResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: MXAPI.baseURL+"users/"+guid+"/accounts/"+account_guid)!
        }()
        
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.allHTTPHeaderFields = ["MX-API-Key": MXAPI.apiKey,
                                          "MX-Client-ID": MXAPI.clientID,
                                          "Accept": MXAPI.version,
                                          "Content-Type": MXAPI.contentType]
        urlRequest.httpMethod = "GET"
        
        fetchGenericJSONData(encodedURLRequest: urlRequest, completion: completion)
    }
    
    func getMXInstitution(institution_code: String, completion: @escaping ((MXInstitutionResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: MXAPI.baseURL+"institutions/"+institution_code)!
        }()
        
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.allHTTPHeaderFields = ["MX-API-Key": MXAPI.apiKey,
                                          "MX-Client-ID": MXAPI.clientID,
                                          "Accept": MXAPI.version,
                                          "Content-Type": MXAPI.contentType]
        urlRequest.httpMethod = "GET"
        
        fetchGenericJSONData(encodedURLRequest: urlRequest, completion: completion)
    }
    
    func getMXTransactions(guid: String, page: String, records_per_page: String, from_date: String?, to_date: String?, completion: @escaping ((MXTransactionResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: MXAPI.baseURL+"users/"+guid+"/transactions")!
        }()
        
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.allHTTPHeaderFields = ["MX-API-Key": MXAPI.apiKey,
                                          "MX-Client-ID": MXAPI.clientID,
                                          "Accept": MXAPI.version,
                                          "Content-Type": MXAPI.contentType]
        urlRequest.httpMethod = "GET"
        
        var parameters = ["page":"\(page)",
                          "records_per_page": "\(records_per_page)"]
        //If no values are given, from_date will default to 90 days prior to the request, and to_date will default to 5 days from the time of the request.
        if let from_date = from_date {
            parameters["from_date"] = "\(from_date)"
        }
        if let to_date = to_date {
            parameters["to_date"] = "\(to_date)"
        }
        
        let encodedURLRequest = urlRequest.encode(with: parameters)
        
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
    }
    
    func getMXMemberTransactions(guid: String, member_guid: String, page: String, records_per_page: String, from_date: String?, to_date: String?, completion: @escaping ((MXTransactionResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: MXAPI.baseURL+"users/"+guid+"/members/"+member_guid+"/transactions")!
        }()
        
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.allHTTPHeaderFields = ["MX-API-Key": MXAPI.apiKey,
                                          "MX-Client-ID": MXAPI.clientID,
                                          "Accept": MXAPI.version,
                                          "Content-Type": MXAPI.contentType]
        urlRequest.httpMethod = "GET"
        
        var parameters = ["page":"\(page)",
                          "records_per_page": "\(records_per_page)"]
        //If no values are given, from_date will default to 90 days prior to the request, and to_date will default to 5 days from the time of the request.
        if let from_date = from_date {
            parameters["from_date"] = "\(from_date)"
        }
        if let to_date = to_date {
            parameters["to_date"] = "\(to_date)"
        }
        
        let encodedURLRequest = urlRequest.encode(with: parameters)
        
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
    }
    
    func getMXAccountTransactions(guid: String, account_guid: String, page: String, records_per_page: String, from_date: String?, to_date: String?, completion: @escaping ((MXTransactionResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: MXAPI.baseURL+"users/"+guid+"/accounts/"+account_guid+"/transactions")!
        }()
        
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.allHTTPHeaderFields = ["MX-API-Key": MXAPI.apiKey,
                                          "MX-Client-ID": MXAPI.clientID,
                                          "Accept": MXAPI.version,
                                          "Content-Type": MXAPI.contentType]
        urlRequest.httpMethod = "GET"
        
        var parameters = ["page": "\(page)",
                          "records_per_page": "\(records_per_page)"]
        //If no values are given, from_date will default to 90 days prior to the request, and to_date will default to 5 days from the time of the request.
        if let from_date = from_date {
            parameters["from_date"] = "\(from_date)"
        }
        if let to_date = to_date {
            parameters["to_date"] = "\(to_date)"
        }
        
        let encodedURLRequest = urlRequest.encode(with: parameters)
        
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
    }
    
    func createMXTransactionRule(guid: String, category_guid: String, match_description: String, description: String?, completion: @escaping ((MXTransactionRuleResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: MXAPI.baseURL+"users/"+guid+"/transaction_rules")!
        }()
        
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.allHTTPHeaderFields = ["MX-API-Key": MXAPI.apiKey,
                                          "MX-Client-ID": MXAPI.clientID,
                                          "Accept": MXAPI.version,
                                          "Content-Type": MXAPI.contentType]
        
        var parameters = ["category_guid": "\(category_guid)",
                          "match_description": "\(match_description)"]
        //If no values are given, from_date will default to 90 days prior to the request, and to_date will default to 5 days from the time of the request.
        if let description = description {
            parameters["description"] = "\(description)"
        }
        
        urlRequest.httpMethod = "POST"
        
        let encodedURLRequest = urlRequest.encode(with: parameters)
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    func deleteMXTransactionRule(guid: String, transaction_rule_guid: String, completion: @escaping ((MXTransactionRuleResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: MXAPI.baseURL+"users/"+guid+"/transaction_rules/"+transaction_rule_guid)!
        }()
        
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.allHTTPHeaderFields = ["MX-API-Key": MXAPI.apiKey,
                                          "MX-Client-ID": MXAPI.clientID,
                                          "Accept": MXAPI.version,
                                          "Content-Type": MXAPI.contentType]
        
        urlRequest.httpMethod = "DELETE"
        
        fetchGenericJSONData(encodedURLRequest: urlRequest, completion: completion)
        
    }
    
    func updateMXTransactionRule(guid: String, transaction_rule_guid: String, category_guid: String?, match_description: String?, description: String?, completion: @escaping ((MXTransactionRuleResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: MXAPI.baseURL+"users/"+guid+"/transaction_rules/"+transaction_rule_guid)!
        }()
        
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.allHTTPHeaderFields = ["MX-API-Key": MXAPI.apiKey,
                                          "MX-Client-ID": MXAPI.clientID,
                                          "Accept": MXAPI.version,
                                          "Content-Type": MXAPI.contentType]
        
        var parameters = [String: String]()
        //If no values are given, from_date will default to 90 days prior to the request, and to_date will default to 5 days from the time of the request.
        if let category_guid = category_guid {
            parameters["category_guid"] = "\(category_guid)"
        }
        if let match_description = match_description {
            parameters["match_description"] = "\(match_description)"
        }
        if let description = description {
            parameters["description"] = "\(description)"
        }
        
        urlRequest.httpMethod = "PUT"
        
        let encodedURLRequest = urlRequest.encode(with: parameters)
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    func createMXCategory(guid: String, parent_guid: String, name: String, completion: @escaping ((MXTransactionCategoryResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: MXAPI.baseURL+"user/"+guid+"/categories")!
        }()
        
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.allHTTPHeaderFields = ["MX-API-Key": MXAPI.apiKey,
                                          "MX-Client-ID": MXAPI.clientID,
                                          "Accept": MXAPI.version,
                                          "Content-Type": MXAPI.contentType]
        
        let parameters = ["parent_guid": "\(parent_guid)",
                          "name": "\(name)"]
        //If no values are given, from_date will default to 90 days prior to the request, and to_date will default to 5 days from the time of the request.
        
        urlRequest.httpMethod = "POST"
        
        let encodedURLRequest = urlRequest.encode(with: parameters)
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    func deleteMXCategory(guid: String, category_guid: String, completion: @escaping ((MXTransactionCategoryResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: MXAPI.baseURL+"user/"+guid+"/categories/"+category_guid)!
        }()
        
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.allHTTPHeaderFields = ["MX-API-Key": MXAPI.apiKey,
                                          "MX-Client-ID": MXAPI.clientID,
                                          "Accept": MXAPI.version,
                                          "Content-Type": MXAPI.contentType]
        
        //If no values are given, from_date will default to 90 days prior to the request, and to_date will default to 5 days from the time of the request.
        
        urlRequest.httpMethod = "DELETE"
        
        fetchGenericJSONData(encodedURLRequest: urlRequest, completion: completion)
        
    }
    
    func updateMXCategory(guid: String, category_guid: String, parent_guid: String?, name: String?, completion: @escaping ((MXTransactionCategoryResult?), Error?) -> ()) {
        
        let baseURL: URL = {
            return URL(string: MXAPI.baseURL+"user/"+guid+"/categories/"+category_guid)!
        }()
        
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.allHTTPHeaderFields = ["MX-API-Key": MXAPI.apiKey,
                                          "MX-Client-ID": MXAPI.clientID,
                                          "Accept": MXAPI.version,
                                          "Content-Type": MXAPI.contentType]
        
        var parameters = [String: String]()
        //If no values are given, from_date will default to 90 days prior to the request, and to_date will default to 5 days from the time of the request.
        if let parent_guid = parent_guid {
            parameters["parent_guid"] = "\(parent_guid)"
        }
        if let name = name {
            parameters["name"] = "\(name)"
        }
        
        urlRequest.httpMethod = "PUT"
        
        let encodedURLRequest = urlRequest.encode(with: parameters)
        fetchGenericJSONData(encodedURLRequest: encodedURLRequest, completion: completion)
        
    }
    
    func fetchMXConnectURL(current_member_guid: String?, completion: @escaping ((String?), Error?) -> ()) {
        let baseURL: URL = {
            return URL(string: "https://us-central1-messenging-app-94621.cloudfunctions.net/openMXConnect")!
        }()
        
        var parameters = ["isMobileWebview":"\(true)",
                          "uiMessageVersion": "\(4)"]
        if UITraitCollection.current.userInterfaceStyle == .light {
            parameters["colorScheme"] = "light"
        } else {
            parameters["colorScheme"] = "dark"
        }
        if let guid = current_member_guid {
            parameters["currentMemberGuid"] = "\(guid)"
            parameters["disableInstitutionSearch"] = "true"
        }
        
        let currentUser = Auth.auth().currentUser
        currentUser?.getIDTokenForcingRefresh(true) { [weak self] token, error in
            if let error = error {
                print("error getting token \(error)")
                // Handle error
                return
            }
            if let token = token {
                var urlRequest = URLRequest(url: baseURL)
                urlRequest.allHTTPHeaderFields = ["Content-Type": "text/plain; charset=utf-8",
                                                  "Authorization" : "Bearer \(token)"]
                
                urlRequest.httpMethod = "GET"
                let jsonData = try? JSONSerialization.data(withJSONObject: parameters)
                urlRequest.httpBody = jsonData
                self?.fetchGenericJSONData(encodedURLRequest: urlRequest, completion: completion)
            }
        }
        
    }
    
    // declare my generic json function here
    func fetchGenericJSONData<T: Decodable>(encodedURLRequest: URLRequest, completion: @escaping (T?, Error?) -> ()) {
        print("encodedURLRequest \(encodedURLRequest)")
        URLSession.shared.dataTask(with: encodedURLRequest) { (data, resp, err) in
            print("resObject \(resp)")
            if let err = err {
                print("err \(err)")
                completion(nil, err)
                return
            }
            do {
                let objects = try JSONDecoder().decode(T.self, from: data!)
                // success
                print("objects \(objects)")
                completion(objects, nil)
            } catch {
                print("error \(error)")
                completion(nil, error)
            }
        }.resume()
    }
    
}

struct SpoonacularAPI {
    static let recipeString = "https://api.spoonacular.com/recipes/"
    static let ingredientsString = "https://api.spoonacular.com/food/ingredients/"
    static let groceryString = "https://api.spoonacular.com/food/products/"
    static let menuString = "https://api.spoonacular.com/food/menuItems/"
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

struct MXAPI {
    //production environment
    //    static let baseURL = "https://atrium.mx.com/"
    
    //production environment keys
    //    static fileprivate let apiKey = "d14242458ddd419ac3e40238537070a6ccf29c2f"
    //    static fileprivate let clientID = "cc3f22cd-7431-4bd9-955c-2624dcbb0e26"
    
    //development environment URL
    static let baseURL = "https://vestibule.mx.com/"
    
    //development environment keys
    static fileprivate let apiKey = "07c825a06c719bafc82e812445d02230cdd67b47"
    static fileprivate let clientID = "cc3f22cd-7431-4bd9-955c-2624dcbb0e26"
    
    static fileprivate let version = "application/vnd.mx.atrium.v1+json"
    static fileprivate let contentType = "application/json"
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


