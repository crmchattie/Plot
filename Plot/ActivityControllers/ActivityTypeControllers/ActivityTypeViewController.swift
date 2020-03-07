//
//  ActivityTypeViewController.swift
//  Plot
//
//  Created by Hafiz Usama on 2019-11-11.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit
import MapKit


class ActivityTypeViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    private let kActivityTypeCell = "ActivityTypeCell"
    private let headerId = "headerId"
    
    private let musicSegmentID = "KZFzniwnSyZfZ7v7nJ"
    private let sportsSegmentID = "KZFzniwnSyZfZ7v7nE"
    
    var sections = [String]()
    var types: [ActivityType] = [.basic, .meal, .workout]
    
    var users = [User]()
    var filteredUsers = [User]()
    var conversations = [Conversation]()
    var groups = [Any]()
    
    var locationManager = CLLocationManager()
    
    init() {
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
        title = "Choose Activity"
        extendedLayoutIncludesOpaqueBars = true
        definesPresentationContext = true
        edgesForExtendedLayout = UIRectEdge.top
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        collectionView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        collectionView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        collectionView.register(ActivityTypeCell.self, forCellWithReuseIdentifier: kActivityTypeCell)
        collectionView.register(ActivityHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerId)
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                        
        fetchData()
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }
    
    fileprivate func fetchData() {
        
        if let navController = self.navigationController {
            self.showSpinner(onView: navController.view)
        } else {
            self.showSpinner(onView: self.view)
        }
            
        var recipes: [Recipe]?
        var musicEvents: [Event]?
        var sportsEvents: [Event]?
        
        // help you sync your data fetches together
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        Service.shared.fetchRecipesSimple(query: "healthy", cuisine: "American") { (search, err) in
            recipes = search?.recipes
            dispatchGroup.leave()
        }
        
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways {
            dispatchGroup.enter()
            Service.shared.fetchEventsLatLong(segmentId: musicSegmentID, lat: locationManager.location?.coordinate.latitude ?? 0.0, long: locationManager.location?.coordinate.longitude ?? 0.0) { (search, err) in
                musicEvents = search?._embedded["events"]
                dispatchGroup.leave()
            }
            
            dispatchGroup.enter()
            Service.shared.fetchEventsLatLong(segmentId: sportsSegmentID, lat: locationManager.location?.coordinate.latitude ?? 0.0, long: locationManager.location?.coordinate.longitude ?? 0.0) { (search, err) in
                sportsEvents = search?._embedded["events"]
                dispatchGroup.leave()
            }
        } else {
            dispatchGroup.enter()
            Service.shared.fetchEvents(segmentId: musicSegmentID) { (search, err) in
                musicEvents = search?._embedded["events"]
                dispatchGroup.leave()
            }
            
            dispatchGroup.enter()
            Service.shared.fetchEvents(segmentId: sportsSegmentID) { (search, err) in
                sportsEvents = search?._embedded["events"]
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.removeSpinner()
            
                if let group = recipes {
                    self.groups.append(group)
                    self.sections.append("Meals")
                }
                if let group = musicEvents {
                    self.groups.append(group)
                    self.sections.append("Concerts")
                }
                if let group = sportsEvents {
                    self.groups.append(group)
                    self.sections.append("Sports")
                }
            self.collectionView.reloadData()
            let layout = UICollectionViewFlowLayout()
            self.collectionView.collectionViewLayout = layout
        }
    }
    
    // MARK: UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerId, for: indexPath) as! ActivityHeader
        header.activityHeaderHorizontalController.customActivities = self.types
        header.activityHeaderHorizontalController.collectionView.reloadData()
        
            header.activityHeaderHorizontalController.didSelectHandler = { [weak self] cellData in
            
                if let activityType = cellData as? ActivityType {
                    let activityTypeName = activityType.rawValue
                        switch activityTypeName {
                        case "basic":
                            print("basic")
                            let destination = CreateActivityViewController()
                            destination.hidesBottomBarWhenPushed = true
                            destination.users = self!.users
                            destination.filteredUsers = self!.filteredUsers
                            destination.conversations = self!.conversations
                            self?.navigationController?.pushViewController(destination, animated: true)
                        case "meal":
                            print("meal")
                        case "workout":
                            print("workout")
                        default:
                            print("default")
                        }
                }
            
            }
        return header

    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return .init(width: view.frame.width, height: 175)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return groups.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kActivityTypeCell, for: indexPath) as! ActivityTypeCell
        cell.delegate = self
        cell.titleLabel.text = sections[indexPath.item]
        var controllerTitle = sections[indexPath.item]
        
        let cellData = groups[indexPath.item]
        if let customActivities = cellData as? [ActivityType] {
            cell.horizontalController.customActivities = customActivities
        } else if let recipes = cellData as? [Recipe] {
            cell.horizontalController.recipes = recipes
        } else if let events = cellData as? [Event] {
            cell.horizontalController.events = events
        } else {
            cell.horizontalController.cellData = cellData
        }
        
        cell.horizontalController.didSelectHandler = { [weak self] cellData in
            
            if let recipe = cellData as? Recipe {
                print("meal \(recipe.title)")
                let destination = ActivityDetailViewController()
                destination.hidesBottomBarWhenPushed = true
                destination.recipe = recipe
                destination.title = controllerTitle
                destination.users = self!.users
                destination.filteredUsers = self!.filteredUsers
                destination.conversations = self!.conversations
                self?.navigationController?.pushViewController(destination, animated: true)
            } else if let event = cellData as? Event {
                print("event \(event.name)")
                let destination = ActivityDetailViewController()
                destination.hidesBottomBarWhenPushed = true
                destination.event = event
                destination.title = controllerTitle
                destination.users = self!.users
                destination.filteredUsers = self!.filteredUsers
                destination.conversations = self!.conversations
                self?.navigationController?.pushViewController(destination, animated: true)
            } else {
                print("neither meals or events")
            }
            
        }
        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 16, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 415)
    }
  
}

extension ActivityTypeViewController: ActivityTypeCellDelegate {
    func viewTapped(labelText: String) {
        switch labelText {
        case "Meals":
            let destination = MealTypeViewController()
            destination.hidesBottomBarWhenPushed = true
            destination.users = users
            destination.filteredUsers = filteredUsers
            destination.conversations = conversations
            navigationController?.pushViewController(destination, animated: true)
        case "Concerts":
            print("Concerts")
        case "Sports":
            print("Sports")
        default:
            print("Default")
        }
    }
}
