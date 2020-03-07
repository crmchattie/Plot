//
//  RecipesFetcher.swift
//  Plot
//
//  Created by Hafiz Usama on 2019-12-01.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import Foundation

class RecipesFetcher {
//    lazy var baseURL: URL = {
//        return URL(string: SpoonacularAPI.baseUrlString)!
//    }()
//    
//    func fetchRecipes(with request: RecipesSearchRequest, completion: @escaping ([Recipe]) -> Void) {
//        let urlRequest = URLRequest(url: baseURL.appendingPathComponent(request.path))
//        let encodedURLRequest = urlRequest.encode(with: request.parameters)
//        print(encodedURLRequest)
//        let session = URLSession.shared
//        let dataTask = session.dataTask(with: encodedURLRequest, completionHandler: { (data, response, error) -> Void in
//            if (error != nil) {
//                print(error)
//                completion([])
//            }
//            else if let data = data {
//                let recipeSearchResult = try? JSONDecoder().decode(RecipeSearchResult.self, from: data)
//                completion(recipeSearchResult?.recipes ?? [])
//            }
//        })
//        
//        dataTask.resume()
//    }
    
}

//struct SpoonacularAPI {
//    static let baseUrlString = "https://api.spoonacular.com/"
//    static let apiKey = "7c1e8c9cd7fc48718c4d903c53aa99d9"
//}
//
//struct RecipesSearchRequest {
//    var path: String {
//        return "recipes/search"
//    }
//
//    let parameters: Parameters
//    private init(parameters: Parameters) {
//        self.parameters = parameters
//    }
//}
//
//extension RecipesSearchRequest {
//    static func from(query: String, cuisine: String) -> RecipesSearchRequest {
//        let defaultParameters = ["diet": "", "excludeIngredients": "", "offset": "0", "number": "20", "limitLicense": "true", "instructionsRequired": "true", "apiKey": "\(SpoonacularAPI.apiKey)"]
//        let parameters = ["query": "\(query)", "cuisine": "\(cuisine)"].merging(defaultParameters, uniquingKeysWith: +)
//        return RecipesSearchRequest(parameters: parameters)
//
//    }
//}
//
//typealias Parameters = [String: String]
//
//extension URLRequest {
//    func encode(with parameters: Parameters?) -> URLRequest {
//        guard let parameters = parameters else {
//            return self
//        }
//
//        var encodedURLRequest = self
//
//        if let url = self.url,
//            let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
//            !parameters.isEmpty {
//            var newUrlComponents = urlComponents
//            let queryItems = parameters.map { key, value in
//                URLQueryItem(name: key, value: value)
//            }
//            newUrlComponents.queryItems = queryItems
//            encodedURLRequest.url = newUrlComponents.url
//            return encodedURLRequest
//        } else {
//            return self
//        }
//    }
//
//
//}
