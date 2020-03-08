//
//  ActivityTypeDetailViewController.swift
//  Plot
//
//  Created by Cory McHattie on 2/6/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class ActivityDetailViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    private let kActivityDetailCell = "ActivityDetailCell"
    
    var sections = [String]()
    
    var users = [User]()
    var filteredUsers = [User]()
    var conversations = [Conversation]()
    
    var recipe: Recipe?
    var event: Event?
    
    var controllerTitle = String()
        
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
        
        extendedLayoutIncludesOpaqueBars = true
        definesPresentationContext = true
        edgesForExtendedLayout = UIRectEdge.top
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        collectionView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        collectionView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        collectionView.register(ActivityDetailCell.self, forCellWithReuseIdentifier: kActivityDetailCell)
                                
        fetchData()
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }
    
    fileprivate func fetchData() {
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kActivityDetailCell, for: indexPath) as! ActivityDetailCell
        cell.delegate = self
        if let recipe = recipe {
            title = "Meal"
            cell.nameLabel.text = recipe.title
            if let categoryLabel = recipe.readyInMinutes, let subcategoryLabel = recipe.servings {
                cell.categoryLabel.text = "Preparation time: \(categoryLabel) mins"
                cell.subcategoryLabel.text = "Servings: \(subcategoryLabel)"
            }
            let recipeImage = "https://spoonacular.com/recipeImages/\(recipe.id)-636x393.jpg"
                cell.imageView.sd_setImage(with: URL(string: recipeImage))
            return cell
        } else if let event = event {
            title = "Event"
            cell.nameLabel.text = "\(event.name)"
            if let startDateTime = event.dates?.start?.dateTime {
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                let date = dateFormatter.date(from:startDateTime)!
                let newDate = date.startDateTimeString()
                cell.categoryLabel.text = "\(newDate)  @ \(event.embedded?.venues?[0].name ?? "")"
            }
            if let minPrice = event.priceRanges?[0].min, let maxPrice = event.priceRanges?[0].max {
                let formatter = CurrencyFormatter()
                formatter.locale = .current
                formatter.numberStyle = .currency
                let minPriceString = formatter.string(for: minPrice)!
                let maxPriceString = formatter.string(for: maxPrice)!
                cell.subcategoryLabel.text = "Price range: \(minPriceString) to \(maxPriceString)"
            } else {
                cell.subcategoryLabel.text = ""
            }
            if let images = event.images, let image = images.first(where: { $0.width == 640 && $0.height == 427 }), let url = image.url {
                cell.imageView.sd_setImage(with: URL(string: url))
            }
            return cell
        } else {
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 397)
    }
}

extension ActivityDetailViewController: ActivityDetailCellDelegate {
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
