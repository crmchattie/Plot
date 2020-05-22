//
//  IngredientSearchViewController.swift
//  Plot
//
//  Created by Cory McHattie on 5/16/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase

class IngredientSearchViewController: UIViewController {
    weak var delegate : UpdateIngredientDelegate?
    
    var searchBar: UISearchBar?
    let searchResultsTableView = UITableView()
    
    fileprivate var movingBackwards: Bool = true
    
    var ingredientDictionary = [String: Int]()
    var searchResults = [String: Int]()
    
    var ingredient: ExtendedIngredient!
    
    var viewPlaceholder = ViewPlaceholder()
    
    fileprivate var reference: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupSearchController()
        setupMainView()
        setupTableView()
        
        if #available(iOS 11.0, *) {
            let cancelBarButton =  UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
            
            navigationItem.rightBarButtonItem = cancelBarButton
        } else {
            let cancelBarButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancel))
            navigationItem.rightBarButtonItem = cancelBarButton
        }
        
        fetchIngredients()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.movingBackwards {
            if ingredient == nil {
                ingredient = ExtendedIngredient(id: nil, aisle: nil, image: nil, consitency: nil, name: "IngredientName", original: nil, originalString: nil, originalName: nil, amount: nil, unit: nil, meta: nil, metaInformation: nil, measures: nil, recipe: nil, bool: nil, unitLong: nil, unitShort: nil, possibleUnits: nil)
            }
            delegate?.updateIngredient(ingredient: ingredient, close: nil)
        }
    }
    
    fileprivate func setupSearchController() {
        searchBar = UISearchBar()
        searchBar?.delegate = self
        searchBar?.searchBarStyle = .minimal
        searchBar?.changeBackgroundColor(to: ThemeManager.currentTheme().searchBarColor)
        searchBar?.placeholder = "Search"
        searchBar?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
        searchResultsTableView.tableHeaderView = searchBar
    }
    
    fileprivate func setupMainView() {
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        navigationItem.title = "Ingredient"
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    }
    
    fileprivate func setupTableView() {

        
        view.addSubview(searchResultsTableView)
        searchResultsTableView.translatesAutoresizingMaskIntoConstraints = false
        searchResultsTableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        
        if #available(iOS 11.0, *) {
            searchResultsTableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0).isActive = true
            searchResultsTableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0).isActive = true
            searchResultsTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
        } else {
            searchResultsTableView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0).isActive = true
            searchResultsTableView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0).isActive = true
            searchResultsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
        }
        searchResultsTableView.delegate = self
        searchResultsTableView.dataSource = self
        searchResultsTableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        searchResultsTableView.sectionIndexBackgroundColor = view.backgroundColor
        searchResultsTableView.backgroundColor = view.backgroundColor
        searchResultsTableView.separatorStyle = .none
        searchResultsTableView.keyboardDismissMode = .onDrag

    }
    
    @objc func cancel() {
        //            self.dismiss(animated: true, completion: nil)
        navigationController?.popViewController(animated: true)
    }
    
    func checkIfThereAreAnyResults(isEmpty: Bool) {
        guard isEmpty else {
            viewPlaceholder.remove(from: searchResultsTableView, priority: .medium)
            return
        }
        viewPlaceholder.add(for: searchResultsTableView, title: .emptyIngredients, subtitle: .empty, priority: .medium, position: .top)
    }
    
    func fetchIngredients() {
        reference = Database.database().reference().child("ingredients")
        reference.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists(), let snapshotValue = snapshot.value {
                self.ingredientDictionary = snapshotValue as! [String: Int]
                print("ingredientDictionary \(self.ingredientDictionary)")

            }
          })
        { (error) in
            print(error.localizedDescription)
        }
    }
    
    func fetchIngredientInfo(id: Int) {
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        Service.shared.fetchIngredientInfo(id: id) { (search, err) in
            let ingredient = search
            dispatchGroup.leave()
            dispatchGroup.notify(queue: .main) {
                self.movingBackwards = false
                let destination = IngredientDetailViewController()
                destination.delegate = self
                destination.active = false
                destination.ingredient = ingredient
                self.navigationController?.pushViewController(destination, animated: true)
            }
        }
    }
    
}

extension IngredientSearchViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("searchText \(searchText)")
        searchResults = ingredientDictionary.filterDictionaryUsingRegex(withRegex: searchText)
        searchResultsTableView.reloadData()
    }
}

extension IngredientSearchViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchResults.count == 0 {
            checkIfThereAreAnyResults(isEmpty: true)
        } else {
            checkIfThereAreAnyResults(isEmpty: false)
        }
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let searchResult = Array(searchResults.keys)[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
        cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
        cell.textLabel?.text = searchResult.capitalized
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let searchResult = Array(searchResults.keys)[indexPath.row]
        fetchIngredientInfo(id: searchResults[searchResult]!)
    }
    

}

extension IngredientSearchViewController {
    
    func updateSearchResults(for searchController: UISearchController) {}
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text == nil {
            cancel()
        }
        searchBar.text = nil
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
        searchResultsTableView.reloadData()
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
        searchBar.setShowsCancelButton(true, animated: true)
        return true
    }
}

extension IngredientSearchViewController: UpdateIngredientDelegate {
    func updateIngredient(ingredient: ExtendedIngredient, close: Bool?) {
        self.ingredient = ingredient
        if let _ = close {
            delegate?.updateIngredient(ingredient: ingredient, close: nil)
        }
    }
}
