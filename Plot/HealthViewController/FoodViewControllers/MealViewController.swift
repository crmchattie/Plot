//
//  MealDetailViewController.swift
//  Plot
//
//  Created by Cory McHattie on 10/26/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import SplitRow
import Firebase
import CodableFirebase

protocol UpdateMealDelegate: class {
    func updateMeal(meal: Meal)
}

class MealViewController: FormViewController {
    weak var delegate : UpdateMealDelegate?
    
    var meal: Meal!
    
    var users = [User]()
    var filteredUsers = [User]()
    var selectedFalconUsers = [User]()
    
    var activities = [Activity]()
    var conversations = [Conversation]()
    
    var activity: Activity!
    
    var userNames : [String] = []
    var userNamesString: String = ""
    
    fileprivate var active: Bool = false
    fileprivate var movingBackwards: Bool = true
    
    fileprivate var productIndex: Int = 0
    
    let numberFormatter = NumberFormatter()
    
    var timer: Timer?
    
    var chatLogController: ChatLogController? = nil
    var messagesFetcher: MessagesFetcher? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTableView()
        
        if meal != nil {
            active = true
            
            var participantCount = self.selectedFalconUsers.count
            
            // If user is creating this activity (admin)
            if meal.admin == nil || meal.admin == Auth.auth().currentUser?.uid {
                participantCount += 1
            }
            
            if participantCount > 1 {
                self.userNamesString = "\(participantCount) participants"
            } else {
                self.userNamesString = "1 participant"
            }
            
            if let inviteesRow: ButtonRow = self.form.rowBy(tag: "Participants") {
                inviteesRow.title = self.userNamesString
                inviteesRow.updateCell()
            }
            resetBadgeForSelf()
        } else {
            if let currentUserID = Auth.auth().currentUser?.uid {
                let ID = Database.database().reference().child(userMealsEntity).child(currentUserID).childByAutoId().key ?? ""
                meal = Meal(id: ID, name: "MealName", admin: currentUserID)
            }
        }
        setupRightBarButton()
        initializeForm()
        calcNutrition()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.movingBackwards {
            delegate?.updateMeal(meal: meal)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard tableView.isEditing else { return }
        tableView.endEditing(true)
        tableView.reloadData()
    }
    
    fileprivate func configureTableView() {
        tableView.allowsMultipleSelectionDuringEditing = false
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.backgroundColor = view.backgroundColor
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        tableView.separatorStyle = .none
        definesPresentationContext = true
        navigationItem.title = "Meal"
    }
    
