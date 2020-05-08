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
    
    var groups = [[Recipe]]()
    var searchActivities = [Recipe]()

    var filters: [filter] = [.cuisine, .excludeCuisine, .diet, .intolerances, .recipeType]
    var filterDictionary = [String: [String]]()
    var sections: [String] = ["American", "Italian", "Vegetarian", "Mexican", "Breakfast", "Dessert"]
    
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Meals"

        let doneBarButton = UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(filter))
        navigationItem.rightBarButtonItem = doneBarButton

        setupSearchBar()
        
        fetchData()
        
    }
    
    fileprivate func setupSearchBar() {
        definesPresentationContext = true
        navigationItem.searchController = self.searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
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
        
        self.searchActivities = [Recipe]()
        showGroups = false
        self.headerheight = view.frame.height
        self.cellheight = 0
        self.collectionView.reloadData()
        
        self.showSpinner(onView: self.view)
        
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
            self.removeSpinner()
        } else {
            dispatchGroup.enter()
            Service.shared.fetchRecipesComplex(query: query, cuisine: cuisine, excludeCuisine: excludeCuisine, diet: diet, intolerances: intolerances, type: type) { (search, err) in
                if let err = err {
                    print("Failed to fetch apps:", err)
                    return
                }
                
                self.searchActivities = search!.recipes
                self.removeSpinner()
                
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.checkIfThereAnyActivities()
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActivities = [Recipe]()
        showGroups = true
        headerheight = 0
        cellheight = 397
        self.checkIfThereAnyActivities()
    }
    
    fileprivate func fetchData() {
        
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
                
        headerheight = 0
        cellheight = 397
            
        var recipes2: [Recipe]?
        var recipes3: [Recipe]?
        var recipes4: [Recipe]?
        var recipes5: [Recipe]?
        var recipes6: [Recipe]?
        
        // help you sync your data fetches together
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        Service.shared.fetchRecipesComplex(query: "", cuisine: ["\(self.sections[1])"], excludeCuisine: [""], diet: "", intolerances: [""], type: "") { (search, err) in
            recipes2 = search?.recipes
            dispatchGroup.leave()
            
            dispatchGroup.notify(queue: .main) {
                self.removeSpinner()
                if let group = recipes2 {
                    self.groups.append(group)
                } else {
                    self.sections.removeAll{ $0 == self.sections[1]}
                }
                self.collectionView.reloadData()
                
                dispatchGroup.enter()
                Service.shared.fetchRecipesComplex(query: "", cuisine: [""], excludeCuisine: [""], diet: "\(self.sections[2])", intolerances: [""], type: "") { (search, err) in
                    recipes3 = search?.recipes
                    dispatchGroup.leave()
                    
                    dispatchGroup.notify(queue: .main) {
                        self.removeSpinner()
                        if let group = recipes3 {
                            self.groups.append(group)
                        } else {
                            self.sections.removeAll{ $0 == self.sections[2]}
                        }
                        self.collectionView.reloadData()
                            
                        dispatchGroup.enter()
                        Service.shared.fetchRecipesComplex(query: "", cuisine: ["\(self.sections[3])"], excludeCuisine: [""], diet: "", intolerances: [""], type: "") { (search, err) in
                        recipes4 = search?.recipes
                        dispatchGroup.leave()
                        
                        dispatchGroup.notify(queue: .main) {
                            self.removeSpinner()
                            if let group = recipes4 {
                                self.groups.append(group)
                            } else {
                                self.sections.removeAll{ $0 == self.sections[3]}
                            }
                            self.collectionView.reloadData()
                            
                            dispatchGroup.enter()
                            Service.shared.fetchRecipesComplex(query: "\(self.sections[4])", cuisine: [""], excludeCuisine: [""], diet: "", intolerances: [""], type: "") { (search, err) in
                                recipes5 = search?.recipes
                                dispatchGroup.leave()
                                
                                dispatchGroup.notify(queue: .main) {
                                    self.removeSpinner()
                                    if let group = recipes5 {
                                        self.groups.append(group)
                                    } else {
                                        self.sections.removeAll{ $0 == self.sections[4]}
                                    }
                                    self.collectionView.reloadData()
                                    
                                    dispatchGroup.enter()
                                    Service.shared.fetchRecipesComplex(query: "\(self.sections[5])", cuisine: [""], excludeCuisine: [""], diet: "", intolerances: [""], type: "") { (search, err) in
                                        recipes6 = search?.recipes
                                        dispatchGroup.leave()
                                        
                                        dispatchGroup.notify(queue: .main) {
                                            self.removeSpinner()
                                            if let group = recipes6 {
                                                self.groups.append(group)
                                            } else {
                                                self.sections.removeAll{ $0 == self.sections[5]}
                                            }
                                            self.collectionView.reloadData()
                                                
                                        }
                                    }
                                        
                                }
                            }
                                
                            }
                        }
                    }
                }
            }
        }
        
    }
    
    
    // MARK: UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if showGroups {
            return sections.count
        } else {
            return 0
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kActivityTypeCell, for: indexPath) as! ActivityTypeCell
        cell.horizontalController.conversations = conversations
        cell.horizontalController.activities = activities
        cell.horizontalController.users = users
        cell.horizontalController.filteredUsers = filteredUsers
        cell.horizontalController.favAct = favAct
        cell.horizontalController.conversation = conversation
        cell.horizontalController.schedule = schedule
        cell.horizontalController.umbrellaActivity = umbrellaActivity
        cell.arrowView.isHidden = true
        cell.delegate = self
        if showGroups {
            cell.titleLabel.text = sections[indexPath.item]
            if indexPath.item < groups.count {
                let recipes = groups[indexPath.item]
                cell.horizontalController.recipes = recipes
                cell.horizontalController.collectionView.reloadData()
                cell.horizontalController.didSelectHandler = { [weak self] recipe, favAct in
                    if let recipe = recipe as? Recipe {
                        print("meal \(recipe.title)")
                        let destination = MealDetailViewController()
                        destination.favAct = favAct
                        destination.recipe = recipe
                        destination.users = self!.users
                        destination.filteredUsers = self!.filteredUsers
                        destination.conversations = self!.conversations
                        destination.activities = self!.activities
                        destination.conversation = self!.conversation
                        destination.schedule = self!.schedule
                        destination.umbrellaActivity = self!.umbrellaActivity
                        destination.delegate = self!
                        self?.navigationController?.pushViewController(destination, animated: true)
                    }
                }
                cell.horizontalController.removeControllerHandler = { [weak self] type, activity in
                    if type == "activity" {
                        let nav = self?.tabBarController!.viewControllers![1] as! UINavigationController
                        if nav.topViewController is MasterActivityContainerController {
                            let homeTab = nav.topViewController as! MasterActivityContainerController
                            homeTab.customSegmented.setIndex(index: 2)
                            homeTab.changeToIndex(index: 2)
                        }
                        self!.tabBarController?.selectedIndex = 1
                        self!.navigationController?.backToViewController(viewController: ActivityTypeViewController.self)
                    } else if type == "schedule" {
                        self!.updateSchedule(schedule: activity)
                        self!.navigationController?.backToViewController(viewController: CreateActivityViewController.self)
                    }
                }
                cell.horizontalController.favActHandler = { [weak self] favAct in
                    self!.favAct = favAct
                }
            }
        }
        return cell
    }
        
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: cellheight)
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerId, for: indexPath) as! SearchHeader
        let recipes = searchActivities
        header.verticalController.recipes = recipes
        header.verticalController.favAct = favAct
        header.verticalController.collectionView.reloadData()
        header.verticalController.conversations = conversations
        header.verticalController.activities = activities
        header.verticalController.users = users
        header.verticalController.filteredUsers = filteredUsers
        header.verticalController.favAct = favAct
        header.verticalController.conversation = conversation
        header.verticalController.schedule = schedule
        header.verticalController.umbrellaActivity = umbrellaActivity
        header.verticalController.didSelectHandler = { [weak self] recipe, favAct in
            if let recipe = recipe as? Recipe {
                print("meal \(recipe.title)")
                let destination = MealDetailViewController()
                destination.recipe = recipe
                destination.favAct = favAct
                destination.users = self!.users
                destination.filteredUsers = self!.filteredUsers
                destination.conversations = self!.conversations
                destination.activities = self!.activities
                destination.conversation = self!.conversation
                destination.schedule = self!.schedule
                destination.umbrellaActivity = self!.umbrellaActivity
                destination.delegate = self!
                self?.navigationController?.pushViewController(destination, animated: true)
            }
        }
        header.verticalController.removeControllerHandler = { [weak self] type, activity in
            if type == "activity" {
                self!.navigationController?.backToViewController(viewController: ActivityViewController.self)
            } else if type == "schedule" {
                self!.updateSchedule(schedule: activity)
                self!.navigationController?.backToViewController(viewController: CreateActivityViewController.self)
            }
        }
        header.verticalController.favActHandler = { [weak self] favAct in
            self!.favAct = favAct
        }
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return .init(width: view.frame.width, height: headerheight)
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
            searchActivities = [Recipe]()
            self.filterDictionary = filterDictionary
            showGroups = true
            headerheight = 0
            cellheight = 397
            checkIfThereAnyActivities()
        }
    }
        
}
