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
    
    let items: [CustomType] = [.tutorialOne, .tutorialTwo, .tutorialThree, .tutorialFour]
    
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
        onboardingContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
        onboardingContainerView.collectionView.delegate = self
        onboardingContainerView.collectionView.dataSource = self
        onboardingContainerView.collectionView.register(OnboardingCollectionViewCell.self, forCellWithReuseIdentifier: onboardingCollectionViewCell)
        
        onboardingContainerView.collectionView.isPagingEnabled = true
        onboardingContainerView.collectionView.showsHorizontalScrollIndicator = false
        onboardingContainerView.pageControl.numberOfPages = items.count
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
        cell.intColor = indexPath.item
        cell.customType = items[indexPath.item]
        if indexPath.item == 0 {
            cell.activities = nil
            cell.healthMetrics = nil
            cell.finances = nil
            cell.collectionView.reloadData()
        } else if indexPath.item == 1 {
            cell.activities = createActivities()
        } else if indexPath.item == 2 {
            cell.healthMetrics = createHealthMetrics()
        } else if indexPath.item == 3 {
            cell.finances = createFinances()
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.size.width, height: collectionView.frame.size.height)
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
    
    func createActivities() -> [Activity] {
        var dateComponents = DateComponents()
        dateComponents.year = Date.yearNumber(Date())()
        dateComponents.month = Date.monthNumber(Date())()
        dateComponents.day = Date.dayNumber(Date())()
        dateComponents.timeZone = TimeZone.current
        let calendar = Calendar.current
        
        let firstActivity = Activity(dictionary: ["activityID": UUID().uuidString as AnyObject])
        firstActivity.name = "Laundry"
        firstActivity.category = "To-do"
        firstActivity.isTask = true
        dateComponents.hour = 12
        dateComponents.minute = 00
        var startDate = calendar.date(from: dateComponents)!
        dateComponents.hour = 13
        dateComponents.minute = 00
        var endDate = calendar.date(from: dateComponents)!
        firstActivity.endDateTime = NSNumber(value: Int((endDate).timeIntervalSince1970))
        firstActivity.hasDeadlineTime = true
        firstActivity.allDay = false
        
        let secondActivity = Activity(dictionary: ["activityID": UUID().uuidString as AnyObject])
        secondActivity.name = "Workout"
        secondActivity.category = "Health"
        firstActivity.isEvent = true
        dateComponents.hour = 17
        dateComponents.minute = 30
        startDate = calendar.date(from: dateComponents)!
        dateComponents.hour = 18
        dateComponents.minute = 00
        endDate = calendar.date(from: dateComponents)!
        secondActivity.startDateTime = NSNumber(value: Int((startDate).timeIntervalSince1970))
        secondActivity.startTimeZone = TimeZone.current.identifier
        secondActivity.endDateTime = NSNumber(value: Int((endDate).timeIntervalSince1970))
        secondActivity.endTimeZone = TimeZone.current.identifier
        secondActivity.allDay = false
        
        let thirdActivity = Activity(dictionary: ["activityID": UUID().uuidString as AnyObject])
        thirdActivity.name = "Dinner"
        thirdActivity.category = "Meal"
        firstActivity.isEvent = true
        dateComponents.hour = 19
        dateComponents.minute = 30
        startDate = calendar.date(from: dateComponents)!
        dateComponents.hour = 21
        dateComponents.minute = 30
        endDate = calendar.date(from: dateComponents)!
        thirdActivity.startDateTime = NSNumber(value: Int((startDate).timeIntervalSince1970))
        thirdActivity.startTimeZone = TimeZone.current.identifier
        thirdActivity.endDateTime = NSNumber(value: Int((endDate).timeIntervalSince1970))
        thirdActivity.endTimeZone = TimeZone.current.identifier
        thirdActivity.allDay = false
        
        let activities = [firstActivity, secondActivity, thirdActivity]
        return activities
    }
    
    func createHealthMetrics() -> [HealthMetric] {
        var stepsMetric = HealthMetric(type: HealthMetricType.steps, total: 7500, date: Date(), unitName: "steps", rank: HealthMetricType.steps.rank)
        stepsMetric.average = 5000
        var sleepMetric = HealthMetric(type: .sleep, total: 27000, date: Date(), unitName: "hrs", rank: HealthMetricType.sleep.rank)
        sleepMetric.average = 28800
        var metricMinutes = HealthMetric(type: HealthMetricType.workoutMinutes, total: 45, date: Date(), unitName: "minutes", rank: -1)
        metricMinutes.average = 2700
        let metrics = [stepsMetric, sleepMetric, metricMinutes]
        return metrics
    }
    
    func createFinances() -> [AnyHashable] {
        var netWorthDetail = AccountDetails(name: "Net Worth", balance: 127500, level: .bs_type, subtype: nil, type: nil, bs_type: .NetWorth, currencyCode: "USD")
        netWorthDetail.lastPeriodBalance = 120000
        var assetsDetail = AccountDetails(name: "Assets", balance: 130000, level: .bs_type, subtype: nil, type: nil, bs_type: .Asset, currencyCode: "USD")
        assetsDetail.lastPeriodBalance = 125000
        var liabilitiesDetail = AccountDetails(name: "Liabilities", balance: 2500, level: .bs_type, subtype: nil, type: nil, bs_type: .Liability, currencyCode: "USD")
        liabilitiesDetail.lastPeriodBalance = 5000
        let finances = [netWorthDetail, assetsDetail, liabilitiesDetail]
        return finances
    }
    
}