    func setupRightBarButton() {
//        if !active || self.selectedFalconUsers.count == 0 {
            let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(close))
            navigationItem.rightBarButtonItem = plusBarButton
//        } else {
//            let dotsImage = UIImage(named: "dots")
//            if #available(iOS 11.0, *) {
//                let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(close))
//                
//                let dotsBarButton = UIButton(type: .system)
//                dotsBarButton.setImage(dotsImage, for: .normal)
//                dotsBarButton.addTarget(self, action: #selector(goToExtras), for: .touchUpInside)
//                
//                navigationItem.rightBarButtonItems = [plusBarButton, UIBarButtonItem(customView: dotsBarButton)]
//            } else {
//                let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(close))
//                let dotsBarButton = UIBarButtonItem(image: dotsImage, style: .plain, target: self, action: #selector(goToExtras))
//                navigationItem.rightBarButtonItems = [plusBarButton, dotsBarButton]
//            }
//        }
    }
    
    @objc fileprivate func close() {
        movingBackwards = false
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if active {
            alert.addAction(UIAlertAction(title: "Update Meal", style: .default, handler: { (_) in
                print("User click Approve button")
                
                // update
                self.showActivityIndicator()
                let createMeal = MealActions(meal: self.meal, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                createMeal.createNewMeal()
                self.hideActivityIndicator()

                self.navigationController?.popViewController(animated: true)
                
            }))
            
            alert.addAction(UIAlertAction(title: "Duplicate Meal", style: .default, handler: { (_) in
                print("User click Approve button")
                // create new meal with updated time
                guard self.currentReachabilityStatus != .notReachable else {
                    basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
                    return
                }
                
                if let currentUserID = Auth.auth().currentUser?.uid {
                    self.showActivityIndicator()
                    let createMeal = MealActions(meal: self.meal, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    createMeal.createNewMeal()

                    //duplicate meal
                    let newMealID = Database.database().reference().child(userMealsEntity).child(currentUserID).childByAutoId().key ?? ""
                    var newMeal = self.meal!
                    newMeal.id = newMealID
                    newMeal.admin = currentUserID
                    newMeal.participantsIDs = nil

                    let createNewMeal = MealActions(meal: newMeal, active: false, selectedFalconUsers: [])
                    createNewMeal.createNewMeal()
                    self.hideActivityIndicator()

                    self.navigationController?.popViewController(animated: true)
                }
                
                
            }))
            
        } else {
            alert.addAction(UIAlertAction(title: "Create New Meal", style: .default, handler: { (_) in
                print("User click Approve button")
                // create new activity
                self.showActivityIndicator()
                let createMeal = MealActions(meal: self.meal, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                createMeal.createNewMeal()
                self.hideActivityIndicator()
                
                let nav = self.tabBarController!.viewControllers![1] as! UINavigationController
                if nav.topViewController is MasterActivityContainerController {
                    let homeTab = nav.topViewController as! MasterActivityContainerController
                    homeTab.customSegmented.setIndex(index: 0)
                    homeTab.changeToIndex(index: 0)
                }
                self.tabBarController?.selectedIndex = 1
                if #available(iOS 13.0, *) {
                    self.navigationController?.backToViewController(viewController: DiscoverViewController.self)
                } else {
                    // Fallback on earlier versions
                }
            }))
            
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
        
    }
    
    @objc func goToExtras() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        
        
        //        alert.addAction(UIAlertAction(title: "Share Grocery List", style: .default, handler: { (_) in
        //            print("User click Edit button")
        //            self.share()
        //        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
        print("shareButtonTapped")
        
    }
    
    func initializeForm() {
        print("initializing form")
        form +++
            Section()
            
            <<< TextRow("Name") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.placeholder = $0.tag
                if active, let meal = meal {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    $0.value = meal.name
                } else {
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                    $0.cell.textField.becomeFirstResponder()
                }
            }.onChange() { [unowned self] row in
                if let rowValue = row.value {
                    self.meal.name = rowValue
                }
                if row.value == nil {
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                } else {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
            }
            
            <<< DateTimeInlineRow("Starts") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.dateFormatter?.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                $0.dateFormatter?.dateStyle = .medium
                $0.dateFormatter?.timeStyle = .short
                if self.active {
                    $0.value = self.meal!.startDateTime
                } else {
                    let original = Date()
                    let rounded = Date(timeIntervalSinceReferenceDate:
                    (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    let timezone = TimeZone.current
                    let seconds = TimeInterval(timezone.secondsFromGMT(for: Date()))
                    $0.value = rounded.addingTimeInterval(seconds)
                    self.meal.startDateTime = $0.value
                }
                }.onChange { [weak self] row in
                    let endRow: DateTimeInlineRow! = self?.form.rowBy(tag: "Ends")
                    if row.value?.compare(endRow.value!) == .orderedDescending {
                        endRow.value = Date(timeInterval: 0, since: row.value!)
                        endRow.updateCell()
                    }
                    self!.meal.startDateTime = row.value
                }.onExpandInlineRow { cell, row, inlineRow in
                    inlineRow.cellUpdate() { cell, row in
                        row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        row.cell.tintColor = ThemeManager.currentTheme().generalBackgroundColor
                        cell.datePicker.datePickerMode = .dateAndTime
                        cell.datePicker.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                    }
                    let color = cell.detailTextLabel?.textColor
                    row.onCollapseInlineRow { cell, _, _ in
                        cell.detailTextLabel?.textColor = color
                    }
                    cell.detailTextLabel?.textColor = cell.tintColor
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                }
            
            <<< DateTimeInlineRow("Ends"){
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.dateFormatter?.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                $0.dateFormatter?.dateStyle = .medium
                $0.dateFormatter?.timeStyle = .short
                if self.active {
                    $0.value = self.meal!.endDateTime
                } else {
                    let original = Date()
                    let rounded = Date(timeIntervalSinceReferenceDate:
                    (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    let timezone = TimeZone.current
                    let seconds = TimeInterval(timezone.secondsFromGMT(for: Date()))
                    $0.value = rounded.addingTimeInterval(seconds)
                    self.meal.endDateTime = $0.value
                }
                }.onChange { [weak self] row in
                    let startRow: DateTimeInlineRow! = self?.form.rowBy(tag: "Starts")
                    if row.value?.compare(startRow.value!) == .orderedAscending {
                        startRow.value = Date(timeInterval: 0, since: row.value!)
                        startRow.updateCell()
                    }
                    self!.meal.endDateTime = row.value
                }.onExpandInlineRow { cell, row, inlineRow in
                        inlineRow.cellUpdate() { cell, row in
                        row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        row.cell.tintColor = ThemeManager.currentTheme().generalBackgroundColor
                            cell.datePicker.datePickerMode = .dateAndTime
                            cell.datePicker.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                    }
                    let color = cell.detailTextLabel?.textColor
                    row.onCollapseInlineRow { cell, _, _ in
                        cell.detailTextLabel?.textColor = color
                    }
                    cell.detailTextLabel?.textColor = cell.tintColor
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                        
                    }
        
            <<< ButtonRow("Participants") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                row.cell.textLabel?.textAlignment = .left
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.title = row.tag
                if active {
                    row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    row.title = self.userNamesString
                }
            }.onCellSelection({ _,_ in
                self.openParticipantsInviter()
            }).cellUpdate { cell, row in
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textLabel?.textAlignment = .left
                if row.title == "Participants" {
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                } else {
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                }
            }
        
            <<< DecimalRow("Servings") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.formatter = numberFormatter
                $0.value = meal.amount
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }.onChange { row in
                self.meal.amount = row.value
                self.timer?.invalidate()
                
                self.timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { (_) in
                    self.calcNutrition()
                })
            }
        
        form +++
            MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                               header: "Items",
                               footer: "Add a item") {
                $0.tag = "itemfields"
                $0.addButtonProvider = { section in
                    return ButtonRow(){
                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        $0.title = "Add New Item"
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        cell.textLabel?.textAlignment = .left
                    }
                }
                $0.multivaluedRowToInsertAt = { index in
                    self.productIndex = index
                    self.openProduct()
                    return ButtonRow(){ row in
                        row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        row.cell.textLabel?.textAlignment = .left
                        row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    }.onCellSelection({ cell, row in
                        self.productIndex = index
                        self.openProduct()
                    }).cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        cell.textLabel?.textAlignment = .left
                    }
                }
                
            }
        
        if let products = self.meal.productContainer, !products.isEmpty {
            var mvs = (form.sectionBy(tag: "itemfields") as! MultivaluedSection)
            for product in products {
                if product.groceryProduct != nil {
                    mvs.insert(ButtonRow() { row in
                        row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        row.cell.textLabel?.textAlignment = .left
                        row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        row.title = "\(product.groceryProduct!.amount ?? 0) \(product.groceryProduct!.title.capitalized)"
                    }.onCellSelection({ cell, row in
                        self.productIndex = row.indexPath!.row
                        self.openProduct()
                    }).cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        cell.textLabel?.textAlignment = .left
                    }, at: mvs.count - 1)
                } else if product.menuProduct != nil {
                    mvs.insert(ButtonRow() { row in
                        row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        row.cell.textLabel?.textAlignment = .left
                        row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        row.title = "\(product.menuProduct!.amount ?? 0) \(product.menuProduct!.title.capitalized)"
                    }.onCellSelection({ cell, row in
                        self.productIndex = row.indexPath!.row
                        self.openProduct()
                    }).cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        cell.textLabel?.textAlignment = .left
                    }, at: mvs.count - 1)
                } else if product.complexIngredient != nil {
                    mvs.insert(ButtonRow() { row in
                        row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        row.cell.textLabel?.textAlignment = .left
                        row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        row.title = "\(product.complexIngredient!.amount ?? 0.0) \(product.complexIngredient!.unit?.capitalized ?? "") of \(product.complexIngredient!.name?.capitalized ?? "")"
                    }.onCellSelection({ cell, row in
                        self.productIndex = row.indexPath!.row
                        self.openProduct()
                    }).cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        cell.textLabel?.textAlignment = .left
                    }, at: mvs.count - 1)
                }
            }
        }
    }
    
    fileprivate func openProduct() {
        print("openProduct \(productIndex)")
        if let products = self.meal.productContainer, products.indices.contains(productIndex) {
            let product = products[productIndex]
            if let groceryProduct = product.groceryProduct {
                let destination = GroceryProductDetailViewController()
                destination.delegate = self
                destination.active = true
                destination.product = groceryProduct
                self.navigationController?.pushViewController(destination, animated: true)
            } else if let menuProduct = product.menuProduct {
                let destination = MenuProductDetailViewController()
                destination.delegate = self
                destination.active = true
                destination.product = menuProduct
                self.navigationController?.pushViewController(destination, animated: true)
            } else if let ingredient = product.complexIngredient {
                let destination = IngredientDetailViewController()
                destination.delegate = self
                destination.active = true
                destination.ingredient = ingredient
                self.navigationController?.pushViewController(destination, animated: true)
            }
        } else {
            let destination = MealProductSearchViewController()
            destination.delegate = self
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    fileprivate func calcNutrition() {
        var nutrients = [Nutrient]()
        if let productContainerList = meal.productContainer {
            for productContainer in productContainerList {
                if let product = productContainer.groceryProduct {
                    if nutrients.isEmpty {
                        nutrients = product.nutrition?.nutrients ?? []
                    } else if let productNutrients = product.nutrition?.nutrients {
                        for nutrient in productNutrients {
                            if let index = nutrients.firstIndex(where: {$0.title == nutrient.title}) {
                                nutrients[index].amount! += nutrient.amount ?? 0
                                nutrients[index].percentOfDailyNeeds! += nutrient.percentOfDailyNeeds ?? 0
                            } else {
                                nutrients.append(nutrient)
                            }
                        }
                    }
                } else if let product = productContainer.menuProduct {
                    if nutrients.isEmpty {
                        nutrients = product.nutrition?.nutrients ?? []
                    } else if let productNutrients = product.nutrition?.nutrients {
                        for nutrient in productNutrients {
                            if let index = nutrients.firstIndex(where: {$0.title == nutrient.title}) {
                                nutrients[index].amount! += nutrient.amount ?? 0
                                nutrients[index].percentOfDailyNeeds! += nutrient.percentOfDailyNeeds ?? 0
                            } else {
                                nutrients.append(nutrient)
                            }
                        }
                    }
                } else if let product = productContainer.complexIngredient {
                    if nutrients.isEmpty {
                        nutrients = product.nutrition?.nutrients ?? []
                    } else if let productNutrients = product.nutrition?.nutrients {
                        for nutrient in productNutrients {
                            if let index = nutrients.firstIndex(where: {$0.title == nutrient.title}) {
                                nutrients[index].amount! += nutrient.amount ?? 0
                                nutrients[index].percentOfDailyNeeds! += nutrient.percentOfDailyNeeds ?? 0
                            } else {
                                nutrients.append(nutrient)
                            }
                        }
                    }
                }
            }
        }
        
        if !nutrients.isEmpty, let amount = meal.amount {
            for index in 0...nutrients.count - 1 {
                nutrients[index].amount! = nutrients[index].amount! * amount
                nutrients[index].percentOfDailyNeeds! = nutrients[index].percentOfDailyNeeds! * amount
            }
        }
        
        var nutrition = Nutrition()
        nutrition.nutrients = nutrients
        meal.nutrition = nutrition
        
        if let section = self.form.sectionBy(tag: "Nutrition") {
            if form.allSections.count > 1 {
                for _ in 0...form.allSections.count - 1 - section.index! {
                    form.remove(at: section.index!)
                }
            }
        }

        if !nutrients.isEmpty {
            form +++
            Section(header: "Nutrition", footer: nil) {
                $0.tag = "Nutrition"
            }
            
            var section = self.form.sectionBy(tag: "Nutrition")
            nutrients = nutrients.sorted(by: { $0.title!.compare($1.title!, options: .caseInsensitive) == .orderedAscending })
            for nutrient in nutrients {
                if let title = nutrient.title, let amount = nutrient.amount, let unit = nutrient.unit, String(format: "%.0f", amount) != "0" {
                    section!.insert(LabelRow() {
                    $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    $0.title = "\(title.capitalized)"
                    $0.value = "\(String(format: "%.0f", amount)) \(unit.capitalized)"
                    }.cellUpdate { cell, _ in
                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    }, at: section!.count)
                }
            }
        }
    }
    
    override func rowsHaveBeenRemoved(_ rows: [BaseRow], at indexes: [IndexPath]) {
        super.rowsHaveBeenRemoved(rows, at: indexes)
        let rowNumber : Int = indexes.first!.row
        let rowType = rows[0].self
        DispatchQueue.main.async { [weak self] in
            if rowType is ButtonRow, let productContainer = self!.meal.productContainer, productContainer.indices.contains(rowNumber) {
                self!.meal.productContainer!.remove(at: rowNumber)
                self!.calcNutrition()
            }
        }
    }
    
    @objc fileprivate func openParticipantsInviter() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        let destination = SelectActivityMembersViewController()
        var uniqueUsers = users
        for participant in selectedFalconUsers {
            if let userIndex = users.firstIndex(where: { (user) -> Bool in
                                                    return user.id == participant.id }) {
                uniqueUsers[userIndex] = participant
            } else {
                uniqueUsers.append(participant)
            }
        }
        
        destination.users = uniqueUsers
        destination.filteredUsers = uniqueUsers
        if !selectedFalconUsers.isEmpty {
            destination.priorSelectedUsers = selectedFalconUsers
        }
        destination.delegate = self
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    func showActivityIndicator() {
        if let navController = self.navigationController {
            self.showSpinner(onView: navController.view)
        } else {
            self.showSpinner(onView: self.view)
        }
        self.navigationController?.view.isUserInteractionEnabled = false
    }
    
    func hideActivityIndicator() {
        self.navigationController?.view.isUserInteractionEnabled = true
        self.removeSpinner()
    }
    
    func getSelectedFalconUsers(forMeal meal: Meal, completion: @escaping ([User])->()) {
        guard let participantsIDs = meal.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        var selectedFalconUsers = [User]()
        let group = DispatchGroup()
        for id in participantsIDs {
            // Only if the current user is created this activity
            if meal.admin == currentUserID && id == currentUserID {
                continue
            }
            
            group.enter()
            let participantReference = Database.database().reference().child("users").child(id)
            participantReference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), var dictionary = snapshot.value as? [String: AnyObject] {
                    dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                    let user = User(dictionary: dictionary)
                    selectedFalconUsers.append(user)
                }
                group.leave()
            })
        }
        
        group.notify(queue: .main) {
            completion(selectedFalconUsers)
        }
    }
    
    fileprivate func resetBadgeForSelf() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        let badgeRef = Database.database().reference().child(userMealsEntity).child(currentUserID).child(meal.id).child("badge")
        badgeRef.runTransactionBlock({ (mutableData) -> TransactionResult in
            var value = mutableData.value as? Int
            value = 0
            mutableData.value = value!
            return TransactionResult.success(withValue: mutableData)
        })
    }
}

