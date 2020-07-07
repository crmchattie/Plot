//
//  MealTypeViewController.swift
//  Plot
//
//  Created by Cory McHattie on 1/20/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Eureka

class MealTypeViewController: ActivitySubTypeViewController, UISearchBarDelegate {
    
    var sections: [ActivitySection] = [.american, .italian, .vegetarian, .mexican, .breakfast, .dessert]
    var groups = [ActivitySection: [Recipe]]()
    var searchActivities = [Recipe]()
    var activeRecipe: Bool = false
    fileprivate var movingBackwards: Bool = true

    var filters: [filter] = [.cuisine, .excludeCuisine, .diet, .intolerances, .recipeType]
    var filterDictionary = [String: [String]]()
    
    weak var recipeDelegate : UpdateRecipeDelegate?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Meals"
        
        let doneBarButton = UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(filter))
        navigationItem.rightBarButtonItem = doneBarButton

        searchController.searchBar.delegate = self
        
        fetchData()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.movingBackwards {
            self.recipeDelegate?.updateRecipe(recipe: nil)
        }
    }
        
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print(searchText)
        
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { (_) in
            self.complexSearch(query: searchText.lowercased(), cuisine: self.filterDictionary["cuisine"] ?? [], excludeCuisine: self.filterDictionary["excludeCuisine"] ?? [], diet: self.filterDictionary["diet"]?[0] ?? "", intolerances: self.filterDictionary["intolerances"] ?? [""], type: self.filterDictionary["recipeType"]?[0] ?? "", favorites: self.filterDictionary["favorites"]?[0] ?? "")
        })
    }
    
    func complexSearch(query: String, cuisine: [String], excludeCuisine: [String], diet: String, intolerances: [String], type: String, favorites: String) {
        print("query \(query), cuisine \(cuisine), excludeCuisine \(excludeCuisine), diet \(diet), intolerances \(intolerances), type \(type), favorites \(favorites)")
        
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
            
        var snapshot = diffableDataSource.snapshot()
        snapshot.deleteAllItems()
        self.diffableDataSource.apply(snapshot)
        collectionView.collectionViewLayout = ActivitySubTypeViewController.searchLayout()
        
        activityIndicatorView.startAnimating()
        
        searchActivities = []
        showGroups = false
                                
        let dispatchGroup = DispatchGroup()
        
        if favorites == "true" {
            if let recipes = self.favAct["recipes"] {
                for recipeID in recipes {
                    var recipe: Recipe!
                    var include = true
                    dispatchGroup.enter()
                    Service.shared.fetchRecipesInfo(id: Int(recipeID)!) { (search, err) in
                        recipe = search
                        for type in cuisine {
                            if let cuisines = recipe.cuisines, cuisines.contains(type) {
                                include = true
                                break
                            } else {
                                include = false
                            }
                        }
                        if include == true {
                            for type in excludeCuisine {
                                if let cuisines = recipe.cuisines, cuisines.contains(type) {
                                    include = false
                                    break
                                } else {
                                    include = true
                                }
                            }
                        }
                        if diet != "" && include == true {
                            if let diets = recipe.diets, diets.contains(diet) {
                                include = true
                            } else {
                                include = false
                            }
                        }
                        if type != "" && include == true {
                            if let types = recipe.dishTypes, types.contains(type) {
                                include = true
                            } else {
                                include = false
                            }
                        }
                        if include {
                            self.searchActivities.append(recipe)
                        }
                        dispatchGroup.leave()
                    }
                }
            }
        } else {
            dispatchGroup.enter()
            Service.shared.fetchRecipesComplex(query: query, cuisine: cuisine, excludeCuisine: excludeCuisine, diet: diet, intolerances: intolerances, type: type) { (search, err) in
                if let err = err {
                    print("Failed to fetch apps:", err)
                    return
                }
                
                self.searchActivities = search!.recipes
                                
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            activityIndicatorView.stopAnimating()
            self.checkIfThereAnyActivities()
            snapshot.appendSections([.search])
            snapshot.appendItems(self.searchActivities, toSection: .search)
            self.diffableDataSource.apply(snapshot)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActivities = []
        
        collectionView.collectionViewLayout = ActivitySubTypeViewController.initialLayout()
        var snapshot = diffableDataSource.snapshot()
        snapshot.deleteSections([.search])
        for section in sections {
            if let object = groups[section] {
                snapshot.appendSections([section])
                snapshot.appendItems(object, toSection: section)
                diffableDataSource.apply(snapshot)
            }
        }
        showGroups = true
        checkIfThereAnyActivities()
    }
    
    fileprivate func fetchData() {
        
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        
        activityIndicatorView.startAnimating()
        
        diffableDataSource.supplementaryViewProvider = .some({ (collectionView, kind, indexPath) -> UICollectionReusableView? in
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.kCompositionalHeader, for: indexPath) as! CompositionalHeader
            let snapshot = self.diffableDataSource.snapshot()
            if let object = self.diffableDataSource.itemIdentifier(for: indexPath), let section = snapshot.sectionIdentifier(containingItem: object) {
                header.titleLabel.text = section.name
                header.subTitleLabel.isHidden = true
            }
            
            return header
        })
        
        var snapshot = self.diffableDataSource.snapshot()
        
        // help you sync your data fetches together
        let dispatchGroup = DispatchGroup()
        
        for section in sections {
            print("section \(section.name)")
            if let object = groups[section] {
                activityIndicatorView.stopAnimating()
                snapshot.appendSections([section])
                snapshot.appendItems(object, toSection: section)
                self.diffableDataSource.apply(snapshot)
                continue
            } else if section.subType == "Cuisine" {
                dispatchGroup.enter()
                Service.shared.fetchRecipesComplex(query: "", cuisine: [section.searchTerm], excludeCuisine: [""], diet: "", intolerances: [""], type: "") { (search, err) in
                    dispatchGroup.leave()
                    if let object = search?.recipes {
                        self.groups[section] = object
                    }
                }
            } else if section.subType == "Diet" {
                dispatchGroup.enter()
                Service.shared.fetchRecipesComplex(query: "", cuisine: [""], excludeCuisine: [""], diet: section.searchTerm, intolerances: [""], type: "") { (search, err) in
                    dispatchGroup.leave()
                    if let object = search?.recipes {
                        self.groups[section] = object
                    }
                }
            } else {
                dispatchGroup.enter()
                Service.shared.fetchRecipesComplex(query: section.searchTerm, cuisine: [""], excludeCuisine: [""], diet: "", intolerances: [""], type: "") { (search, err) in
                    dispatchGroup.leave()
                    if let object = search?.recipes {
                        self.groups[section] = object
                    }
                }
            }
            dispatchGroup.notify(queue: .main) {
                if let object = self.groups[section] {
                    activityIndicatorView.stopAnimating()
                    snapshot.appendSections([section])
                    snapshot.appendItems(object, toSection: section)
                    self.diffableDataSource.apply(snapshot)
                }
            }
        }
    }
    
    func checkIfThereAnyActivities() {
        if searchActivities.count > 0 || showGroups {
            viewPlaceholder.remove(from: view, priority: .medium)
        } else {
            viewPlaceholder.add(for: view, title: .emptyRecipes, subtitle: .emptyRecipesEvents, priority: .medium, position: .top)
        }
        collectionView?.reloadData()
    }
    
    @objc func filter() {
        let destination = FilterViewController()
        let navigationViewController = UINavigationController(rootViewController: destination)
        destination.delegate = self
        destination.filters = filters
        destination.filterDictionary = filterDictionary
        self.present(navigationViewController, animated: true, completion: nil)
    }

}

extension MealTypeViewController: ActivityTypeCellDelegate {
    func viewTapped(labelText: String) {
        print(labelText)
    }
}

extension MealTypeViewController: UpdateFilter {
    func updateFilter(filterDictionary : [String: [String]]) {
        if !filterDictionary.values.isEmpty {
            showGroups = false
            self.filterDictionary = filterDictionary
            complexSearch(query: "", cuisine: filterDictionary["cuisine"] ?? [], excludeCuisine: filterDictionary["excludeCuisine"] ?? [], diet: filterDictionary["diet"]?[0] ?? "", intolerances: filterDictionary["intolerances"] ?? [], type: filterDictionary["recipeType"]?[0] ?? "", favorites: self.filterDictionary["favorites"]?[0] ?? "")
        } else {
            searchActivities = []
            self.filterDictionary = filterDictionary
            showGroups = true
            checkIfThereAnyActivities()
        }
    }
        
}

extension MealTypeViewController: UpdateRecipeDelegate {
    func updateRecipe(recipe: Recipe?) {
        self.recipeDelegate?.updateRecipe(recipe: recipe)
    }
}
