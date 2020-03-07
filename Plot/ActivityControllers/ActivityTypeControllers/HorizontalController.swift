//
//  HorizontalController.swift
//  Plot
//
//  Created by Cory McHattie on 1/4/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class HorizontalController: HorizontalSnappingController, UICollectionViewDelegateFlowLayout {
    
    private let kActivitySubTypeCell = "ActivitySubTypeCell"
    
    var cellData: Any?
    var customActivities: [ActivityType]?
    var recipes: [Recipe]?
    var events: [Event]?
    var numberOfRows: Int = 0
    
    var users = [User]()
    var filteredUsers = [User]()
    var conversations = [Conversation]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        collectionView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        collectionView.register(ActivitySubTypeCell.self, forCellWithReuseIdentifier: kActivitySubTypeCell)
        collectionView.contentInset = .init(top: 0, left: 16, bottom: 10, right: 16)

    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }
    
    var didSelectHandler: ((Any) -> ())?
        
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("item selected")
        if customActivities != nil {
            if let activityType = customActivities?[indexPath.item] {
                didSelectHandler?(activityType)
            }
        } else if recipes != nil {
            if let recipe = recipes?[indexPath.item] {
                didSelectHandler?(recipe)
            }
        } else if events != nil {
            if let event = events?[indexPath.item] {
                didSelectHandler?(event)
            }
        } else {
            
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if customActivities != nil {
            return customActivities!.count
        } else if recipes != nil {
            return recipes!.count
        } else if events != nil {
            return events!.count
        } else {
            return 0
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kActivitySubTypeCell, for: indexPath) as! ActivitySubTypeCell
        if recipes != nil {
            let recipe = recipes![indexPath.item]
            cell.nameLabel.text = recipe.title
            if let categoryLabel = recipe.readyInMinutes, let subcategoryLabel = recipe.servings {
                cell.categoryLabel.text = "Preparation time: \(categoryLabel) mins"
                cell.subcategoryLabel.text = "Servings: \(subcategoryLabel)"
            }
            let recipeImage = "https://spoonacular.com/recipeImages/\(recipe.id)-636x393.jpg"
                cell.imageView.sd_setImage(with: URL(string: recipeImage))
            return cell
        } else if events != nil {
            let event = events![indexPath.item]
            cell.nameLabel.text = "\(event.name)"
            if let startDateTime = event.dates.start.dateTime {
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                let date = dateFormatter.date(from:startDateTime)!
                let newDate = date.startDateTimeString()
                cell.categoryLabel.text = "\(newDate)  @ \(event._embedded["venues"]?[0].name ?? "")"
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
            cell.imageView.sd_setImage(with: URL(string: event.images[3].url))
            return cell
        } else {
            return cell
        }
    }
    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
//        return UIEdgeInsets.init(top: 0, left: 10, bottom: 10, right: 10)
//    }
//    let topBottomPadding: CGFloat = 12
//    let lineSpacing: CGFloat = 10
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: view.frame.width - 48, height: view.frame.height)
    }
    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
//        return lineSpacing
//    }
    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
//        return .init(top: topBottomPadding, left: 0, bottom: 0, right: 0)
//    }
    
}