extension MealViewController: UpdateInvitees {
    func updateInvitees(selectedFalconUsers: [User]) {
        if let inviteesRow: ButtonRow = form.rowBy(tag: "Participants") {
            if !selectedFalconUsers.isEmpty {
                self.selectedFalconUsers = selectedFalconUsers
                var participantCount = self.selectedFalconUsers.count
                // If user is creating this activity (admin)
                if meal.admin == nil || meal.admin == Auth.auth().currentUser?.uid {
                    participantCount += 1
                }
                if participantCount > 1 {
                    self.userNamesString = "\(participantCount) participants"
                } else {
                    self.userNamesString = "1 participant"
                }
                
                inviteesRow.title = self.userNamesString
                inviteesRow.updateCell()
                
            } else {
                self.selectedFalconUsers = selectedFalconUsers
                inviteesRow.title = "1 participant"
                inviteesRow.updateCell()
            }
            
            if active {
                showActivityIndicator()
                let createMeal = MealActions(meal: meal, active: active, selectedFalconUsers: selectedFalconUsers)
                createMeal.updateMealParticipants()
                hideActivityIndicator()
                
            }
            
        }
    }
}

extension MealViewController: MessagesDelegate {
    
    func messages(shouldChangeMessageStatusToReadAt reference: DatabaseReference) {
        chatLogController?.updateMessageStatus(messageRef: reference)
    }
    
