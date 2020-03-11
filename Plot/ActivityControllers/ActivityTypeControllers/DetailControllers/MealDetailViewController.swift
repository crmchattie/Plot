//
//  MealDetailViewController.swift
//  Plot
//
//  Created by Cory McHattie on 3/7/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class MealDetailViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    private let kActivityDetailCell = "ActivityDetailCell"
    private let kMealDetailCell = "MealDetailCell"
    
    var sections = [String]()
    
    var users = [User]()
    var filteredUsers = [User]()
    var conversations = [Conversation]()
    
    var recipe: Recipe?
    var detailedRecipe: Recipe?
    
        
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
                                
        fetchData()
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }
    
    fileprivate func fetchData() {
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
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kActivityDetailCell, for: indexPath) as! ActivityDetailCell
            cell.delegate = self
            if let recipe = recipe {
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
            print("height: \(height)")
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
            print("height: \(height)")
            return CGSize(width: view.frame.width, height: height)
        }
    }
}

extension MealDetailViewController: ActivityDetailCellDelegate {
    func plusButtonTapped() {
        print("plusButtonTapped")
    }
    
    func shareButtonTapped() {
        print("shareButtonTapped")
    }
    
    func heartButtonTapped() {
        print("heartButtonTapped")
    }

}
