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
    
    let activityIndicatorView: UIActivityIndicatorView = {
        let aiv = UIActivityIndicatorView(style: .whiteLarge)
        aiv.color = .darkGray
        aiv.startAnimating()
        aiv.hidesWhenStopped = true
        return aiv
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        collectionView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        collectionView.register(ActivitySubTypeCell.self, forCellWithReuseIdentifier: kActivitySubTypeCell)
        collectionView.contentInset = .init(top: 0, left: 16, bottom: 10, right: 16)
        
        view.addSubview(activityIndicatorView)
        activityIndicatorView.centerInSuperview()

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
        cell.delegate = self
        if recipes != nil {
            self.activityIndicatorView.stopAnimating()
            let recipe = recipes![indexPath.item]
            cell.recipe = recipe
            return cell
        } else if events != nil {
            self.activityIndicatorView.stopAnimating()
            let event = events![indexPath.item]
            cell.event = event
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

extension HorizontalController: ActivitySubTypeCellDelegate {
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
