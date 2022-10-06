//
//  TutorialViewController.swift
//  Plot
//
//  Created by Cory McHattie on 10/5/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import Foundation

class TutorialViewController: UIViewController {
    let collectionView:UICollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout.init())
    let layout:UICollectionViewFlowLayout = UICollectionViewFlowLayout.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        extendedLayoutIncludesOpaqueBars = true
        view.backgroundColor = .systemGroupedBackground
        
        configureNavigationBar()
    }
    
    fileprivate func configureNavigationBar () {
//        let rightBarButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(rightBarButtonDidTap))
//        self.navigationItem.rightBarButtonItem = rightBarButton
        title = "Get Started"
        navigationItem.setHidesBackButton(true, animated: true)
    }
    
}
