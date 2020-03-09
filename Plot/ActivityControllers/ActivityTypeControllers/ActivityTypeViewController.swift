//
//  ActivityTypeViewController.swift
//  Plot
//
//  Created by Hafiz Usama on 2019-11-11.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit
import MapKit
import Firebase
import CodableFirebase


class ActivityTypeViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    fileprivate var workoutReference: DatabaseReference!
    
    private let kActivityTypeCell = "ActivityTypeCell"
    private let headerId = "headerId"
    
    var sections: [String] = ["Recipes", "Workouts", "Events"]
    var types: [ActivityType] = [.basic]
    var recipes = [Recipe]()
    
    var workoutIDs: [String] = ["ZB9Gina","E5YrL4F","lhNZOX1","LWampEt","5jbuzns","ltrgYTF","Z37OGjs","7GdJQBG","RKrXsHn","GwxLrim","nspLcIX","nHWkOhp","0ym6yNn","6VLf2M7","n8g5auz","CM5o2rv","ufiyRQc","N7aHlCw","gIeTbVT","lGaFbQK"]
    
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
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
                        
        fetchData()
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }
    
    fileprivate func fetchData() {
            
        var recipes: [Recipe]?
        var workouts = [Workout]()
        var events: [Event]?
        
        // help you sync your data fetches together
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        Service.shared.fetchRecipesSimple(query: "healthy", cuisine: "American") { (search, err) in
            recipes = search?.recipes
            dispatchGroup.leave()
            
            dispatchGroup.notify(queue: .main) {
                if let group = recipes {
                    self.groups.append(group)
                    self.recipes = group
                } else {
                    self.sections.removeAll{ $0 == "Recipes"}
                }
                
                self.collectionView.reloadData()
                
                for workoutID in self.workoutIDs {
                    dispatchGroup.enter()
                    self.workoutReference = Database.database().reference().child("workouts").child("0")
                    self.workoutReference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                        if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                            if let workout = try? FirebaseDecoder().decode(Workout.self, from: workoutSnapshotValue) {
                                print("workout title \(String(describing: workout.title))")
                                workouts.append(workout)
                                dispatchGroup.leave()
                            }
                        }
                      })
                    { (error) in
                        print(error.localizedDescription)
                    }
                }
                
                dispatchGroup.notify(queue: .main) {
                    self.groups.append(workouts)
                    self.collectionView.reloadData()
    
                    if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways {
                        dispatchGroup.enter()
                        Service.shared.fetchEventsSegmentLatLong(segmentId: "", lat: self.locationManager.location?.coordinate.latitude ?? 0.0, long: self.locationManager.location?.coordinate.longitude ?? 0.0) { (search, err) in
                            events = search?.embedded?.events
                            dispatchGroup.leave()
                            dispatchGroup.notify(queue: .main) {
                                if let group = events {
                                    self.groups.append(group)
                                } else {
                                    self.sections.removeAll{ $0 == "Events"}
                                }
                                
                                self.collectionView.reloadData()
                            }
                        }
                    } else {
                        dispatchGroup.enter()
                        Service.shared.fetchEventsSegment(segmentId: "") { (search, err) in
                            events = search?.embedded?.events
                            dispatchGroup.leave()
                            dispatchGroup.notify(queue: .main) {
                                if let group = events {
                                    self.groups.append(group)
                                } else {
                                    self.sections.removeAll{ $0 == "Events"}
                                }
                
                                self.collectionView.reloadData()
                                    
                            }
                        }
                    }
                }
            }
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
        return sections.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kActivityTypeCell, for: indexPath) as! ActivityTypeCell
        cell.delegate = self
        cell.titleLabel.text = sections[indexPath.item]
        if indexPath.item < groups.count {
            let cellData = groups[indexPath.item]
            if let recipes = cellData as? [Recipe] {
                cell.horizontalController.recipes = recipes
                cell.horizontalController.events = nil
                cell.horizontalController.workouts = nil
            } else if let events = cellData as? [Event] {
                cell.horizontalController.events = events
                cell.horizontalController.recipes = nil
                cell.horizontalController.workouts = nil
            } else if let workouts = cellData as? [Workout] {
                cell.horizontalController.workouts = workouts
                cell.horizontalController.recipes = nil
                cell.horizontalController.events = nil
            } else {
                cell.horizontalController.cellData = cellData
            }
            cell.horizontalController.collectionView.reloadData()
            cell.horizontalController.didSelectHandler = { [weak self] cellData in
                
                if let recipe = cellData as? Recipe {
                    print("meal \(recipe.title)")
                    let destination = MealDetailViewController()
                    destination.hidesBottomBarWhenPushed = true
                    destination.recipe = recipe
                    destination.users = self!.users
                    destination.filteredUsers = self!.filteredUsers
                    destination.conversations = self!.conversations
                    self?.navigationController?.pushViewController(destination, animated: true)
                } else if let event = cellData as? Event {
                    print("event \(String(describing: event.name))")
                    let destination = EventDetailViewController()
                    destination.hidesBottomBarWhenPushed = true
                    destination.event = event
                    destination.users = self!.users
                    destination.filteredUsers = self!.filteredUsers
                    destination.conversations = self!.conversations
                    self?.navigationController?.pushViewController(destination, animated: true)
                } else if let workout = cellData as? Workout {
                    print("workout \(String(describing: workout.title))")
//                    let destination = EventDetailViewController()
//                    destination.hidesBottomBarWhenPushed = true
//                    destination.event = event
//                    destination.users = self!.users
//                    destination.filteredUsers = self!.filteredUsers
//                    destination.conversations = self!.conversations
//                    self?.navigationController?.pushViewController(destination, animated: true)
                } else {
                    print("neither meals or events")
                }
            }
        }
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 16, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 397)
    }
  
}

extension ActivityTypeViewController: ActivityTypeCellDelegate {
    func viewTapped(labelText: String) {
        switch labelText {
        case "Recipes":
            let destination = MealTypeViewController()
            destination.hidesBottomBarWhenPushed = true
            if !recipes.isEmpty {
                destination.groups.append(recipes)
            }
            destination.users = users
            destination.filteredUsers = filteredUsers
            destination.conversations = conversations
            navigationController?.pushViewController(destination, animated: true)
        case "Events":
            print("Event")
            let destination = EventTypeViewController()
            destination.hidesBottomBarWhenPushed = true
            destination.users = users
            destination.filteredUsers = filteredUsers
            destination.conversations = conversations
            navigationController?.pushViewController(destination, animated: true)
        case "Workouts":
            print("Workouts")
        default:
            print("Default")
        }
    }
}
