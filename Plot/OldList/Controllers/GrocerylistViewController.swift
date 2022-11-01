//
//  GroceryListViewController.swift
//  Plot
//
//  Created by Cory McHattie on 5/7/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import SplitRow
import Firebase
import CodableFirebase

protocol UpdateGrocerylistDelegate: AnyObject {
    func updateGrocerylist(grocerylist: Grocerylist)
}

class GrocerylistViewController: FormViewController {
    weak var delegate : UpdateGrocerylistDelegate?
    
    var grocerylist: Grocerylist!
    var productContainer = [FoodProductContainer]()
    
    var users = [User]()
    var filteredUsers = [User]()
    var selectedFalconUsers = [User]()
    
    var activities = [Activity]()
    var conversations = [Conversation]()
    
    var activity: Activity!
    
    fileprivate var active: Bool = false
    fileprivate var movingBackwards: Bool = true
    var connectedToAct = true
    var comingFromLists = false
    
    fileprivate var ingredientIndex: Int = 0
    fileprivate var recipeIndex: Int = 0
    fileprivate var recipeID: String = ""
    
    var chatLogController: ChatLogController? = nil
    var messagesFetcher: MessagesFetcher? = nil
    
    init() {
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
        
        
                
        if grocerylist != nil {
            active = true
            
            if let ingredients = grocerylist.ingredients {
                let ingredientsProducts = ingredients.map { FoodProductContainer(groceryProduct: nil, menuProduct: nil, recipeProduct: nil, complexIngredient: $0, basicIngredient: nil) }
                self.productContainer.append(contentsOf: ingredientsProducts)
            }
            
            if let groceries = grocerylist.groceryProducts {
                let groceryProducts = groceries.map { FoodProductContainer(groceryProduct: $0, menuProduct: nil, recipeProduct: nil, complexIngredient: nil, basicIngredient: nil) }
                self.productContainer.append(contentsOf: groceryProducts)
            }
            
            resetBadgeForSelf()
        } else {
            if let currentUserID = Auth.auth().currentUser?.uid {
                let ID = Database.database().reference().child(userGrocerylistsEntity).child(currentUserID).childByAutoId().key ?? ""
                grocerylist = Grocerylist(dictionary: ["ID": ID as AnyObject])
                grocerylist.createdDate = Date()
                grocerylist.name = "GroceryListName"
            }
        }
        configureTableView()
        setupRightBarButton()
        initializeForm()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.movingBackwards && !comingFromLists {
            delegate?.updateGrocerylist(grocerylist: grocerylist)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard tableView.isEditing else { return }
        tableView.endEditing(true)
        tableView.reloadData()
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
        navigationItem.title = "Grocery List"
        navigationOptions = .Disabled
    }
    
    func setupRightBarButton() {
        if !comingFromLists || !active || self.selectedFalconUsers.count == 0 {
            let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(close))
            navigationItem.rightBarButtonItem = plusBarButton
        } else {
            let dotsImage = UIImage(named: "dots")
            if #available(iOS 11.0, *) {
                let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(close))
                
                let dotsBarButton = UIButton(type: .system)
                dotsBarButton.setImage(dotsImage, for: .normal)
                dotsBarButton.addTarget(self, action: #selector(goToExtras), for: .touchUpInside)
                
                navigationItem.rightBarButtonItems = [plusBarButton, UIBarButtonItem(customView: dotsBarButton)]
            } else {
                let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))
                let dotsBarButton = UIBarButtonItem(image: dotsImage, style: .plain, target: self, action: #selector(goToExtras))
                navigationItem.rightBarButtonItems = [plusBarButton, dotsBarButton]
            }
        }
    }
    
    @objc fileprivate func close() {
        movingBackwards = false
        
        if !comingFromLists {
            if let activity = activity {
                grocerylist.activityID = activity.activityID
            }
            grocerylist.lastModifiedDate = Date()
            delegate?.updateGrocerylist(grocerylist: grocerylist)
            self.navigationController?.popViewController(animated: true)
            
        }
        
    }
    
    @objc func goToExtras() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        
        if connectedToAct {
            if grocerylist.conversationID == nil {
                alert.addAction(UIAlertAction(title: "Connect Grocery List/Activity to a Chat", style: .default, handler: { (_) in
                    print("User click Approve button")
                    self.goToChat()
                    
                }))
            } else {
                alert.addAction(UIAlertAction(title: "Go to Chat", style: .default, handler: { (_) in
                    print("User click Approve button")
                    self.goToChat()
                    
                    
                }))
            }
        } else if grocerylist.conversationID == nil {
            alert.addAction(UIAlertAction(title: "Connect Grocery List to a Chat", style: .default, handler: { (_) in
                print("User click Approve button")
                self.goToChat()
                
            }))
        } else {
            alert.addAction(UIAlertAction(title: "Go to Chat", style: .default, handler: { (_) in
                print("User click Approve button")
                self.goToChat()
                
                
            }))
        }
        
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
    
    @objc func goToChat() {
        if let conversationID = grocerylist.conversationID {
            if let convo = conversations.first(where: {$0.chatID == conversationID}) {
                self.chatLogController = ChatLogController(collectionViewLayout: AutoSizingCollectionViewFlowLayout())
                self.messagesFetcher = MessagesFetcher()
                self.messagesFetcher?.delegate = self
                self.messagesFetcher?.loadMessagesData(for: convo)
            }
        } else {
            let destination = ChooseChatTableViewController()
            let navController = UINavigationController(rootViewController: destination)
            destination.delegate = self
            if let activity = grocerylist.activity {
                destination.activity = activity
            }
            destination.grocerylist = grocerylist
            destination.conversations = conversations
            destination.pinnedConversations = conversations
            destination.filteredConversations = conversations
            destination.filteredPinnedConversations = conversations
            present(navController, animated: true, completion: nil)
        }
    }
    
    func share() {
        //        if let activity = activity, let name = activity.name {
        //            let imageName = "activityLarge"
        //            if let image = UIImage(named: imageName) {
        //                let data = compressImage(image: image)
        //                let aO = ["activityName": "\(name)",
        //                            "activityID": activityID,
        //                            "activityImageURL": "\(imageName)",
        //                            "object": data] as [String: AnyObject]
        //                let activityObject = ActivityObject(dictionary: aO)
        //
        //                let alert = UIAlertController(title: "Share Activity", message: nil, preferredStyle: .actionSheet)
        //
        //                alert.addAction(UIAlertAction(title: "Inside of Plot", style: .default, handler: { (_) in
        //                    print("User click Approve button")
        //                    let destination = ChooseChatTableViewController()
        //                    let navController = UINavigationController(rootViewController: destination)
        //                    destination.activityObject = activityObject
        //                    destination.users = self.users
        //                    destination.filteredUsers = self.filteredUsers
        //                    destination.conversations = self.conversations
        //                    destination.filteredConversations = self.conversations
        //                    destination.filteredPinnedConversations = self.conversations
        //                    self.present(navController, animated: true, completion: nil)
        //
        //                }))
        //
        //                alert.addAction(UIAlertAction(title: "Outside of Plot", style: .default, handler: { (_) in
        //                    print("User click Edit button")
        //                        // Fallback on earlier versions
        //                    let shareText = "Hey! Download Plot on the App Store so I can share an activity with you."
        //                    guard let url = URL(string: "https://apps.apple.com/us/app/plot-scheduling-app/id1473764067?ls=1")
        //                        else { return }
        //                    let shareContent: [Any] = [shareText, url]
        //                    let activityController = UIActivityViewController(activityItems: shareContent,
        //                                                                      applicationActivities: nil)
        //                    self.present(activityController, animated: true, completion: nil)
        //                    activityController.completionWithItemsHandler = { (activityType: UIActivity.ActivityType?, completed:
        //                    Bool, arrayReturnedItems: [Any]?, error: Error?) in
        //                        if completed {
        //                            print("share completed")
        //                            return
        //                        } else {
        //                            print("cancel")
        //                        }
        //                        if let shareError = error {
        //                            print("error while sharing: \(shareError.localizedDescription)")
        //                        }
        //                    }
        //
        //                }))
        //
        //
        //                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
        //                    print("User click Dismiss button")
        //                }))
        //
        //                self.present(alert, animated: true, completion: {
        //                    print("completion block")
        //                })
        //                print("shareButtonTapped")
        //            }
        //
        //
        //        }
    }
    
    func initializeForm() {
        print("initializing form")
        form +++
            Section()
            
            <<< TextRow("Name") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textField?.textColor = .label
                $0.placeholderColor = .secondaryLabel
                $0.placeholder = $0.tag
                if active, let grocerylist = grocerylist {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    $0.value = grocerylist.name
                } else {
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                    $0.cell.textField.becomeFirstResponder()
                }
            }.onChange() { [unowned self] row in
                if let rowValue = row.value {
                    self.grocerylist.name = rowValue
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
        
        if !connectedToAct {
            form.last!
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
        }
        
        form.last!
        <<< TextAreaRow("Notes") {
            $0.cell.backgroundColor = .secondarySystemGroupedBackground
            $0.cell.textView?.backgroundColor = .secondarySystemGroupedBackground
            $0.cell.textView?.textColor = .label
            $0.cell.placeholderLabel?.textColor = .secondaryLabel
            $0.placeholder = $0.tag
            $0.value = grocerylist.notes
            }.cellUpdate({ (cell, row) in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textView?.backgroundColor = .secondarySystemGroupedBackground
                cell.textView?.textColor = .label
                cell.placeholderLabel?.textColor = .secondaryLabel
            }).onChange { row in
                self.grocerylist.notes = row.value
            }
        
        form +++
            
            MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                               header: "Recipe(s)",
                               footer: "Add a recipe") {
                                $0.tag = "recipefields"
                                $0.addButtonProvider = { section in
                                    return ButtonRow(){
                                        $0.cell.backgroundColor = .secondarySystemGroupedBackground
                                        $0.title = "Add New Recipe"
                                    }.cellUpdate { cell, row in
                                        cell.backgroundColor = .secondarySystemGroupedBackground
                                        cell.textLabel?.textAlignment = .left
                                        
                                    }
                                }
                                $0.multivaluedRowToInsertAt = { index in
                                    self.recipeID = ""
                                    self.openRecipe()
                                    return LabelRow("label"){ row in
                                        
                                    }
                                }
                                
        }
        if let recipes = self.grocerylist.recipes {
            for (ID, title) in recipes {
                var mvs = (form.sectionBy(tag: "recipefields") as! MultivaluedSection)
                mvs.insert(ButtonRow() { row in
                    row.cell.backgroundColor = .secondarySystemGroupedBackground
                    row.cell.textLabel?.textAlignment = .left
                    row.cell.textLabel?.textColor = .label
                    row.title = title
                }.onCellSelection({ cell, row in
                    self.recipeID = ID
                    self.recipeIndex = row.indexPath!.row
                    self.openRecipe()
                }).cellUpdate { cell, row in
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                    cell.textLabel?.textAlignment = .left
                }, at: mvs.count - 1)
            }
        }
        
        form +++
            MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                               header: "Ingredient(s)") {
                                $0.tag = "ingredientfields"
                                $0.addButtonProvider = { section in
                                    return ButtonRow(){
                                        $0.cell.backgroundColor = .secondarySystemGroupedBackground
                                        $0.title = "Add New Ingredient"
                                    }.cellUpdate { cell, row in
                                        cell.backgroundColor = .secondarySystemGroupedBackground
                                        cell.textLabel?.textAlignment = .left
                                    }
                                }
                                $0.multivaluedRowToInsertAt = { index in
                                    self.ingredientIndex = -1
                                    self.openIngredient()
                                    return LabelRow(){ row in
                                        
                                    }
                                }
        }
        
        addIngredients()
    }
    
    fileprivate func addIngredients() {
        if !productContainer.isEmpty {
            for index in 0...productContainer.count - 1 {
                if let product = productContainer[index].complexIngredient {
                    if product.amount ?? 0.0 < 0.0 {
                        if let index = self.grocerylist.ingredients?.firstIndex(of: product) {
                            self.grocerylist.ingredients?.remove(at: index)
                            continue
                        }
                    }
                    var aisle = product.aisle?.capitalized ?? ""
                    aisle = aisle.replacingOccurrences(of: ";", with: "; ")
                    if form.sectionBy(tag: "\(aisle)") != nil {
                        var section = form.sectionBy(tag: "\(aisle)") as? MultivaluedSection
                        section!.insert(SplitRow<ButtonRow, CheckRow>("\(product.name!)"){
                            $0.rowLeftPercentage = 0.75
                            $0.rowLeft = ButtonRow(){ row in
                                row.cell.backgroundColor = .secondarySystemGroupedBackground
                                row.cell.textLabel?.textAlignment = .left
                                row.cell.textLabel?.textColor = .label
                                row.cell.textLabel?.numberOfLines = 0
                                row.title = "\(product.amount ?? 0.0) \(product.unit ?? "") of \(product.name?.capitalized ?? "")"
                            }.onCellSelection({ cell, row in
                                self.ingredientIndex = index
                                self.openIngredient()
                            }).cellUpdate { cell, row in
                                cell.backgroundColor = .secondarySystemGroupedBackground
                                cell.textLabel?.textColor = .label
                                cell.textLabel?.textAlignment = .left
                                cell.textLabel?.numberOfLines = 0
                            }
                            
                            $0.rowRight = CheckRow() {
                                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                                $0.cell.tintColor = FalconPalette.defaultBlue
                                $0.value = product.bool ?? false
                                $0.cell.accessoryType = .checkmark
                                $0.cell.tintAdjustmentMode = .dimmed
                            }.cellUpdate { cell, row in
                                cell.backgroundColor = .secondarySystemGroupedBackground
                                cell.tintColor = FalconPalette.defaultBlue
                                cell.accessoryType = .checkmark
                                if row.value == false {
                                    cell.tintAdjustmentMode = .dimmed
                                } else {
                                    cell.tintAdjustmentMode = .automatic
                                }
                            }.onCellSelection({ (cell, row) in
                                if let index = self.grocerylist.ingredients?.firstIndex(of: product) {
                                    self.grocerylist.ingredients![index].bool = row.value
                                }
                            })
                        }.cellUpdate { cell, row in
                            cell.backgroundColor = .secondarySystemGroupedBackground
                        } , at: section!.count - 1)
                    } else {
                        var aisle = product.aisle?.capitalized ?? ""
                        aisle = aisle.replacingOccurrences(of: ";", with: "; ")
                        
                        form +++
                            MultivaluedSection(multivaluedOptions: [.Delete],
                                               header: "\(aisle)") {
                                                $0.tag = "\(aisle)"
                        }
                        
                        var section = form.sectionBy(tag: "\(aisle)") as? MultivaluedSection
                        section!.insert(SplitRow<ButtonRow, CheckRow>("\(product.name!)"){
                            $0.rowLeftPercentage = 0.75
                            $0.rowLeft = ButtonRow(){ row in
                                row.cell.backgroundColor = .secondarySystemGroupedBackground
                                row.cell.textLabel?.textAlignment = .left
                                row.cell.textLabel?.textColor = .label
                                row.cell.textLabel?.numberOfLines = 0
                                row.title = "\(product.amount ?? 0.0) \(product.unit ?? "") of \(product.name?.capitalized ?? "")"
                            }.onCellSelection({ cell, row in
                                self.ingredientIndex = index
                                self.openIngredient()
                            }).cellUpdate { cell, row in
                                cell.backgroundColor = .secondarySystemGroupedBackground
                                cell.textLabel?.textColor = .label
                                cell.textLabel?.textAlignment = .left
                                cell.textLabel?.numberOfLines = 0
                            }
                            
                            $0.rowRight = CheckRow() {
                                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                                $0.cell.tintColor = FalconPalette.defaultBlue
                                $0.value = product.bool ?? false
                                $0.cell.accessoryType = .checkmark
                                $0.cell.tintAdjustmentMode = .dimmed
                            }.cellUpdate { cell, row in
                                cell.backgroundColor = .secondarySystemGroupedBackground
                                cell.tintColor = FalconPalette.defaultBlue
                                cell.accessoryType = .checkmark
                                if row.value == false {
                                    cell.tintAdjustmentMode = .dimmed
                                } else {
                                    cell.tintAdjustmentMode = .automatic
                                }
                            }.onCellSelection({ (cell, row) in
                                if let index = self.grocerylist.ingredients?.firstIndex(of: product) {
                                    self.grocerylist.ingredients![index].bool = row.value
                                }
                            })
                        }.cellUpdate { cell, row in
                            cell.backgroundColor = .secondarySystemGroupedBackground
                        } , at: 0)
                    }
                } else if let product = productContainer[index].groceryProduct {
                    var aisle = product.aisle?.capitalized ?? ""
                    aisle = aisle.replacingOccurrences(of: ";", with: "; ")
                    if form.sectionBy(tag: "\(aisle)") != nil {
                        var section = form.sectionBy(tag: "\(aisle)") as? MultivaluedSection
                        section!.insert(SplitRow<ButtonRow, CheckRow>("\(product.title)"){
                            $0.rowLeftPercentage = 0.75
                            $0.rowLeft = ButtonRow(){ row in
                                row.cell.backgroundColor = .secondarySystemGroupedBackground
                                row.cell.textLabel?.textAlignment = .left
                                row.cell.textLabel?.textColor = .label
                                row.cell.textLabel?.numberOfLines = 0
                                row.title = "\(product.amount ?? 0) \(product.title.capitalized)"
                            }.onCellSelection({ cell, row in
                                self.ingredientIndex = index
                                self.openIngredient()
                            }).cellUpdate { cell, row in
                                cell.backgroundColor = .secondarySystemGroupedBackground
                                cell.textLabel?.textColor = .label
                                cell.textLabel?.textAlignment = .left
                                cell.textLabel?.numberOfLines = 0
                            }
                            
                            $0.rowRight = CheckRow() {
                                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                                $0.cell.tintColor = FalconPalette.defaultBlue
                                $0.value = product.bool ?? false
                                $0.cell.accessoryType = .checkmark
                                $0.cell.tintAdjustmentMode = .dimmed
                            }.cellUpdate { cell, row in
                                cell.backgroundColor = .secondarySystemGroupedBackground
                                cell.tintColor = FalconPalette.defaultBlue
                                cell.accessoryType = .checkmark
                                if row.value == false {
                                    cell.tintAdjustmentMode = .dimmed
                                } else {
                                    cell.tintAdjustmentMode = .automatic
                                }
                            }.onCellSelection({ (cell, row) in
                                if let index = self.grocerylist.groceryProducts?.firstIndex(of: product) {
                                    self.grocerylist.groceryProducts![index].bool = row.value
                                }
                            })
                        }.cellUpdate { cell, row in
                            cell.backgroundColor = .secondarySystemGroupedBackground
                        } , at: section!.count - 1)
                    } else {
                        var aisle = product.aisle?.capitalized ?? ""
                        aisle = aisle.replacingOccurrences(of: ";", with: "; ")
                        
                        form +++
                            MultivaluedSection(multivaluedOptions: [.Delete],
                                               header: "\(aisle)") {
                                                $0.tag = "\(aisle)"
                        }
                        
                        var section = form.sectionBy(tag: "\(aisle)") as? MultivaluedSection
                        section!.insert(SplitRow<ButtonRow, CheckRow>("\(product.title)"){
                            $0.rowLeftPercentage = 0.75
                            $0.rowLeft = ButtonRow(){ row in
                                row.cell.backgroundColor = .secondarySystemGroupedBackground
                                row.cell.textLabel?.textAlignment = .left
                                row.cell.textLabel?.textColor = .label
                                row.cell.textLabel?.numberOfLines = 0
                                row.title = "\(product.amount ?? 0) \(product.title.capitalized)"
                            }.onCellSelection({ cell, row in
                                self.ingredientIndex = index
                                self.openIngredient()
                            }).cellUpdate { cell, row in
                                cell.backgroundColor = .secondarySystemGroupedBackground
                                cell.textLabel?.textColor = .label
                                cell.textLabel?.textAlignment = .left
                                cell.textLabel?.numberOfLines = 0
                            }
                            
                            $0.rowRight = CheckRow() {
                                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                                $0.cell.tintColor = FalconPalette.defaultBlue
                                $0.value = product.bool ?? false
                                $0.cell.accessoryType = .checkmark
                                $0.cell.tintAdjustmentMode = .dimmed
                            }.cellUpdate { cell, row in
                                cell.backgroundColor = .secondarySystemGroupedBackground
                                cell.tintColor = FalconPalette.defaultBlue
                                cell.accessoryType = .checkmark
                                if row.value == false {
                                    cell.tintAdjustmentMode = .dimmed
                                } else {
                                    cell.tintAdjustmentMode = .automatic
                                }
                            }.onCellSelection({ (cell, row) in
                                if let index = self.grocerylist.groceryProducts?.firstIndex(of: product) {
                                    self.grocerylist.groceryProducts![index].bool = row.value
                                }
                            })
                        }.cellUpdate { cell, row in
                            cell.backgroundColor = .secondarySystemGroupedBackground
                        } , at: 0)
                    }
                }
            }
        }
    }
    
    fileprivate func openIngredient() {
        if ingredientIndex == -1 {
            let destination = IngredientSearchViewController()
            destination.delegate = self
            self.navigationController?.pushViewController(destination, animated: true)
        } else if let items = self.grocerylist.ingredients, items.indices.contains(ingredientIndex) {
            let destination = IngredientDetailViewController()
            destination.delegate = self
            destination.ingredient = items[ingredientIndex]
            destination.active = true
            self.navigationController?.pushViewController(destination, animated: true)
            
        }
    }
    
    fileprivate func openRecipe() {
        
    }
    
    override func rowsHaveBeenRemoved(_ rows: [BaseRow], at indexes: [IndexPath]) {
        super.rowsHaveBeenRemoved(rows, at: indexes)
        let rowNumber : Int = indexes.first!.row
        let rowType = rows[0].self
        
        DispatchQueue.main.async { [weak self] in
            if rowType is ButtonRow {
                if let recipes = self!.grocerylist.recipes, rows[0].title != nil {
                    let id = Array<String>(recipes.keys)[rowNumber]
                    self!.lookupRecipe(recipeID: Int(id)!, add: false)
                }
            } else if rowType is SplitRow<ButtonRow, CheckRow>, !self!.productContainer.isEmpty, let rowTag = rows[0].tag {
                if let index = self!.productContainer.firstIndex(where: {$0.title == rowTag}) {
                    if let product = self!.productContainer[index].complexIngredient {
                        if let index = self!.grocerylist.ingredients!.firstIndex(where: {$0 == product}) {
                            self!.grocerylist.ingredients!.remove(at: index)
                        }
                    } else if let product = self!.productContainer[index].groceryProduct {
                        if let index = self!.grocerylist.groceryProducts!.firstIndex(where: {$0 == product}) {
                            self!.grocerylist.ingredients!.remove(at: index)
                        }
                    }
                    self!.productContainer.remove(at: index)
                    if self!.productContainer.count == 1 {
                        if let ingredientSection = self!.form.sectionBy(tag: "ingredientfields") as? MultivaluedSection {
                            if self!.form.allSections.count > 3 {
                                for _ in 0...self!.form.allSections.count - 2 - ingredientSection.index! {
                                    self!.form.remove(at: ingredientSection.index! + 1)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    fileprivate func lookupRecipe(recipeID: Int, add: Bool) {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWithClose(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        Service.shared.fetchRecipesInfo(id: recipeID) { (search, err) in
            dispatchGroup.leave()
            dispatchGroup.notify(queue: .main) {
                if let recipe = search {
                    if add {
                        self.updateGrocerylist(recipe: recipe, add: true)
                    } else {
                        self.updateGrocerylist(recipe: recipe, add: false)
                    }
                }
            }
        }
    }
    
    fileprivate func updateGrocerylist(recipe: Recipe, add: Bool) {
        print("updating grocery list \(recipe.title) \(add)")
        if self.grocerylist != nil, self.grocerylist.ingredients != nil, let recipeIngredients = recipe.extendedIngredients {
            var glIngredients = self.grocerylist.ingredients!
            if let grocerylistServings = self.grocerylist.servings?["\(recipe.id)"], grocerylistServings != recipe.servings {
                self.grocerylist.servings!["\(recipe.id)"] = recipe.servings
                for recipeIngredient in recipeIngredients {
                    if let index = glIngredients.firstIndex(where: {$0 == recipeIngredient}) {
                        glIngredients[index].recipe![recipe.title] = recipeIngredient.amount ?? 0.0
                        if glIngredients[index].amount != nil && recipeIngredient.amount != nil  {
                            glIngredients[index].amount! +=  recipeIngredient.amount! - recipeIngredient.amount! * Double(grocerylistServings) / Double(recipe.servings!)
                        }
                    }
                }
            } else if let recipes = self.grocerylist.recipes, recipes["\(recipe.id)"] != nil && add {
                print("recipe exists")
                return
            } else {
                print("adding recipe")
                if add {
                    if self.grocerylist.recipes != nil {
                        self.grocerylist.recipes!["\(recipe.id)"] = recipe.title
                        self.grocerylist.servings!["\(recipe.id)"] = recipe.servings
                    } else {
                        self.grocerylist.recipes = ["\(recipe.id)": recipe.title]
                        self.grocerylist.servings = ["\(recipe.id)": recipe.servings!]
                    }
                } else {
                    self.grocerylist.recipes!["\(recipe.id)"] = nil
                    self.grocerylist.servings!["\(recipe.id)"] = nil
                }
                for recipeIngredient in recipeIngredients {
                    if let index = glIngredients.firstIndex(where: {$0 == recipeIngredient}) {
                        if add {
                            glIngredients[index].recipe![recipe.title] = recipeIngredient.amount ?? 0.0
                            if glIngredients[index].amount != nil {
                                glIngredients[index].amount! += recipeIngredient.amount ?? 0.0
                            }
                        } else {
                            if glIngredients[index].amount != nil {
                                glIngredients[index].amount! -= recipeIngredient.amount ?? 0.0
                                if glIngredients[index].amount! == 0 || glIngredients[index].amount! < 0 {
                                    print("remove ingredient name \(glIngredients[index].name ?? "no name")")
                                    glIngredients.remove(at: index)
                                    continue
                                } else {
                                    glIngredients[index].recipe![recipe.title] = nil
                                }
                            }
                        }
                    } else {
                        if add {
                            var recIngredient = recipeIngredient
                            recIngredient.recipe = [recipe.title: recIngredient.amount ?? 0.0]
                            glIngredients.append(recIngredient)
                        }
                    }
                }
            }
            self.grocerylist.ingredients = glIngredients
        } else if let recipeIngredients = recipe.extendedIngredients, add {
            self.grocerylist.recipes = ["\(recipe.id)": recipe.title]
            self.grocerylist.servings = ["\(recipe.id)": recipe.servings!]
            self.grocerylist.ingredients = recipeIngredients
            for index in 0...recipeIngredients.count - 1 {
                self.grocerylist.ingredients![index].recipe = [recipe.title: self.grocerylist.ingredients![index].amount ?? 0.0]
                
            }
        }
        
        let createGrocerylist = GrocerylistActions(grocerylist: self.grocerylist, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
        createGrocerylist.createNewGrocerylist()
        
        if let ingredientSection = form.sectionBy(tag: "ingredientfields") as? MultivaluedSection {
            if form.allSections.count > 3 {
                for _ in 0...form.allSections.count - 2 - ingredientSection.index! {
                    form.remove(at: ingredientSection.index! + 1)
                }
            }
            addIngredients()
        } else {
            form.removeAll()
            initializeForm()
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
        destination.ownerID = grocerylist.admin
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
    
    func getSelectedFalconUsers(forGrocerylist grocerylist: Grocerylist, completion: @escaping ([User])->()) {
        guard let participantsIDs = grocerylist.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        var selectedFalconUsers = [User]()
        let group = DispatchGroup()
        for id in participantsIDs {
            // Only if the current user is created this activity
            if grocerylist.admin == currentUserID && id == currentUserID {
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
        let badgeRef = Database.database().reference().child(userGrocerylistsEntity).child(currentUserID).child(grocerylist.ID!).child("badge")
        badgeRef.runTransactionBlock({ (mutableData) -> TransactionResult in
            var value = mutableData.value as? Int
            value = 0
            mutableData.value = value!
            return TransactionResult.success(withValue: mutableData)
        })
    }
}

extension GrocerylistViewController: UpdateFoodProductContainerDelegate {
    func updateFoodProductContainer(foodProductContainer: FoodProductContainer?, close: Bool?) {
        if let foodProductContainer = foodProductContainer, let ingredient = foodProductContainer.complexIngredient {
            if ingredientIndex == -1 {
                if let mvs = self.form.sectionBy(tag: "ingredientfields") as? MultivaluedSection {
                    print("removing row")
                    mvs.remove(at: 0)
                }
            }
            if ingredient.name == "IngredientName" {
                print("no ingredient")
                return
            }
            if !productContainer.isEmpty, let items = self.grocerylist.ingredients {
                if productContainer.indices.contains(ingredientIndex) {
                    print("active ingredient")
                    if let index = self.grocerylist.ingredients?.firstIndex(of: ingredient) {
                        self.grocerylist.ingredients![index] = ingredient
                    }
                    if let row: SplitRow<ButtonRow, CheckRow> = form.rowBy(tag: "\(ingredient.name!)") {
                        row.rowLeft!.title = "\(ingredient.amount ?? 0.0) \(ingredient.unit ?? "") of \(ingredient.name?.capitalized ?? "")"
                        row.updateCell()
                        return
                    }
                } else if let index = items.firstIndex(where: {$0 == ingredient}) {
                    print("ingredient exists")
                    if items[index].amount != nil {
                        self.grocerylist.ingredients![index].amount! += ingredient.amount ?? 0.0
                    }
                } else {
                    print("appending ingredient")
                    self.grocerylist.ingredients!.append(ingredient)
                    self.productContainer.append(FoodProductContainer(groceryProduct: nil, menuProduct: nil, recipeProduct: nil, complexIngredient: ingredient, basicIngredient: nil))
                }
                
                let createGrocerylist = GrocerylistActions(grocerylist: self.grocerylist, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                createGrocerylist.createNewGrocerylist()
                
                if let ingredientSection = form.sectionBy(tag: "ingredientfields") as? MultivaluedSection {
                    if form.allSections.count > 3 {
                        for _ in 0...form.allSections.count - 2 - ingredientSection.index! {
                            form.remove(at: ingredientSection.index! + 1)
                        }
                    }
                    addIngredients()
                }
            } else if self.grocerylist.ingredients == nil {
                self.grocerylist.ingredients = [ingredient]
                self.productContainer.append(FoodProductContainer(groceryProduct: nil, menuProduct: nil, recipeProduct: nil, complexIngredient: ingredient, basicIngredient: nil))
                
                let createGrocerylist = GrocerylistActions(grocerylist: self.grocerylist, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                createGrocerylist.createNewGrocerylist()
                
                addIngredients()
            }
        } else if let foodProductContainer = foodProductContainer, let groceryProduct = foodProductContainer.groceryProduct {
            if ingredientIndex == -1 {
                if let mvs = self.form.sectionBy(tag: "ingredientfields") as? MultivaluedSection {
                    print("removing row")
                    mvs.remove(at: 0)
                }
            }
            if groceryProduct.title == "GroceryProductName" {
                print("no ingredient")
                return
            }
            if !productContainer.isEmpty, let items = self.grocerylist.groceryProducts {
                if productContainer.indices.contains(ingredientIndex) {
                    print("active ingredient")
                    if let index = self.grocerylist.groceryProducts?.firstIndex(of: groceryProduct) {
                        self.grocerylist.groceryProducts![index] = groceryProduct
                    }
                    if let row: SplitRow<ButtonRow, CheckRow> = form.rowBy(tag: "\(groceryProduct.title)") {
                        row.rowLeft!.title = "\(groceryProduct.amount ?? 0) \(groceryProduct.title.capitalized)"
                        row.updateCell()
                        return
                    }
                } else if let _ = items.firstIndex(where: {$0 == groceryProduct}) {
                    print("ingredient exists")
                } else {
                    print("appending ingredient")
                    self.grocerylist.groceryProducts!.append(groceryProduct)
                    self.productContainer.append(FoodProductContainer(groceryProduct: groceryProduct, menuProduct: nil, recipeProduct: nil, complexIngredient: nil, basicIngredient: nil))
                }
                
                let createGrocerylist = GrocerylistActions(grocerylist: self.grocerylist, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                createGrocerylist.createNewGrocerylist()
                
                if let ingredientSection = form.sectionBy(tag: "ingredientfields") as? MultivaluedSection {
                    if form.allSections.count > 3 {
                        for _ in 0...form.allSections.count - 2 - ingredientSection.index! {
                            form.remove(at: ingredientSection.index! + 1)
                        }
                    }
                    addIngredients()
                }
            } else if self.grocerylist.groceryProducts == nil {
                self.grocerylist.groceryProducts = [groceryProduct]
                self.productContainer.append(FoodProductContainer(groceryProduct: groceryProduct, menuProduct: nil, recipeProduct: nil, complexIngredient: nil, basicIngredient: nil))
                
                let createGrocerylist = GrocerylistActions(grocerylist: self.grocerylist, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                createGrocerylist.createNewGrocerylist()
                
                addIngredients()
            }
        }
    }
}

extension GrocerylistViewController: UpdateInvitees {
    func updateInvitees(selectedFalconUsers: [User]) {
        if let inviteesRow: LabelRow = form.rowBy(tag: "Participants") {
            self.selectedFalconUsers = selectedFalconUsers
            inviteesRow.value = String(selectedFalconUsers.count + 1)
            inviteesRow.updateCell()
            
            if active {
                showActivityIndicator()
                let createGrocerylist = GrocerylistActions(grocerylist: grocerylist, active: active, selectedFalconUsers: selectedFalconUsers)
                createGrocerylist.updateGrocerylistParticipants()
                hideActivityIndicator()
                
            }
            
        }
    }
}

extension GrocerylistViewController: ChooseActivityDelegate {
    func chosenActivity(mergeActivity: Activity) {
        let groupActivityReference = Database.database().reference().child(activitiesEntity).child(mergeActivity.activityID!).child(messageMetaDataFirebaseFolder)
        if let activityGrocerylistID = mergeActivity.grocerylistID {
            let grocerylistDataReference = Database.database().reference().child(grocerylistsEntity).child(activityGrocerylistID)
            grocerylistDataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), let grocerylistSnapshotValue = snapshot.value {
                    if let activityGrocerylist = try? FirebaseDecoder().decode(Grocerylist.self, from: grocerylistSnapshotValue) {
                        if let recipes = self.grocerylist.recipes {
                            for recipe in recipes {
                                if let activityRecipes = activityGrocerylist.recipes {
                                    // do not double count recipes
                                    if let _ = activityRecipes.firstIndex(where: {$0 == recipe}) {
                                        continue
                                    } else {
                                        if activityGrocerylist.recipes != nil {
                                            activityGrocerylist.recipes!["\(recipe.key)"] = recipe.value
                                            activityGrocerylist.servings!["\(recipe.key)"] = self.grocerylist.servings!["\(recipe.key)"]
                                        } else {
                                            activityGrocerylist.recipes = ["\(recipe.key)": recipe.value]
                                            activityGrocerylist.servings = ["\(recipe.key)": self.grocerylist.servings!["\(recipe.key)"]!]
                                        }
                                        for ingredient in self.grocerylist.ingredients! {
                                            // if ingredient does not belong to recipe, move to next
                                            if ingredient.recipe![recipe.value] == nil {
                                                continue
                                            }
                                            if let index = activityGrocerylist.ingredients!.firstIndex(where: {$0 == ingredient}) {
                                                // if activity GL ingredient already includes recipe
                                                if activityGrocerylist.ingredients![index].recipe![recipe.value] != nil {
                                                    continue
                                                }
                                                activityGrocerylist.ingredients![index].recipe![recipe.value] = ingredient.recipe![recipe.value]
                                                if activityGrocerylist.ingredients![index].amount != nil {
                                                    activityGrocerylist.ingredients![index].amount! += ingredient.recipe![recipe.value] ?? 0.0
                                                }
                                            } else {
                                                activityGrocerylist.ingredients!.append(ingredient)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        if let ingredients = self.grocerylist.ingredients {
                            for ingredient in ingredients {
                                if let recipe = ingredient.recipe, recipe["No Recipe"] == nil {
                                    continue
                                } else if let recipe = ingredient.recipe, recipe.count > 1 {
                                    if let index = activityGrocerylist.ingredients!.firstIndex(where: {$0 == ingredient}) {
                                        // if activity GL ingredient already includes recipe
                                        if activityGrocerylist.ingredients![index].recipe!["No Recipe"] != nil {
                                            continue
                                        }
                                        activityGrocerylist.ingredients![index].recipe!["No Recipe"] = ingredient.recipe!["No Recipe"]
                                        if activityGrocerylist.ingredients![index].amount != nil {
                                            activityGrocerylist.ingredients![index].amount! += ingredient.recipe!["No Recipe"] ?? 0.0
                                        }
                                    } else {
                                        activityGrocerylist.ingredients!.append(ingredient)
                                    }
                                } else if let index = activityGrocerylist.ingredients!.firstIndex(where: {$0 == ingredient}) {
                                    if activityGrocerylist.ingredients![index].amount != nil {
                                        activityGrocerylist.ingredients![index].amount! += ingredient.amount ?? 0.0
                                    }
                                } else {
                                    activityGrocerylist.ingredients!.append(ingredient)
                                }
                            }
                        }
                        activityGrocerylist.lastModifiedDate = Date()
                        do {
                            let value = try FirebaseEncoder().encode(activityGrocerylist)
                            grocerylistDataReference.setValue(value)
                        } catch let error {
                            print(error)
                        }
                    }
                }
            })
            if !connectedToAct {
                let dispatchGroup = DispatchGroup()
                dispatchGroup.enter()
                if let grocerylist = grocerylist {
                    let deleteGrocerylist = GrocerylistActions(grocerylist: grocerylist, active: true, selectedFalconUsers: self.selectedFalconUsers)
                    deleteGrocerylist.deleteGrocerylist()
                    dispatchGroup.leave()
                    self.addedToActAlert()
                    self.dismiss(animated: true, completion: nil)
                }
            } else {
                self.addedToActAlert()
                self.dismiss(animated: true, completion: nil)
            }
        } else {
            if connectedToAct {
                if let currentUserID = Auth.auth().currentUser?.uid {
                    let newGrocerylistID = Database.database().reference().child(userGrocerylistsEntity).child(currentUserID).childByAutoId().key ?? ""
                    groupActivityReference.updateChildValues(["grocerylistID": newGrocerylistID as AnyObject])
                    
                    let newGrocerylist = self.grocerylist.copy() as! Grocerylist
                    newGrocerylist.ID = newGrocerylistID
                    newGrocerylist.admin = mergeActivity.admin
                    newGrocerylist.participantsIDs = mergeActivity.participantsIDs
                    newGrocerylist.conversationID = mergeActivity.conversationID
                    newGrocerylist.activityID = mergeActivity.activityID
                    
                    self.getSelectedFalconUsers(forGrocerylist: grocerylist) { (participants) in
                        self.showActivityIndicator()
                        let createGrocerylist = GrocerylistActions(grocerylist: self.grocerylist, active: self.active, selectedFalconUsers: participants)
                        createGrocerylist.createNewGrocerylist()
                        self.hideActivityIndicator()
                        self.addedToActAlert()
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            } else {
                groupActivityReference.updateChildValues(["grocerylistID": self.grocerylist.ID! as AnyObject])
                //remove participants and admin when adding
                grocerylist.participantsIDs = mergeActivity.participantsIDs
                grocerylist.admin = mergeActivity.admin
                grocerylist.activityID = mergeActivity.activityID
                grocerylist.conversationID = mergeActivity.conversationID
                
                self.getSelectedFalconUsers(forGrocerylist: grocerylist) { (participants) in
                    self.showActivityIndicator()
                    let createGrocerylist = GrocerylistActions(grocerylist: self.grocerylist, active: self.active, selectedFalconUsers: participants)
                    createGrocerylist.createNewGrocerylist()
                    self.hideActivityIndicator()
                    self.addedToActAlert()
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
}

extension GrocerylistViewController: ChooseChatDelegate {
    func chosenChat(chatID: String, activityID: String?, grocerylistID: String?, checklistID: String?, packinglistID: String?, activitylistID: String?) {
        if let grocerylistID = grocerylistID {
            let updatedConversationID = ["conversationID": chatID as AnyObject]
            Database.database().reference().child(grocerylistsEntity).child(grocerylistID).updateChildValues(updatedConversationID)
            if let conversation = conversations.first(where: {$0.chatID == chatID}) {
                if conversation.grocerylists != nil {
                    var grocerylists = conversation.grocerylists!
                    grocerylists.append(grocerylistID)
                    let updatedGrocerylists = [grocerylistsEntity: grocerylists as AnyObject]
                    Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedGrocerylists)
                } else {
                    let updatedGrocerylists = [grocerylistsEntity: [grocerylistID] as AnyObject]
                    Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedGrocerylists)
                }
                if let activityID = activityID {
                    Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder).updateChildValues(updatedConversationID)
                    if conversation.activities != nil {
                        var activities = conversation.activities!
                        activities.append(activityID)
                        let updatedActivities = [activitiesEntity: activities as AnyObject]
                        Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
                    } else {
                        let updatedActivities = [activitiesEntity: [activityID] as AnyObject]
                        Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
                    }
                    Database.database().reference().child(activitiesEntity).child(activityID).updateChildValues(updatedConversationID)
                }
                self.connectedToChatAlert()
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}

extension GrocerylistViewController: MessagesDelegate {
    
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

extension GrocerylistViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == FalconPalette.defaultBlue {
            textView.text = nil
            textView.textColor = .label
        }
        
        
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Description"
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
    }
    
}
