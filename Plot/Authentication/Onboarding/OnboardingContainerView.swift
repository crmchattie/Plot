//
//  OnboardingContainerView.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class OnboardingContainerView: UIView {
    
    let collectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemGroupedBackground
        return collectionView
    }()
    
    let pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.currentPageIndicatorTintColor = .systemBlue
        pageControl.pageIndicatorTintColor = .secondaryLabel
        pageControl.isUserInteractionEnabled = false
        return pageControl
    }()
    
    //set-up startPlotting button
    let startPlotting: UIButton = {
        let startPlotting = UIButton()
        startPlotting.translatesAutoresizingMaskIntoConstraints = false
        startPlotting.setTitle("Start Plotting", for: .normal)
        startPlotting.setTitleColor(.white, for: .normal)
        startPlotting.titleLabel?.backgroundColor = .clear
        startPlotting.titleLabel?.font = UIFont.title3.with(weight: .semibold)
        startPlotting.backgroundColor = .systemBlue
        startPlotting.layer.cornerRadius = 10
        return startPlotting
    }()
    
    //add View background color, Subviews and Constraints
    override init(frame: CGRect) {
        super.init(frame: frame)        
        addSubview(collectionView)
        addSubview(pageControl)
        addSubview(startPlotting)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor, constant: 50),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            collectionView.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -20),

            pageControl.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: startPlotting.topAnchor, constant: -20),
            pageControl.heightAnchor.constraint(equalToConstant: 15),
            
            startPlotting.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            startPlotting.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            startPlotting.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -50),
            startPlotting.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
}
