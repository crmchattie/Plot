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

protocol UpdateGrocerylistDelegate: class {
    func updateGrocerylist(grocerylist: Grocerylist)
}

class GrocerylistViewController: FormViewController {
    weak var delegate : UpdateGrocerylistDelegate?
          
    var grocerylist: Grocerylist!
    
    var users = [User]()
    var filteredUsers = [User]()
    var selectedFalconUsers = [User]()
    
    var activities = [Activity]()
    var conversations = [Conversation]()
    
    var userNames : [String] = []
    var userNamesString: String = ""

    fileprivate var active: Bool = false
    fileprivate var movingBackwards: Bool = true
    var connectedToAct = true
    var comingFromLists = false
    
    fileprivate var ingredientIndex: Int = 0
    fileprivate var recipeIndex: Int = 0
              
    override func viewDidLoad() {
        super.viewDidLoad()
              
        configureTableView()
      
        if grocerylist != nil {
            active = true
            self.navigationItem.rightBarButtonItem?.isEnabled = true
            if !connectedToAct {
                connectedToAct = false
                var participantCount = self.selectedFalconUsers.count
                
                // If user is creating this activity (admin)
                if grocerylist.admin == nil || grocerylist.admin == Auth.auth().currentUser?.uid {
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
            }
        } else {
            grocerylist = Grocerylist(dictionary: ["name" : "GroceryListName" as AnyObject])
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }
        
        setupRightBarButton()
        
        initializeForm()
      
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.movingBackwards {
            delegate?.updateGrocerylist(grocerylist: grocerylist)
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
        navigationItem.title = "Grocery List"
    }
    
    func setupRightBarButton() {
        if !comingFromLists {
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
                let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(close))
                let dotsBarButton = UIBarButtonItem(image: dotsImage, style: .plain, target: self, action: #selector(goToExtras))
                navigationItem.rightBarButtonItems = [plusBarButton, dotsBarButton]
            }
        }
    }

    @objc fileprivate func close() {
        movingBackwards = false
        delegate?.updateGrocerylist(grocerylist: grocerylist)
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func goToExtras() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if connectedToAct {
            if grocerylist.activity?.conversationID == nil {
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
        
        alert.addAction(UIAlertAction(title: "Share Grocery List", style: .default, handler: { (_) in
            print("User click Edit button")
            self.share()
        }))

        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))

        self.present(alert, animated: true, completion: {
            print("completion block")
        })
        print("shareButtonTapped")
        
    }
        
        @objc func goToChat() {
    //        if checklist.conversationID != nil {
    //            if let convo = conversations.first(where: {$0.chatID == activity!.conversationID}) {
    //                self.chatLogController = ChatLogController(collectionViewLayout: AutoSizingCollectionViewFlowLayout())
    //                self.messagesFetcher = MessagesFetcher()
    //                self.messagesFetcher?.delegate = self
    //                self.messagesFetcher?.loadMessagesData(for: convo)
    //            }
    //        } else {
    //            let destination = ChooseChatTableViewController()
    //            let navController = UINavigationController(rootViewController: destination)
    //            destination.delegate = self
    //            destination.activity = activity
    //            destination.conversations = conversations
    //            destination.pinnedConversations = conversations
    //            destination.filteredConversations = conversations
    //            destination.filteredPinnedConversations = conversations
    //            present(navController, animated: true, completion: nil)
    //        }
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
    //                alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { (_) in
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
            $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
            $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
            $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
            $0.placeholder = $0.tag
            if active, let grocerylist = grocerylist {
                $0.value = grocerylist.name
            } else {
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
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
            }
        
        if !connectedToAct {
            form.last!
            <<< ButtonRow("Participants") { row in
            row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
            row.cell.textLabel?.textAlignment = .left
            row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            row.cell.accessoryType = .disclosureIndicator
            row.title = row.tag
            if self.selectedFalconUsers.count > 0 {
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
        }
        
        form +++
        MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                           header: "Recipe(s)",
                           footer: "Add a recipe") {
            $0.tag = "recipefields"
            $0.addButtonProvider = { section in
                return ButtonRow(){
                    $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    $0.title = "Add New Recipe"
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        cell.textLabel?.textAlignment = .left
                        
                }
            }
            $0.multivaluedRowToInsertAt = { index in
                self.recipeIndex = index
                self.openRecipe()
                return ButtonRow() { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                row.cell.textLabel?.textAlignment = .left
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                }.onCellSelection({ _,_ in
                    self.recipeIndex = index
                    self.openRecipe()
                }).cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.textLabel?.textAlignment = .left
                }
            }
            
            }
        if let recipes = self.grocerylist.recipes {
            for (_, title) in recipes {
                var mvs = (form.sectionBy(tag: "recipefields") as! MultivaluedSection)
                mvs.insert(ButtonRow() { row in
                    row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    row.cell.textLabel?.textAlignment = .left
                    row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    row.title = title
                    self.recipeIndex = mvs.count - 1
                    }.onCellSelection({ cell, row in
                        self.recipeIndex = row.indexPath!.row
                        self.openRecipe()
                    }).cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
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
                            $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                            $0.title = "Add New Ingredient"
                            }.cellUpdate { cell, row in
                                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
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
        if let items = self.grocerylist.ingredients {
            for index in 0...items.count - 1 {
                var aisle = items[index].aisle!.capitalized
                aisle = aisle.replacingOccurrences(of: ";", with: "; ")
                if form.sectionBy(tag: "\(aisle)") != nil {
                    var section = form.sectionBy(tag: "\(aisle)") as? MultivaluedSection
                    section!.insert(SplitRow<ButtonRow, CheckRow>("\(items[index].name!)"){
                    $0.rowLeftPercentage = 0.75
                    $0.rowLeft = ButtonRow(){ row in
                        row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        row.cell.textLabel?.textAlignment = .left
                        row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        row.cell.textLabel?.numberOfLines = 0
                        row.title = "\(items[index].amount ?? 0.0) \(items[index].unit ?? "") of \(items[index].name?.capitalized ?? "")"
                        }.onCellSelection({ cell, row in
                            self.ingredientIndex = index
                            self.openIngredient()
                        }).cellUpdate { cell, row in
                            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                            cell.textLabel?.textAlignment = .left
                            cell.textLabel?.numberOfLines = 0
                        }
                    
                    $0.rowRight = CheckRow() {
                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        $0.cell.tintColor = FalconPalette.defaultBlue
                        $0.value = items[index].bool ?? false
                        $0.cell.accessoryType = .checkmark
                        $0.cell.tintAdjustmentMode = .dimmed
                        }.cellUpdate { cell, row in
                            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                            cell.tintColor = FalconPalette.defaultBlue
                            if row.value == false {
                                cell.accessoryType = .checkmark
                                cell.tintAdjustmentMode = .dimmed
                            } else {
                                cell.tintAdjustmentMode = .automatic
                            }
                        }.onCellSelection({ (cell, row) in
                            self.grocerylist.ingredients![index].bool = row.value
                        })
                        }.cellUpdate { cell, row in
                            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        } , at: section!.count - 1)
                } else {
                    var aisle = items[index].aisle!.capitalized
                    aisle = aisle.replacingOccurrences(of: ";", with: "; ")
                    
                    form +++
                    MultivaluedSection(multivaluedOptions: [.Delete],
                        header: "\(aisle)") {
                        $0.tag = "\(aisle)"
                    }
                    
                    var section = form.sectionBy(tag: "\(aisle)") as? MultivaluedSection
                    section!.insert(SplitRow<ButtonRow, CheckRow>("\(items[index].name!)"){
                    $0.rowLeftPercentage = 0.75
                    $0.rowLeft = ButtonRow(){ row in
                        row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        row.cell.textLabel?.textAlignment = .left
                        row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        row.cell.textLabel?.numberOfLines = 0
                        row.title = "\(items[index].amount ?? 0.0) \(items[index].unit ?? "") of \(items[index].name?.capitalized ?? "")"
                        }.onCellSelection({ cell, row in
                            self.ingredientIndex = index
                            self.openIngredient()
                        }).cellUpdate { cell, row in
                            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                            cell.textLabel?.textAlignment = .left
                            cell.textLabel?.numberOfLines = 0
                        }

                    $0.rowRight = CheckRow() {
                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        $0.cell.tintColor = FalconPalette.defaultBlue
                        $0.value = items[index].bool ?? false
                        $0.cell.accessoryType = .checkmark
                        $0.cell.tintAdjustmentMode = .dimmed
                        }.cellUpdate { cell, row in
                            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                            cell.tintColor = FalconPalette.defaultBlue
                            if row.value == false {
                                cell.accessoryType = .checkmark
                                cell.tintAdjustmentMode = .dimmed
                            } else {
                                cell.tintAdjustmentMode = .automatic
                            }
                        }.onCellSelection({ (cell, row) in
                            self.grocerylist.ingredients![index].bool = row.value
                        })
                        }.cellUpdate { cell, row in
                            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        } , at: 0)
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
        if let recipes = grocerylist.recipes, recipeIndex <= recipes.count - 1 {
            let id = Array<String>(recipes.keys)[recipeIndex]
            showActivityIndicator()
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            Service.shared.fetchRecipesInfo(id: Int(id)!) { (search, err) in
                let detailedRecipe = search
                dispatchGroup.leave()
                dispatchGroup.notify(queue: .main) {
                    let destination = MealDetailViewController()
                    destination.recipe = detailedRecipe
                    destination.detailedRecipe = detailedRecipe
                    destination.activeRecipe = true
                    destination.servings = self.grocerylist.servings?["\(id)"]
                    destination.recipeDelegate = self
                    self.hideActivityIndicator()
                    self.navigationController?.pushViewController(destination, animated: true)
                }
            }
        } else {
            let destination = MealTypeViewController()
            destination.recipeDelegate = self
            destination.activeRecipe = true
            self.navigationController?.pushViewController(destination, animated: true)
        }
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
            } else if rowType is SplitRow<ButtonRow, CheckRow>, let ingredients = self!.grocerylist.ingredients, let rowTag = rows[0].tag {
                if let index = ingredients.firstIndex(where: {$0.name == rowTag}) {
                    self!.grocerylist.ingredients!.remove(at: index)
                }
            }
        }
    }
    
    fileprivate func lookupRecipe(recipeID: Int, add: Bool) {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
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
                        if glIngredients[index].measures?.metric?.amount != nil && recipeIngredient.measures?.metric?.amount! != nil {
                            glIngredients[index].measures!.metric!.amount! +=  recipeIngredient.measures!.metric!.amount! - recipeIngredient.measures!.metric!.amount! * Double(grocerylistServings) / Double(recipe.servings!)
                        }
                        if glIngredients[index].measures?.us?.amount != nil && recipeIngredient.measures?.us?.amount! != nil {
                            glIngredients[index].measures!.us!.amount! +=  recipeIngredient.measures!.us!.amount! - recipeIngredient.measures!.us!.amount! * Double(grocerylistServings) / Double(recipe.servings!)
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
                            if glIngredients[index].measures?.metric?.amount != nil {
                                glIngredients[index].measures?.metric?.amount! += recipeIngredient.measures?.metric?.amount ?? 0.0
                            }
                            if glIngredients[index].measures?.us?.amount != nil {
                                glIngredients[index].measures?.us?.amount! += recipeIngredient.measures?.us?.amount ?? 0.0
                            }
                        } else {
                            if glIngredients[index].amount != nil {
                                glIngredients[index].amount! -= recipeIngredient.amount ?? 0.0
                                if glIngredients[index].amount! == 0 {
                                    print("remove ingredient name \(glIngredients[index].name ?? "no name")")
                                    glIngredients.remove(at: index)
                                    continue
                                } else {
                                    glIngredients[index].recipe![recipe.title] = nil
                                }
                            }
                            if glIngredients[index].measures?.metric?.amount != nil {
                                glIngredients[index].measures?.metric?.amount! -= recipeIngredient.measures?.metric?.amount ?? 0.0
                                if glIngredients[index].measures?.metric?.amount! == 0 {
                                    glIngredients.remove(at: index)
                                    continue
                                } else {
                                    glIngredients[index].recipe![recipe.title] = nil
                                }
                            }
                            if glIngredients[index].measures?.us?.amount != nil {
                                glIngredients[index].measures?.us?.amount! -= recipeIngredient.measures?.us?.amount ?? 0.0
                                if glIngredients[index].measures?.us?.amount! == 0 {
                                    glIngredients.remove(at: index)
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
        if let ingredientSection = form.sectionBy(tag: "ingredientfields") as? MultivaluedSection {
            for _ in 0...form.allSections.count - 2 - ingredientSection.index! {
                form.remove(at: ingredientSection.index! + 1)
            }
            addIngredients()
        } else {
            form.removeAll()
            initializeForm()
        }
    }
    
    @objc fileprivate func openParticipantsInviter() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        let destination = SelectActivityMembersViewController()
        destination.users = users
        destination.filteredUsers = filteredUsers
        if !selectedFalconUsers.isEmpty{
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
}

extension GrocerylistViewController: UpdateIngredientDelegate {
    func updateIngredient(ingredient: ExtendedIngredient, close: Bool?) {
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
        if let items = self.grocerylist.ingredients {
            if items.indices.contains(ingredientIndex) {
                print("active ingredient")
                self.grocerylist.ingredients![ingredientIndex] = ingredient
                if let ingredientRow: SplitRow<ButtonRow, CheckRow> = form.rowBy(tag: "\(ingredient.name!)") {
                    ingredientRow.rowLeft!.title = "\(ingredient.amount ?? 0.0) \(ingredient.unit ?? "") of \(ingredient.name?.capitalized ?? "")"
                    ingredientRow.updateCell()
                    return
                }
            } else if let index = items.firstIndex(where: {$0 == ingredient}) {
                print("ingredient exists")
                if items[index].amount != nil {
                    self.grocerylist.ingredients![index].amount! += ingredient.amount ?? 0.0
                }
                if items[index].measures?.metric?.amount != nil {
                    self.grocerylist.ingredients![index].measures?.metric?.amount! += ingredient.measures?.metric?.amount ?? 0.0
                }
                if items[index].measures?.us?.amount != nil {
                    self.grocerylist.ingredients![index].measures?.us?.amount! += ingredient.measures?.us?.amount ?? 0.0
                }
            } else {
                print("appending ingredient")
                self.grocerylist.ingredients!.append(ingredient)
            }
            
            
            if let ingredientSection = form.sectionBy(tag: "ingredientfields") as? MultivaluedSection {
                for _ in 0...form.allSections.count - 2 - ingredientSection.index! {
                    form.remove(at: ingredientSection.index! + 1)
                }
                addIngredients()
            }
        }
    }
}

extension GrocerylistViewController: UpdateRecipeDelegate {
    func updateRecipe(recipe: Recipe?) {
        if let mvs = self.form.sectionBy(tag: "recipefields") as? MultivaluedSection {
            if let recipe = recipe {
                print("updating Ingredients via delegate")
                let recipeRow = mvs.allRows[recipeIndex]
                recipeRow.title = recipe.title
                if let _ = recipe.extendedIngredients {
                    updateGrocerylist(recipe: recipe, add: true)
                } else {
                    lookupRecipe(recipeID: recipe.id, add: true)
                }
            } else {
                print("remove")
                mvs.remove(at: recipeIndex)
            }
        }
    }
}

extension GrocerylistViewController: UpdateInvitees {
    func updateInvitees(selectedFalconUsers: [User]) {
        if let inviteesRow: ButtonRow = form.rowBy(tag: "Participants") {
            if !selectedFalconUsers.isEmpty {
                self.selectedFalconUsers = selectedFalconUsers
                
                var participantCount = self.selectedFalconUsers.count
                // If user is creating this activity (admin)
                if grocerylist.admin == nil || grocerylist.admin == Auth.auth().currentUser?.uid {
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
            
//            if active {
//                showActivityIndicator()
//                let createActivity = ActivityActions(activity: activity, active: active, selectedFalconUsers: selectedFalconUsers)
//                createActivity.updateActivityParticipants()
//                hideActivityIndicator()
//
//            }
            
        }
    }
}
