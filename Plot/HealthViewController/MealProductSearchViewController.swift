//
//  MealProductSearchViewController.swift
//  Plot
//
//  Created by Cory McHattie on 10/26/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase

class MealProductSearchViewController: UIViewController {
    weak var groceryDelegate : UpdateGroceryProductDelegate?
    weak var menuDelegate : UpdateMenuProductDelegate?
    weak var listDelegate : UpdateListDelegate?
    
    var searchBar: UISearchBar?
    let searchResultsTableView = UITableView()
    
    fileprivate var movingBackwards: Bool = true
    
    var searchResults = [FoodHint]()
    
    var groceryProduct: GroceryProduct!
    var menuProduct: MenuProduct!
    var recipeProduct: Recipe!
    
    var viewPlaceholder = ViewPlaceholder()
    
    fileprivate var reference: DatabaseReference!
    
    var timer: Timer?
    
    var users = [User]()
    var filteredUsers = [User]()
    var selectedFalconUsers = [User]()
    var activities = [Activity]()
    var conversations = [Conversation]()
    
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.movingBackwards {
            
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //need to reassign as true if moving back from detail controller
        movingBackwards = true
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
        viewPlaceholder.add(for: searchResultsTableView, title: .emptyMealProducts, subtitle: .empty, priority: .medium, position: .top)
    }
    
    func fetchProducts(query: String) {
        searchResults = []
        let dispatchGroup = DispatchGroup()
//        dispatchGroup.enter()
//        Service.shared.fetchGroceryProducts(query: query) { (search, err) in
//            if let products = search?.products {
//                let groceryProducts = products.map { FoodProductContainer(groceryProduct: $0, menuProduct: nil, recipeProduct: nil, complexIngredient: nil, basicIngredient: nil) }
//                self.searchResults.append(contentsOf: groceryProducts)
//            }
//            dispatchGroup.leave()
//        }
//        
//        dispatchGroup.enter()
//        Service.shared.fetchMenuProducts(query: query) { (search, err) in
//            if let products = search?.menuItems {
//                let menuProducts = products.map { FoodProductContainer(groceryProduct: nil, menuProduct: $0, recipeProduct: nil, complexIngredient: nil, basicIngredient: nil) }
//                self.searchResults.append(contentsOf: menuProducts)
//            }
//            dispatchGroup.leave()
//        }
        
        dispatchGroup.enter()
        Service.shared.foodSearch(query: query) { (search, err) in
            if let products = search?.hints {
                self.searchResults.append(contentsOf: products)
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            self.searchResults = self.searchResults.sorted(by: { $0.food?.label?.compare($1.food?.label ?? "", options: .caseInsensitive) == .orderedAscending })
            self.searchResultsTableView.reloadData()
        }
    }
    
    func fetchProductInfo(groceryID: Int?, menuID: Int?, recipeID: Int?, foodHint: FoodHint?) {
        let dispatchGroup = DispatchGroup()
        if let groceryID = groceryID {
            dispatchGroup.enter()
            Service.shared.fetchGroceryProductInfo(id: groceryID) { (search, err) in
                let product = search
                dispatchGroup.leave()
                dispatchGroup.notify(queue: .main) {
                    self.movingBackwards = false
                    let destination = GroceryProductDetailViewController()
                    destination.delegate = self
                    destination.active = false
                    destination.product = product
                    self.navigationController?.pushViewController(destination, animated: true)
                }

            }
        } else if let menuID = menuID {
            dispatchGroup.enter()
            Service.shared.fetchMenuProductInfo(id: menuID) { (search, err) in
                let product = search
                dispatchGroup.leave()
                dispatchGroup.notify(queue: .main) {
                    self.movingBackwards = false
                    let destination = MenuProductDetailViewController()
                    destination.delegate = self
                    destination.active = false
                    destination.product = product
                    self.navigationController?.pushViewController(destination, animated: true)
                }
            }
        } else if let recipeID = recipeID {
            dispatchGroup.enter()
            Service.shared.fetchRecipesInfo(id: recipeID) { (search, err) in
                if let detailedRecipe = search {
                    dispatchGroup.leave()
                    dispatchGroup.notify(queue: .main) {
                        let destination = RecipeDetailViewController()
                        destination.recipe = detailedRecipe
                        destination.detailedRecipe = detailedRecipe
                        destination.activeList = true
                        destination.active = false
                        destination.listType = "grocery"
                        destination.activityType = "recipe"
                        destination.listDelegate = self
                        self.navigationController?.pushViewController(destination, animated: true)
                    }
                }
            }
        } else if let foodHint = foodHint, let food = foodHint.food, let foodID = food.foodID, let measures = foodHint.measures, let uri = measures[0].uri {
            dispatchGroup.enter()
            Service.shared.nutrientsSearch(foodId: foodID, measureURI: uri, quantity: nil, qualifiers: nil) { (search, err) in
                if let nutrientSearch = search {
                    print("nutrient \(nutrientSearch)")
                    dispatchGroup.leave()
                    dispatchGroup.notify(queue: .main) {
                        self.movingBackwards = false
                        let destination = FoodProductDetailViewController()
                        destination.delegate = self
                        destination.active = false
                        destination.product = nutrientSearch
                        destination.food = food
                        self.navigationController?.pushViewController(destination, animated: true)
                    }
                }
            }
        }
    }
    
}

extension MealProductSearchViewController: UITableViewDataSource, UITableViewDelegate {
    
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
        let product = searchResults[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
        cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
        cell.textLabel?.text = product.food?.label?.capitalized ?? ""
//        if product.food?.category != "" {
//            cell.detailTextLabel?.text = product.subtitle.capitalized
//        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let product = searchResults[indexPath.row]
        fetchProductInfo(groceryID: nil, menuID: nil, recipeID: nil, foodHint: product)
//        if let grocery = product.groceryProduct {
//            fetchProductInfo(groceryID: grocery.id, menuID: nil, recipeID: nil)
//        } else if let menu = product.menuProduct {
//            fetchProductInfo(groceryID: nil, menuID: menu.id, recipeID: nil)
//        } else if let recipe = product.recipeProduct {
//            fetchProductInfo(groceryID: nil, menuID: nil, recipeID: recipe.id)
//        }
    }
}

extension MealProductSearchViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { (_) in
            self.fetchProducts(query: searchText.lowercased())
        })
    }
}

extension MealProductSearchViewController {
    
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

extension MealProductSearchViewController: UpdateGroceryProductDelegate {
    func updateGroceryProduct(groceryProduct: GroceryProduct, close: Bool?) {
        self.groceryProduct = groceryProduct
        if let _ = close {
            groceryDelegate?.updateGroceryProduct(groceryProduct: groceryProduct, close: nil)
        }
    }
}

extension MealProductSearchViewController: UpdateMenuProductDelegate {
    func updateMenuProduct(menuProduct: MenuProduct, close: Bool?) {
        self.menuProduct = menuProduct
        if let _ = close {
            menuDelegate?.updateMenuProduct(menuProduct: menuProduct, close: nil)
        }
    }
}

extension MealProductSearchViewController: UpdateFoodProductDelegate {
    func updateFoodProduct(foodProduct: NutrientSearch, close: Bool?) {
        
    }
}

extension MealProductSearchViewController: UpdateListDelegate {
    func updateRecipe(recipe: Recipe?) {
        self.recipeProduct = recipe
        listDelegate?.updateRecipe(recipe: recipe)
    }
    func updateList(recipe: Recipe?, workout: PreBuiltWorkout?, event: Event?, place: FSVenue?, activityType: String?) {
        
    }
}