    func messages(shouldBeUpdatedTo messages: [Message], conversation: Conversation) {
        
        chatLogController?.hidesBottomBarWhenPushed = true
        chatLogController?.messagesFetcher = messagesFetcher
        chatLogController?.messages = messages
        chatLogController?.conversation = conversation
        
        if let membersIDs = conversation.chatParticipantsIDs, let uid = Auth.auth().currentUser?.uid, membersIDs.contains(uid) {
            chatLogController?.observeTypingIndicator()
            chatLogController?.configureTitleViewWithOnlineStatus()
        }
        
        chatLogController?.messagesFetcher.collectionDelegate = chatLogController
        guard let destination = chatLogController else { return }
        
        self.chatLogController?.startCollectionViewAtBottom()
        
        
        // If we're presenting a modal sheet
        if let presentedViewController = presentedViewController as? UINavigationController {
            presentedViewController.pushViewController(destination, animated: true)
        } else {
            navigationController?.pushViewController(destination, animated: true)
        }
        
        chatLogController = nil
        messagesFetcher?.delegate = nil
        messagesFetcher = nil
    }
}

extension MealViewController: UpdateFoodProductContainerDelegate {
    func updateFoodProductContainer(foodProductContainer: FoodProductContainer?, close: Bool?) {
        if let mvs = self.form.sectionBy(tag: "itemfields") as? MultivaluedSection {
            if let foodProductContainer = foodProductContainer {
                let row = mvs.allRows[productIndex]
                if foodProductContainer.groceryProduct != nil {
                    row.title = "\(foodProductContainer.groceryProduct!.amount ?? 0) \(foodProductContainer.groceryProduct!.title.capitalized)"
                } else if foodProductContainer.menuProduct != nil {
                    row.title = "\(foodProductContainer.menuProduct!.amount ?? 0) \(foodProductContainer.menuProduct!.title.capitalized)"
                } else if foodProductContainer.complexIngredient != nil {
                    row.title = "\(foodProductContainer.complexIngredient!.amount ?? 0.0) \(foodProductContainer.complexIngredient!.unit?.capitalized ?? "") of \(foodProductContainer.complexIngredient!.name?.capitalized ?? "")"
                }
                row.updateCell()
                if let productContainer = meal.productContainer {
                    if productContainer.indices.contains(productIndex) {
                        self.meal.productContainer![productIndex] = foodProductContainer
                    } else {
                        self.meal.productContainer!.append(foodProductContainer)
                    }
                } else {
                    self.meal.productContainer = [foodProductContainer]
                }
                calcNutrition()
            } else {
                mvs.remove(at: productIndex)
            }
        }
    }
}

extension MealViewController: UpdateListDelegate {
    func updateRecipe(recipe: Recipe?) {
        
    }
    func updateList(recipe: Recipe?, workout: PreBuiltWorkout?, event: Event?, place: FSVenue?, activityType: String?) {
        
    }
}
