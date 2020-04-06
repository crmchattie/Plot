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
    var searchRecipes = [Recipe]()

    var filters: [filter] = [.cuisine, .excludeCuisine, .diet, .intolerances, .recipeType]
    var filterDictionary = [String: [String]]()
    var sections: [String] = ["American", "Italian", "Vegetarian"]
    
        
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
            self.complexSearch(query: searchText.lowercased(), cuisine: self.filterDictionary["cuisine"] ?? [""], excludeCuisine: self.filterDictionary["excludeCuisine"] ?? [""], diet: self.filterDictionary["diet"]?[0] ?? "", intolerances: self.filterDictionary["intolerances"] ?? [""], type: self.filterDictionary["recipeType"]?[0] ?? "")
        })
    }
    
    func complexSearch(query: String, cuisine: [String], excludeCuisine: [String], diet: String, intolerances: [String], type: String) {
        print("query \(query), cuisine \(cuisine), excludeCuisine \(excludeCuisine), diet \(diet), intolerances \(intolerances), type \(type), ")
        
        self.searchRecipes = [Recipe]()
        showGroups = false
        self.headerheight = view.frame.height
        self.cellheight = 0
        self.collectionView.reloadData()
        
        if let navController = self.navigationController {
            self.showSpinner(onView: navController.view)
        } else {
            self.showSpinner(onView: self.view)
        }
        
        let dispatchGroup = DispatchGroup()

        dispatchGroup.enter()
        Service.shared.fetchRecipesComplex(query: query, cuisine: cuisine, excludeCuisine: excludeCuisine, diet: diet, intolerances: intolerances, type: type) { (search, err) in
            if let err = err {
                print("Failed to fetch apps:", err)
                return
            }
            self.removeSpinner()
            self.searchRecipes = search!.recipes
            
            dispatchGroup.leave()
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchRecipes = [Recipe]()
        showGroups = true
        headerheight = 0
        cellheight = 397
        self.collectionView.reloadData()
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
        
        // help you sync your data fetches together
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        Service.shared.fetchRecipesSimple(query: "", cuisine: "Italian") { (search, err) in
            recipes2 = search?.recipes
            dispatchGroup.leave()
            
            dispatchGroup.notify(queue: .main) {
                self.removeSpinner()
                if let group = recipes2 {
                    self.groups.append(group)
                } else {
                    self.sections.removeAll{ $0 == "Italian"}
                }
                self.collectionView.reloadData()
                
                dispatchGroup.enter()
                Service.shared.fetchRecipesSimple(query: "vegetarian", cuisine: "") { (search, err) in
//                Service.shared.fetchRecipesComplex(query: "", cuisine: [""], excludeCuisine: [""], diet: "Vegetarian", intolerances: [""], type: "") { (search, err) in
                    recipes3 = search?.recipes
                    dispatchGroup.leave()
                    
                    dispatchGroup.notify(queue: .main) {
                    self.removeSpinner()
                    if let group = recipes3 {
                        self.groups.append(group)
                    } else {
                        self.sections.removeAll{ $0 == "Vegetarian"}
                    }
                    self.collectionView.reloadData()
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
        cell.horizontalController.favAct = favAct
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
                        destination.hidesBottomBarWhenPushed = true
                        destination.favAct = favAct
                        destination.recipe = recipe
                        destination.users = self!.users
                        destination.filteredUsers = self!.filteredUsers
                        destination.conversations = self!.conversations
                        self?.navigationController?.pushViewController(destination, animated: true)
                    }
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
        let recipes = searchRecipes
        header.verticalController.recipes = recipes
        header.verticalController.favAct = favAct
        header.verticalController.collectionView.reloadData()
        header.verticalController.didSelectHandler = { [weak self] recipe, favAct in
            if let recipe = recipe as? Recipe {
                print("meal \(recipe.title)")
                let destination = MealDetailViewController()
                destination.hidesBottomBarWhenPushed = true
                destination.recipe = recipe
                destination.favAct = favAct
                destination.users = self!.users
                destination.filteredUsers = self!.filteredUsers
                destination.conversations = self!.conversations
                self?.navigationController?.pushViewController(destination, animated: true)
            }
        }
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return .init(width: view.frame.width, height: headerheight)
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
            complexSearch(query: "", cuisine: filterDictionary["cuisine"] ?? [""], excludeCuisine: filterDictionary["excludeCuisine"] ?? [""], diet: filterDictionary["diet"]?[0] ?? "", intolerances: filterDictionary["intolerances"] ?? [""], type: filterDictionary["recipeType"]?[0] ?? "")
        } else {
            searchRecipes = [Recipe]()
            self.filterDictionary = filterDictionary
            showGroups = true
            headerheight = 0
            cellheight = 397
            self.collectionView.reloadData()
        }
    }
        
}
