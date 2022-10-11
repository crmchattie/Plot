//
//  OnboardingController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

let onboardingCollectionViewCell = "OnboardingCollectionViewCell"

class OnboardingController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    let onboardingContainerView = OnboardingContainerView()
    
    let items: [CustomType] = [.time, .health, .finances]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set-up interface with the help of OnboardingContainerView file
        extendedLayoutIncludesOpaqueBars = true
        view.backgroundColor = .systemGroupedBackground
        
        view.addSubview(onboardingContainerView)
        onboardingContainerView.translatesAutoresizingMaskIntoConstraints = false
        onboardingContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        onboardingContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        onboardingContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        onboardingContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        onboardingContainerView.collectionView.delegate = self
        onboardingContainerView.collectionView.dataSource = self
        onboardingContainerView.collectionView.register(OnboardingCollectionViewCell.self, forCellWithReuseIdentifier: onboardingCollectionViewCell)
        
        onboardingContainerView.collectionView.isPagingEnabled = true
        onboardingContainerView.collectionView.showsHorizontalScrollIndicator = false
        onboardingContainerView.pageControl.numberOfPages = 3
        onboardingContainerView.pageControl.currentPage = 0
        
        onboardingContainerView.startPlotting.addTarget(self, action: #selector(startPlottingDidTap), for: .touchUpInside)

        
    }
    
    //move to next ViewController when user taps on startMessagingDidTap button
    @objc func startPlottingDidTap() {
        let destination = AuthPhoneNumberController()
        navigationController?.pushViewController(destination, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: onboardingCollectionViewCell, for: indexPath) as! OnboardingCollectionViewCell
        cell.intColor = (indexPath.item % 3)
        cell.customType = items[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.size.width, height: 300)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollPos = scrollView.contentOffset.x / view.frame.width
        onboardingContainerView.pageControl.currentPage = Int(scrollPos)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        onboardingContainerView.pageControl.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        onboardingContainerView.pageControl.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
    }
    
}
