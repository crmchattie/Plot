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

protocol UpdateMealDelegate: AnyObject {
    func updateMeal(meal: Meal)
}

class MealViewController: FormViewController {
    var meal: Meal!
    
    lazy var users: [User] = networkController.userService.users
    lazy var filteredUsers: [User] = networkController.userService.users
    lazy var activities: [Activity] = networkController.activityService.events
    
    var selectedFalconUsers = [User]()
                
    fileprivate var productIndex: Int = 0
    
    let numberFormatter = NumberFormatter()
    
    var timer: Timer?
    
    var chatLogController: ChatLogController? = nil
    var messagesFetcher: MessagesFetcher? = nil
    
    //added for EventViewController
    var movingBackwards: Bool = false
    var active: Bool = false    
    
    weak var delegate : UpdateMealDelegate?
    weak var updateDiscoverDelegate : UpdateDiscover?
    
    var networkController: NetworkController
    
    init(networkController: NetworkController) {
        self.networkController = networkController
        super.init(style: .insetGrouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.isHidden = false
        navigationItem.largeTitleDisplayMode = .never        
        
        configureTableView()
        
        if meal != nil {
            title = "Meal"
            active = true
        } else {
            title = "New Meal"
            if let currentUserID = Auth.auth().currentUser?.uid {
                let ID = Database.database().reference().child(userMealsEntity).child(currentUserID).childByAutoId().key ?? ""
                meal = Meal(id: ID, name: "Name", admin: currentUserID, lastModifiedDate: Date(), createdDate: Date(), startDateTime: nil, endDateTime: nil)
            }
        }
        setupRightBarButton()
        initializeForm()
        calcNutrition()
        
        if active {
            for row in form.rows {
                row.baseCell.isUserInteractionEnabled = false
            }
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if movingBackwards {
            self.delegate?.updateMeal(meal: meal)
        }
    }
    
    fileprivate func configureTableView() {
        tableView.allowsMultipleSelectionDuringEditing = false
        view.backgroundColor = .systemGroupedBackground
        tableView.indicatorStyle = .default
        tableView.backgroundColor = view.backgroundColor
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        tableView.separatorStyle = .none
        definesPresentationContext = true
        navigationOptions = .Disabled
    }
    
    func setupRightBarButton() {
        if !active {
            let addBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(create))
            navigationItem.rightBarButtonItem = addBarButton
        }
        if navigationItem.leftBarButtonItem != nil {
            navigationItem.leftBarButtonItem?.action = #selector(cancel)
        }
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc fileprivate func create() {
        if active {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Update Meal", style: .default, handler: { (_) in
                print("User click Approve button")
                
                // update
                self.showActivityIndicator()
                let createMeal = MealActions(meal: self.meal, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                createMeal.createNewMeal()
                self.hideActivityIndicator()
                if self.navigationItem.leftBarButtonItem != nil {
                    self.dismiss(animated: true, completion: nil)
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
                
            }))
            
            alert.addAction(UIAlertAction(title: "Duplicate Meal", style: .default, handler: { (_) in
                print("User click Approve button")
                // create new meal with updated time
                guard self.currentReachabilityStatus != .notReachable else {
                    basicErrorAlertWithClose(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
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

                    if self.navigationItem.leftBarButtonItem != nil {
                        self.dismiss(animated: true, completion: nil)
                    } else {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
                
                
            }))
            
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                print("User click Dismiss button")
            }))
            
            self.present(alert, animated: true, completion: {
                print("completion block")
            })
            
        } else {
            // create new activity
            self.showActivityIndicator()
            let createMeal = MealActions(meal: self.meal, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
            createMeal.createNewMeal()
            self.hideActivityIndicator()
            self.delegate?.updateMeal(meal: meal)
            if navigationItem.leftBarButtonItem != nil {
                self.dismiss(animated: true, completion: nil)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        }
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
        
    }
    
    func initializeForm() {
        form +++
            Section()
            
            <<< TextRow("Name") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textField?.textColor = .label
                $0.placeholderColor = .secondaryLabel
                $0.placeholder = $0.tag
                if active, let meal = meal {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    $0.value = meal.name
                } else {
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                    //$0.cell.textField.becomeFirstResponder()
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
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textField?.textColor = .label
                row.placeholderColor = .secondaryLabel
            }
            
            <<< DateTimeInlineRow("Starts") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textLabel?.textColor = .label
                $0.cell.detailTextLabel?.textColor = .secondaryLabel
                $0.title = $0.tag
                $0.dateFormatter?.dateStyle = .medium
                $0.dateFormatter?.timeStyle = .short
                $0.minuteInterval = 5
                if self.active {
                    $0.value = self.meal!.startDateTime
                } else {
                    let original = Date()
                    let rounded = Date(timeIntervalSinceReferenceDate:
                    (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    $0.value = rounded
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
                        row.cell.backgroundColor = .secondarySystemGroupedBackground
                        row.cell.tintColor = .secondarySystemGroupedBackground
                        cell.datePicker.datePickerMode = .dateAndTime
                        if #available(iOS 14.0, *) {
                            cell.datePicker.preferredDatePickerStyle = .inline
                            cell.datePicker.tintColor = .systemBlue
                        }
                    }
                    let color = cell.detailTextLabel?.textColor
                    row.onCollapseInlineRow { cell, _, _ in
                        cell.detailTextLabel?.textColor = color
                    }
                    cell.detailTextLabel?.textColor = cell.tintColor
                }.cellUpdate { cell, row in
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                    cell.detailTextLabel?.textColor = .secondaryLabel
                }
            
            <<< DateTimeInlineRow("Ends"){
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textLabel?.textColor = .label
                $0.cell.detailTextLabel?.textColor = .secondaryLabel
                $0.title = $0.tag
                $0.dateFormatter?.dateStyle = .medium
                $0.dateFormatter?.timeStyle = .short
                $0.minuteInterval = 5
                if self.active {
                    $0.value = self.meal!.endDateTime
                } else {
                    let original = Date()
                    let rounded = Date(timeIntervalSinceReferenceDate:
                    (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    $0.value = rounded
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
                        row.cell.backgroundColor = .secondarySystemGroupedBackground
                        row.cell.tintColor = .secondarySystemGroupedBackground
                            cell.datePicker.datePickerMode = .dateAndTime
                            if #available(iOS 14.0, *) {
                                cell.datePicker.preferredDatePickerStyle = .inline
                                cell.datePicker.tintColor = .systemBlue
                            }
                    }
                    let color = cell.detailTextLabel?.textColor
                    row.onCollapseInlineRow { cell, _, _ in
                        cell.detailTextLabel?.textColor = color
                    }
                    cell.detailTextLabel?.textColor = cell.tintColor
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = .secondarySystemGroupedBackground
                        cell.textLabel?.textColor = .label
                        cell.detailTextLabel?.textColor = .secondaryLabel
                        
                    }
        
            <<< LabelRow("Participants") { row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.textLabel?.textColor = .label
                row.cell.detailTextLabel?.textColor = .secondaryLabel
                row.cell.accessoryType = .disclosureIndicator
                row.cell.textLabel?.textAlignment = .left
                row.cell.selectionStyle = .default
                row.title = row.tag
                row.value = String(selectedFalconUsers.count + 1)
            }.onCellSelection({ _, row in
                self.openParticipantsInviter()
            }).cellUpdate { cell, row in
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.textColor = .secondaryLabel
                cell.textLabel?.textAlignment = .left
            }
        
            <<< DecimalRow("Amount") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textField?.textColor = .secondaryLabel
                $0.title = $0.tag
                $0.formatter = numberFormatter
                $0.value = meal.amount
            }.cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textField?.textColor = .secondaryLabel
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
                               footer: "Add an Item") {
                $0.tag = "itemfields"
                $0.addButtonProvider = { section in
                    return ButtonRow(){
                        $0.cell.backgroundColor = .secondarySystemGroupedBackground
                        $0.title = "Add New Item"
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = .secondarySystemGroupedBackground
                        cell.textLabel?.textAlignment = .left
                    }
                }
                $0.multivaluedRowToInsertAt = { index in
                    self.productIndex = index
                    self.openProduct()
                    return ButtonRow(){ row in
                        row.cell.backgroundColor = .secondarySystemGroupedBackground
                        row.cell.textLabel?.textAlignment = .left
                        row.cell.textLabel?.textColor = .label
                    }.onCellSelection({ cell, row in
                        self.productIndex = index
                        self.openProduct()
                    }).cellUpdate { cell, row in
                        cell.backgroundColor = .secondarySystemGroupedBackground
                        cell.textLabel?.textColor = .label
                        cell.textLabel?.textAlignment = .left
                    }
                }
                
            }
        
        if let products = self.meal.productContainer, !products.isEmpty {
            var mvs = (form.sectionBy(tag: "itemfields") as! MultivaluedSection)
            for product in products {
                if product.groceryProduct != nil {
                    mvs.insert(ButtonRow() { row in
                        row.cell.backgroundColor = .secondarySystemGroupedBackground
                        row.cell.textLabel?.textAlignment = .left
                        row.cell.textLabel?.textColor = .label
                        row.title = "\(product.groceryProduct!.amount ?? 0) \(product.groceryProduct!.title.capitalized)"
                    }.onCellSelection({ cell, row in
                        self.productIndex = row.indexPath!.row
                        self.openProduct()
                    }).cellUpdate { cell, row in
                        cell.backgroundColor = .secondarySystemGroupedBackground
                        cell.textLabel?.textColor = .label
                        cell.textLabel?.textAlignment = .left
                    }, at: mvs.count - 1)
                } else if product.menuProduct != nil {
                    mvs.insert(ButtonRow() { row in
                        row.cell.backgroundColor = .secondarySystemGroupedBackground
                        row.cell.textLabel?.textAlignment = .left
                        row.cell.textLabel?.textColor = .label
                        row.title = "\(product.menuProduct!.amount ?? 0) \(product.menuProduct!.title.capitalized)"
                    }.onCellSelection({ cell, row in
                        self.productIndex = row.indexPath!.row
                        self.openProduct()
                    }).cellUpdate { cell, row in
                        cell.backgroundColor = .secondarySystemGroupedBackground
                        cell.textLabel?.textColor = .label
                        cell.textLabel?.textAlignment = .left
                    }, at: mvs.count - 1)
                } else if product.complexIngredient != nil {
                    mvs.insert(ButtonRow() { row in
                        row.cell.backgroundColor = .secondarySystemGroupedBackground
                        row.cell.textLabel?.textAlignment = .left
                        row.cell.textLabel?.textColor = .label
                        row.title = "\(product.complexIngredient!.amount ?? 0.0) \(product.complexIngredient!.unit?.capitalized ?? "") of \(product.complexIngredient!.name?.capitalized ?? "")"
                    }.onCellSelection({ cell, row in
                        self.productIndex = row.indexPath!.row
                        self.openProduct()
                    }).cellUpdate { cell, row in
                        cell.backgroundColor = .secondarySystemGroupedBackground
                        cell.textLabel?.textColor = .label
                        cell.textLabel?.textAlignment = .left
                    }, at: mvs.count - 1)
                }
            }
        }
    }
    
    fileprivate func openProduct() {
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
                            if let index = nutrients.firstIndex(where: {$0.name == nutrient.name}) {
                                nutrients[index].amount! += nutrient.amount ?? 0
                                nutrients[index].percentOfDailyNeeds = (nutrients[index].percentOfDailyNeeds ?? 0) + (nutrient.percentOfDailyNeeds ?? 0)
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
                            if let index = nutrients.firstIndex(where: {$0.name == nutrient.name}) {
                                nutrients[index].amount! += nutrient.amount ?? 0
                                nutrients[index].percentOfDailyNeeds = (nutrients[index].percentOfDailyNeeds ?? 0) + (nutrient.percentOfDailyNeeds ?? 0)
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
                            if let index = nutrients.firstIndex(where: {$0.name == nutrient.name}) {
                                nutrients[index].amount! += nutrient.amount ?? 0
                                nutrients[index].percentOfDailyNeeds = (nutrients[index].percentOfDailyNeeds ?? 0) + (nutrient.percentOfDailyNeeds ?? 0)
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
            nutrients = nutrients.sorted(by: { $0.name!.compare($1.name!, options: .caseInsensitive) == .orderedAscending })
            for nutrient in nutrients {
                if let title = nutrient.name, let amount = nutrient.amount, let unit = nutrient.unit, String(format: "%.0f", amount) != "0" {
                    section!.insert(LabelRow() {
                    $0.cell.backgroundColor = .secondarySystemGroupedBackground
                    $0.cell.textLabel?.textColor = .label
                    $0.cell.detailTextLabel?.textColor = .secondaryLabel
                    $0.title = "\(title.capitalized)"
                    $0.value = "\(String(format: "%.0f", amount)) \(unit.capitalized)"
                    }.cellUpdate { cell, _ in
                        cell.backgroundColor = .secondarySystemGroupedBackground
                        cell.textLabel?.textColor = .label
                    }, at: section!.count)
                }
            }
        }
    }
    
    override func rowsHaveBeenRemoved(_ rows: [BaseRow], at indexes: [IndexPath]) {
        super.rowsHaveBeenRemoved(rows, at: indexes)
        let rowNumber : Int = indexes.first!.row
        let row = rows[0].self
        DispatchQueue.main.async { [weak self] in
            if row is ButtonRow, let productContainer = self!.meal.productContainer, productContainer.indices.contains(rowNumber) {
                self!.meal.productContainer!.remove(at: rowNumber)
                self!.calcNutrition()
            }
        }
    }
    
    @objc fileprivate func openParticipantsInviter() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWithClose(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
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
        destination.ownerID = meal.admin
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
}

extension MealViewController: UpdateInvitees {
    func updateInvitees(selectedFalconUsers: [User]) {
        if let inviteesRow: LabelRow = form.rowBy(tag: "Participants") {
            self.selectedFalconUsers = selectedFalconUsers
            inviteesRow.value = String(selectedFalconUsers.count + 1)
            inviteesRow.updateCell()
            
            if active {
                showActivityIndicator()
                let createMeal = MealActions(meal: meal, active: active, selectedFalconUsers: selectedFalconUsers)
                createMeal.updateMealParticipants()
                hideActivityIndicator()
                
            }
        }
    }
}

extension MealViewController: UpdateFoodProductContainerDelegate {
    func updateFoodProductContainer(foodProductContainer: FoodProductContainer?, close: Bool?) {
        var mvs = self.form.sectionBy(tag: "itemfields") as! MultivaluedSection
        if let foodProductContainer = foodProductContainer {
            if mvs.allRows.count - 1 == productIndex {
                mvs.insert(ButtonRow() { row in
                    row.cell.backgroundColor = .secondarySystemGroupedBackground
                    row.cell.textLabel?.textAlignment = .left
                    row.cell.textLabel?.textColor = .label
                }.onCellSelection({ cell, row in
                    self.productIndex = row.indexPath!.row
                    self.openProduct()
                }).cellUpdate { cell, row in
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                    cell.textLabel?.textAlignment = .left
                }, at: productIndex)
            }
            
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
        } else if mvs.allRows.count - 1 > productIndex {
            mvs.remove(at: productIndex)
        }
    }
}
