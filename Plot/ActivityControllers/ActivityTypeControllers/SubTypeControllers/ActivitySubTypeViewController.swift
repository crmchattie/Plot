//
//  ActivitySubTypeViewController.swift
//  Plot
//
//  Created by Cory McHattie on 1/20/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class ActivitySubTypeViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    let kActivityTypeCell = "ActivityTypeCell"
    let headerId = "headerId"
    let searchController = UISearchController(searchResultsController: nil)
    
    var users = [User]()
    var filteredUsers = [User]()
    var conversations = [Conversation]()
        
    var timer: Timer?
    var headerheight: CGFloat = 0
    var cellheight: CGFloat = 0
    
    var showGroups = true
    
    
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
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for:.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layoutIfNeeded()
        
        extendedLayoutIncludesOpaqueBars = true
        definesPresentationContext = true
        edgesForExtendedLayout = UIRectEdge.bottom
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        collectionView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        collectionView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        collectionView.register(ActivityTypeCell.self, forCellWithReuseIdentifier: kActivityTypeCell)
        collectionView.register(SearchHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerId)
                
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }
}

