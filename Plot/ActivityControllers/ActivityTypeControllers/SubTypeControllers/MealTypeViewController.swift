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

    var filters: [filter] = [.cuisine, .excludeCuisine, .diet, .intolerances, .type]
    var filterDictionary = [String: [String]]()
        
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
        
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { (_) in
            self.complexSearch(query: searchText.lowercased(), cuisine: self.filterDictionary["cuisine"] ?? [""], excludeCuisine: self.filterDictionary["excludeCuisine"] ?? [""], diet: self.filterDictionary["diet"]?[0] ?? "", intolerances: self.filterDictionary["intolerances"] ?? [""], type: self.filterDictionary["type"]?[0] ?? "")
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
        cellheight = 415
        self.collectionView.reloadData()
    }
    
    fileprivate func fetchData() {
        
        if let navController = self.navigationController {
            self.showSpinner(onView: navController.view)
        } else {
            self.showSpinner(onView: self.view)
        }
                
        headerheight = 0
        cellheight = 415
            
        var recipes1: [Recipe]?
        var recipes2: [Recipe]?
        var recipes3: [Recipe]?
        
        // help you sync your data fetches together
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        Service.shared.fetchRecipesComplex(query: "dinner", cuisine: [""], excludeCuisine: [""], diet: "", intolerances: [""], type: "") { (search, err) in
            recipes1 = search?.recipes
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        Service.shared.fetchRecipesComplex(query: "", cuisine: [""], excludeCuisine: ["Vegetable"], diet: "", intolerances: [""], type: "") { (search, err) in
            recipes2 = search?.recipes
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        Service.shared.fetchRecipesComplex(query: "", cuisine: ["Italian"], excludeCuisine: [""], diet: "", intolerances: [""], type: "") { (search, err) in
            recipes3 = search?.recipes
            dispatchGroup.leave()
        }
        
        
        dispatchGroup.notify(queue: .main) {
            self.removeSpinner()
            if let group = recipes1 {
                self.groups.append(group)
                self.sections.append("Dinner")
            }
            if let group = recipes2 {
                self.groups.append(group)
                self.sections.append("Vegetarian")
            }
            if let group = recipes3 {
                self.groups.append(group)
                self.sections.append("Italian")
            }
            self.collectionView.reloadData()
        }
    }
    
    
    // MARK: UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if showGroups {
            return groups.count
        } else {
            return 0
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kActivityTypeCell, for: indexPath) as! ActivityTypeCell
        cell.delegate = self
        if showGroups {
            cell.titleLabel.text = sections[indexPath.item]
            let recipes = groups[indexPath.item]
            cell.horizontalController.recipes = recipes
    //        cell.horizontalController.didSelectHandler = { [weak self] recipe in
    //            let controller = AppDetailController(appId: feedResult.id)
    //            controller.navigationItem.title = feedResult.name
    //            self?.navigationController?.pushViewController(controller, animated: true)
    //        }
            
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
        header.verticalController.collectionView.reloadData()
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
            complexSearch(query: "", cuisine: filterDictionary["cuisine"] ?? [""], excludeCuisine: filterDictionary["excludeCuisine"] ?? [""], diet: filterDictionary["diet"]?[0] ?? "", intolerances: filterDictionary["intolerances"] ?? [""], type: filterDictionary["type"]?[0] ?? "")
        } else {
            searchRecipes = [Recipe]()
            self.filterDictionary = filterDictionary
            showGroups = true
            headerheight = 0
            cellheight = 415
            self.collectionView.reloadData()
        }
    }
        
}
