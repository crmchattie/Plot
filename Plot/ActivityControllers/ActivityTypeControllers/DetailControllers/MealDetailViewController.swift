//
//  MealDetailViewController.swift
//  Plot
//
//  Created by Cory McHattie on 3/7/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase

class MealDetailViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    private let kActivityDetailCell = "ActivityDetailCell"
    private let kMealDetailCell = "MealDetailCell"
    
    var sections = [String]()
    
    var users = [User]()
    var filteredUsers = [User]()
    var conversations = [Conversation]()
    var favAct = [String: [String]]()
    
    var recipe: Recipe?
    var detailedRecipe: Recipe?
    
    fileprivate var reference: DatabaseReference!
        
        
    init() {
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
            
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = true
        
        title = "Meal"
        
        extendedLayoutIncludesOpaqueBars = true
        definesPresentationContext = true
        edgesForExtendedLayout = UIRectEdge.top
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        collectionView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        collectionView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        collectionView.register(ActivityDetailCell.self, forCellWithReuseIdentifier: kActivityDetailCell)
        collectionView.register(MealDetailCell.self, forCellWithReuseIdentifier: kMealDetailCell)
        
        if detailedRecipe == nil {
            fetchData()
        }
        
        if favAct.isEmpty {
            fetchFavAct()
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }
    
    fileprivate func fetchData() {
        
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        if let recipe = recipe {
            Service.shared.fetchRecipesInfo(id: recipe.id) { (search, err) in
                self.detailedRecipe = search
                dispatchGroup.leave()
                dispatchGroup.notify(queue: .main) {
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
    fileprivate func fetchFavAct() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        self.reference = Database.database().reference().child("user-fav-activities").child(currentUserID)
        self.reference.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists(), let favoriteActivitiesSnapshot = snapshot.value as? [String: [String]] {
                print("snapshot exists")
                self.favAct = favoriteActivitiesSnapshot
                self.collectionView.reloadData()
            }
        })
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kActivityDetailCell, for: indexPath) as! ActivityDetailCell
            cell.delegate = self
            if let recipe = recipe {
                if let recipes = favAct["recipes"], recipes.contains("\(recipe.id)") {
                    print("heart filled")
                    cell.heartButtonImage = "heart-filled"
                } else {
                    print("heart")
                    cell.heartButtonImage = "heart"
                }
                cell.recipe = recipe
                return cell
            } else {
                return cell
            }
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kMealDetailCell, for: indexPath) as! MealDetailCell
            if let recipe = detailedRecipe {
                cell.mealExpandedDetailViewController.recipe = recipe
                cell.mealExpandedDetailViewController.collectionView.reloadData()
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 328
        if indexPath.item == 0 {
            let dummyCell = ActivityDetailCell(frame: .init(x: 0, y: 0, width: view.frame.width, height: 328))
            dummyCell.recipe = recipe
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: view.frame.width, height: 328))
            height = estimatedSize.height
            return CGSize(width: view.frame.width, height: height)
        } else {
            let dummyCell = MealDetailCell(frame: .init(x: 0, y: 0, width: view.frame.width, height: 1000))
            if let recipe = detailedRecipe {
                dummyCell.mealExpandedDetailViewController.recipe = recipe
                dummyCell.mealExpandedDetailViewController.collectionView.reloadData()
            }
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: view.frame.width, height: 1000))
            height = estimatedSize.height
            return CGSize(width: view.frame.width, height: height)
        }
    }
}

extension MealDetailViewController: ActivityDetailCellDelegate {
    func plusButtonTapped(type: Any) {
        print("plusButtonTapped")
    }
    
    func shareButtonTapped(id: String) {
        print("shareButtonTapped")
    }
    
    func heartButtonTapped(type: Any) {
        print("heartButtonTapped")
        if let currentUserID = Auth.auth().currentUser?.uid {
            let databaseReference = Database.database().reference().child("user-fav-activities").child(currentUserID)
            if let recipe = type as? Recipe {
                print(recipe.title)
                databaseReference.child("recipes").observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists() {
                        var value = snapshot.value as! [String]
                        if value.contains("\(recipe.id)") {
                            if let index = value.firstIndex(of: "\(recipe.id)") {
                                value.remove(at: index)
                            }
                            databaseReference.updateChildValues(["recipes": value as NSArray])
                        } else {
                            value.append("\(recipe.id)")
                            databaseReference.updateChildValues(["recipes": value as NSArray])
                        }
                        self.favAct["recipes"] = value
                    } else {
                        self.favAct["recipes"] = ["\(recipe.id)"]
                        databaseReference.updateChildValues(["recipes": ["\(recipe.id)"]])
                    }
                })
            }
        }
        
    }

}
