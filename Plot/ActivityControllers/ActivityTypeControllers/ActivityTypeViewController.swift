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
import SwiftUI

class ActivityTypeViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    weak var delegate : UpdateScheduleDelegate?
    weak var recipeDelegate : UpdateRecipeDelegate?
    
    fileprivate var reference: DatabaseReference!
    
    private let kCompositionalHeader = "CompositionalHeader"
    private let kActivityTypeCell = "ActivityTypeCell"
    private let kActivityHeaderCell = "ActivityHeaderCell"
    
    var attractionsString = [String]()
    var customTypes: [ActivityType] = [.basic, .flight]
    var favAct = [String: [String]]()
    
    var sections: [ActivitySection] = [.custom, .food, .nightlife, .events, .sightseeing, .recreation, .shopping, .workouts, .recipes]
    var groups = [ActivitySection: [AnyHashable]]()
    
    var workoutIDs: [String] = ["ZB9Gina","E5YrL4F","lhNZOX1","LWampEt","5jbuzns","ltrgYTF","Z37OGjs","7GdJQBG","RKrXsHn","GwxLrim","nspLcIX","nHWkOhp","0ym6yNn","6VLf2M7","n8g5auz","CM5o2rv","ufiyRQc","N7aHlCw","gIeTbVT","lGaFbQK"]
    var intColor: Int = 0
    
    var umbrellaActivity: Activity!
    var schedule: Bool = false
    var movingBackwards: Bool = true
    
    var users = [User]()
    var filteredUsers = [User]()
    var selectedFalconUsers = [User]()
    var activities = [Activity]()
    var conversations = [Conversation]()
    var conversation: Conversation?
    
    var activity: Activity!
    var activeRecipe: Bool = false
    
    var startDateTime: Date?
    var endDateTime: Date?
    
    var locationManager = CLLocationManager()
    
    let navigationItemActivityIndicator = NavigationItemActivityIndicator()
    
    init() {
        
        let layout = UICollectionViewCompositionalLayout { (sectionNumber, _) -> NSCollectionLayoutSection? in
            
            if sectionNumber == 0 {
                return ActivityTypeViewController.topSection()
            } else {
                // second section
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1/3)))
                item.contentInsets = .init(top: 0, leading: 0, bottom: 8, trailing: 16)
                
                let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(0.92), heightDimension: .absolute(360)), subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .groupPaging
                section.contentInsets.leading = 16
                section.contentInsets.trailing = 16
                
                let kind = UICollectionView.elementKindSectionHeader
                section.boundarySupplementaryItems = [
                    .init(layoutSize: .init(widthDimension: .fractionalWidth(0.92), heightDimension: .absolute(50)), elementKind: kind, alignment: .topLeading)
                ]
                
                return section
            }
        }
        
        super.init(collectionViewLayout: layout)
    }
    
    static func topSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
        item.contentInsets.bottom = 16
        item.contentInsets.trailing = 16
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(0.92), heightDimension: .absolute(175)), subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPaging
        section.contentInsets.leading = 16
        
        let kind = UICollectionView.elementKindSectionHeader
        section.boundarySupplementaryItems = [
            .init(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(50)), elementKind: kind, alignment: .topLeading)
        ]
        
        return section
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(activityIndicatorView)
        activityIndicatorView.centerInSuperview()
        
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = false
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for:.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layoutIfNeeded()
        
        tabBarController?.tabBar.barTintColor = ThemeManager.currentTheme().barBackgroundColor
        tabBarController?.tabBar.barStyle = ThemeManager.currentTheme().barStyle
        
        extendedLayoutIncludesOpaqueBars = true
        definesPresentationContext = true
        edgesForExtendedLayout = UIRectEdge.top
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        collectionView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        collectionView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        collectionView.register(CompositionalHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: kCompositionalHeader)
        collectionView.register(ActivityHeaderCell.self, forCellWithReuseIdentifier: kActivityHeaderCell)
        collectionView.register(ActivityTypeCell.self, forCellWithReuseIdentifier: kActivityTypeCell)
        
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        
        addObservers()
        
        groups[.custom] = customTypes
        
        fetchData()
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        managePresense()
        fetchFavAct()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if movingBackwards && navigationController?.visibleViewController is CreateActivityViewController {
            let activity = Activity(dictionary: ["activityID": UUID().uuidString as AnyObject])
            delegate?.updateSchedule(schedule: activity)
        }
        
    }
    
    fileprivate func managePresense() {
        if currentReachabilityStatus == .notReachable {
            navigationItemActivityIndicator.showActivityIndicator(for: navigationItem, with: .connecting,
                                                                  activityPriority: .high,
                                                                  color: ThemeManager.currentTheme().generalTitleColor)
        }
        
        let connectedReference = Database.database().reference(withPath: ".info/connected")
        connectedReference.observe(.value, with: { (snapshot) in
            
            if self.currentReachabilityStatus != .notReachable {
                self.navigationItemActivityIndicator.hideActivityIndicator(for: self.navigationItem, activityPriority: .crazy)
            } else {
                self.navigationItemActivityIndicator.showActivityIndicator(for: self.navigationItem, with: .noInternet, activityPriority: .crazy, color: ThemeManager.currentTheme().generalTitleColor)
            }
        })
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
    }
    
    @objc fileprivate func changeTheme() {
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        navigationController?.navigationBar.barStyle = ThemeManager.currentTheme().barStyle
        navigationController?.navigationBar.barTintColor = ThemeManager.currentTheme().barBackgroundColor
        let textAttributes = [NSAttributedString.Key.foregroundColor: ThemeManager.currentTheme().generalTitleColor]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationController?.navigationBar.largeTitleTextAttributes = textAttributes
        navigationController?.navigationBar.backgroundColor = ThemeManager.currentTheme().barBackgroundColor
        
        tabBarController?.tabBar.barTintColor = ThemeManager.currentTheme().barBackgroundColor
        tabBarController?.tabBar.barStyle = ThemeManager.currentTheme().barStyle
        
        collectionView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        collectionView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        collectionView.reloadData()
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }
    
    lazy var diffableDataSource: UICollectionViewDiffableDataSource<ActivitySection, AnyHashable> = .init(collectionView: self.collectionView) { (collectionView, indexPath, object) -> UICollectionViewCell? in
        if let object = object as? ActivityType {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kActivityHeaderCell, for: indexPath) as! ActivityHeaderCell
            cell.intColor = (indexPath.item % 5)
            cell.activityType = object
            return cell
        } else if let object = object as? GroupItem {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kActivityTypeCell, for: indexPath) as! ActivityTypeCell
            cell.delegate = self
            if let places = self.favAct["places"], places.contains(object.venue?.id ?? "") {
                cell.heartButtonImage = "heart-filled"
            } else {
                cell.heartButtonImage = "heart"
            }
            cell.intColor = (indexPath.item % 5)
            cell.imageURL = self.sections[indexPath.section].image
            cell.fsVenue = object.venue
            return cell
        } else if let object = object as? FSVenue {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kActivityTypeCell, for: indexPath) as! ActivityTypeCell
            cell.delegate = self
            if let places = self.favAct["places"], places.contains(object.id) {
                cell.heartButtonImage = "heart-filled"
            } else {
                cell.heartButtonImage = "heart"
            }
            cell.intColor = (indexPath.item % 5)
            cell.imageURL = self.sections[indexPath.section].image
            cell.fsVenue = object
            return cell
        } else if let object = object as? Event {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kActivityTypeCell, for: indexPath) as! ActivityTypeCell
            cell.delegate = self
            if let events = self.favAct["events"], events.contains(object.id) {
                cell.heartButtonImage = "heart-filled"
            } else {
                cell.heartButtonImage = "heart"
            }
            cell.intColor = (indexPath.item % 5)
            cell.imageURL = self.sections[indexPath.section].image
            cell.event = object
            return cell
        } else if let object = object as? SygicPlace {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kActivityTypeCell, for: indexPath) as! ActivityTypeCell
            cell.delegate = self
            if let places = self.favAct["places"], places.contains(object.id) {
                cell.heartButtonImage = "heart-filled"
            } else {
                cell.heartButtonImage = "heart"
            }
            cell.intColor = (indexPath.item % 5)
            cell.imageURL = self.sections[indexPath.section].image
            cell.sygicPlace = object
            return cell
        } else if let object = object as? Workout {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kActivityTypeCell, for: indexPath) as! ActivityTypeCell
            cell.delegate = self
            if let workouts = self.favAct["workouts"], workouts.contains(object.identifier) {
                cell.heartButtonImage = "heart-filled"
            } else {
                cell.heartButtonImage = "heart"
            }
            cell.intColor = (indexPath.item % 5)
            cell.imageURL = self.sections[indexPath.section].image
            cell.workout = object
            return cell
        } else if let object = object as? Recipe {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kActivityTypeCell, for: indexPath) as! ActivityTypeCell
            cell.delegate = self
            if let recipes = self.favAct["recipes"], recipes.contains("\(object.id)") {
                cell.heartButtonImage = "heart-filled"
            } else {
                cell.heartButtonImage = "heart"
            }
            cell.intColor = (indexPath.item % 5)
            cell.imageURL = self.sections[indexPath.section].image
            cell.recipe = object
            return cell
        }
        return nil
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let object = diffableDataSource.itemIdentifier(for: indexPath)
        if let activityType = object as? ActivityType {
            let activityTypeName = activityType.rawValue
            switch activityTypeName {
            case "basic":
                print("basic")
                if let activity = self.umbrellaActivity {
                    let destination = ScheduleViewController()
                    destination.hidesBottomBarWhenPushed = true
                    destination.users = self.users
                    destination.filteredUsers = self.filteredUsers
                    destination.delegate = self
                    destination.startDateTime = Date(timeIntervalSince1970: activity.startDateTime as! TimeInterval)
                    destination.endDateTime = Date(timeIntervalSince1970: activity.endDateTime as! TimeInterval)
                    self.navigationController?.pushViewController(destination, animated: true)
                } else {
                    let destination = CreateActivityViewController()
                    destination.hidesBottomBarWhenPushed = true
                    destination.users = self.users
                    destination.filteredUsers = self.filteredUsers
                    destination.conversations = self.conversations
                    self.navigationController?.pushViewController(destination, animated: true)
                }
            case "flight":
                print("flight")
                let destination = FlightSearchViewController()
                destination.hidesBottomBarWhenPushed = true
                destination.users = self.users
                destination.filteredUsers = self.filteredUsers
                destination.conversations = self.conversations
                self.navigationController?.pushViewController(destination, animated: true)
            case "meal":
                print("meal")
            case "workout":
                print("workout")
            default:
                print("default")
            }
        } else if let recipe = object as? Recipe {
            print("meal \(recipe.title)")
            let destination = RecipeDetailViewController()
            destination.hidesBottomBarWhenPushed = true
            destination.favAct = favAct
            destination.recipe = recipe
            destination.users = self.users
            destination.filteredUsers = self.filteredUsers
            destination.conversations = self.conversations
            destination.activities = self.activities
            destination.conversation = self.conversation
            destination.schedule = self.schedule
            destination.umbrellaActivity = self.umbrellaActivity
            destination.delegate = self
            self.navigationController?.pushViewController(destination, animated: true)
        } else if let event = object as? Event {
            print("event \(String(describing: event.name))")
            let destination = EventDetailViewController()
            destination.hidesBottomBarWhenPushed = true
            destination.favAct = favAct
            destination.event = event
            destination.users = self.users
            destination.filteredUsers = self.filteredUsers
            destination.conversations = self.conversations
            destination.activities = self.activities
            destination.conversation = self.conversation
            destination.schedule = self.schedule
            destination.umbrellaActivity = self.umbrellaActivity
            destination.delegate = self
            self.navigationController?.pushViewController(destination, animated: true)
        } else if let workout = object as? Workout {
            print("workout \(String(describing: workout.title))")
            let destination = WorkoutDetailViewController()
            destination.hidesBottomBarWhenPushed = true
            destination.favAct = favAct
            destination.workout = workout
            destination.intColor = (indexPath.item % 5)
            destination.users = self.users
            destination.filteredUsers = self.filteredUsers
            destination.conversations = self.conversations
            destination.activities = self.activities
            destination.conversation = self.conversation
            destination.schedule = self.schedule
            destination.umbrellaActivity = self.umbrellaActivity
            destination.delegate = self
            self.navigationController?.pushViewController(destination, animated: true)
        } else if let attraction = object as? Attraction {
            print("attraction \(String(describing: attraction.name))")
            let destination = EventDetailViewController()
            destination.hidesBottomBarWhenPushed = true
            destination.favAct = favAct
            destination.attraction = attraction
            destination.users = self.users
            destination.filteredUsers = self.filteredUsers
            destination.conversations = self.conversations
            destination.activities = self.activities
            destination.conversation = self.conversation
            destination.schedule = self.schedule
            destination.umbrellaActivity = self.umbrellaActivity
            destination.delegate = self
            self.navigationController?.pushViewController(destination, animated: true)
        } else {
            print("neither meals or events")
        }
    }
    
    private func fetchData() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        activityIndicatorView.startAnimating()
        
        diffableDataSource.supplementaryViewProvider = .some({ (collectionView, kind, indexPath) -> UICollectionReusableView? in
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.kCompositionalHeader, for: indexPath) as! CompositionalHeader
            header.delegate = self
            let snapshot = self.diffableDataSource.snapshot()
            if let object = self.diffableDataSource.itemIdentifier(for: indexPath), let section = snapshot.sectionIdentifier(containingItem: object) {
                header.titleLabel.text = section.name
                if section == .custom {
                    header.subTitleLabel.isHidden = true
                } else {
                    header.subTitleLabel.isHidden = false
                }
            }
            
            return header
        })
        
        var snapshot = self.diffableDataSource.snapshot()
        
        let dispatchGroup = DispatchGroup()
        
        for section in sections {
            if let object = groups[section] {
                activityIndicatorView.stopAnimating()
                snapshot.appendSections([section])
                snapshot.appendItems(object, toSection: section)
                self.diffableDataSource.apply(snapshot)
                continue
            } else if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways {
                if section.type == "FSVenue" {
                    dispatchGroup.enter()
                    Service.shared.fetchFSExploreLatLong(limit: "30", offset: "", time: "", day: "", openNow: 0, sortByDistance: 0, sortByPopularity: 1, price: section.price, query: "", radius: "", city: "", stateCode: "", countryCode: "", categoryId: section.searchTerm, section: section.extras, lat: self.locationManager.location?.coordinate.latitude ?? 0.0, long: self.locationManager.location?.coordinate.longitude ?? 0.0) { (search, err) in
                        dispatchGroup.leave()
                        if let object = search?.response?.groups?[0].items {
                            self.groups[section] = object
                        } else {
                            self.sections.removeAll(where: {$0 == section})
                        }
                    }
                } else if section.type == "Event" {
                    dispatchGroup.enter()
                    Service.shared.fetchEventsSegmentLatLong(size: "30", id: "", keyword: "", attractionId: "", venueId: "", postalCode: "", radius: "", unit: "", startDateTime: "", endDateTime: "", city: "", stateCode: "", countryCode: "", classificationName: "", classificationId: "", lat: self.locationManager.location?.coordinate.latitude ?? 0.0, long: self.locationManager.location?.coordinate.longitude ?? 0.0) { (search, err) in
                        dispatchGroup.leave()
                        if let object = search?.embedded?.events {
                            self.groups[section] = object
                        } else {
                            self.sections.removeAll(where: {$0 == section})
                        }
                    }
                } else if section.type == "SygicPlace" {
                    dispatchGroup.enter()
                    Service.shared.fetchSygicPlacesLatLong(limit: "30", offset: "", query: "", categories: ["discovering", "sightseeing"], categories_not: [], parent_place_id: "", place_ids: "", tags: "", tags_not: "", prefer_unique: "", city: "", stateCode: "", countryCode: "", lat: self.locationManager.location?.coordinate.latitude ?? 0.0, long: self.locationManager.location?.coordinate.longitude ?? 0.0, radius: "1000") { (search, err) in
                        dispatchGroup.leave()
                        if let object = search?.data?.places {
                            self.groups[section] = object
                        } else {
                            self.sections.removeAll(where: {$0 == section})
                        }
                    }
                } else if section.type == "Workout" {
                    var workouts = [Workout]()
                    for workoutID in self.workoutIDs {
                        dispatchGroup.enter()
                        self.reference = Database.database().reference().child("workouts").child("workouts")
                        self.reference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                            if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                                if let workout = try? FirebaseDecoder().decode(Workout.self, from: workoutSnapshotValue) {
                                    workouts.append(workout)
                                    self.groups[section] = workouts
                                    dispatchGroup.leave()
                                }
                            }
                        })
                        { (error) in
                            print(error.localizedDescription)
                        }
                    }
                } else if section.type == "Recipe" {
                    dispatchGroup.enter()
                    Service.shared.fetchRecipesComplex(query: "", cuisine: [section.searchTerm], excludeCuisine: [""], diet: "", intolerances: [""], type: "") { (search, err) in
                        dispatchGroup.leave()
                        if let object = search?.recipes {
                            self.groups[section] = object
                        } else {
                            self.sections.removeAll(where: {$0 == section})
                        }
                    }
                }
            } else {
                if section.type == "FSVenue" {
                    dispatchGroup.enter()
                    Service.shared.fetchFSExplore(limit: "30", offset: "", time: "", day: "", openNow: 0, sortByDistance: 0, sortByPopularity: 1, price: section.price, query: "", radius: "", city: "", stateCode: "", countryCode: "", categoryId: section.searchTerm, section: section.extras) { (search, err) in
                        dispatchGroup.leave()
                        if let object = search?.response?.groups?[0].items {
                            self.groups[section] = object
                        } else {
                            self.sections.removeAll(where: {$0 == section})
                        }
                    }
                } else if section.type == "Event" {
                    dispatchGroup.enter()
                    Service.shared.fetchEventsSegment(size: "30", id: "", keyword: "", attractionId: "", venueId: "", postalCode: "", radius: "", unit: "", startDateTime: "", endDateTime: "", city: "", stateCode: "", countryCode: "", classificationName: "", classificationId: "") { (search, err) in
                        dispatchGroup.leave()
                        if let object = search?.embedded?.events {
                            self.groups[section] = object
                        } else {
                            self.sections.removeAll(where: {$0 == section})
                        }
                    }
                } else if section.type == "SygicPlace" {
                    dispatchGroup.enter()
                    Service.shared.fetchSygicPlaces(limit: "30", offset: "", query: "", categories: ["discovering", "sightseeing"], categories_not: [], parent_place_id: "", place_ids: "", tags: "", tags_not: "", prefer_unique: "", city: "", stateCode: "", countryCode: "", radius: "1000") { (search, err) in
                        dispatchGroup.leave()
                        if let object = search?.data?.places {
                            self.groups[section] = object
                        } else {
                            self.sections.removeAll(where: {$0 == section})
                        }
                    }
                } else if section.type == "Workout" {
                    var workouts = [Workout]()
                    for workoutID in self.workoutIDs {
                        dispatchGroup.enter()
                        self.reference = Database.database().reference().child("workouts").child("workouts")
                        self.reference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                            if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                                if let workout = try? FirebaseDecoder().decode(Workout.self, from: workoutSnapshotValue) {
                                    workouts.append(workout)
                                    self.groups[section] = workouts
                                    dispatchGroup.leave()
                                }
                            }
                        })
                        { (error) in
                            print(error.localizedDescription)
                        }
                    }
                } else if section.type == "Recipe" {
                    dispatchGroup.enter()
                    Service.shared.fetchRecipesComplex(query: "", cuisine: [section.searchTerm], excludeCuisine: [""], diet: "", intolerances: [""], type: "") { (search, err) in
                        dispatchGroup.leave()
                        if let object = search?.recipes {
                            self.groups[section] = object
                        } else {
                            self.sections.removeAll(where: {$0 == section})
                        }
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                if let object = self.groups[section] {
                    activityIndicatorView.stopAnimating()
                    snapshot.appendSections([section])
                    snapshot.appendItems(object, toSection: section)
                    self.diffableDataSource.apply(snapshot)
                }
            }
        }
    }
    
    func fetchFavAct() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        self.reference = Database.database().reference().child("user-fav-activities").child(currentUserID)
        self.reference.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists(), let favoriteActivitiesSnapshot = snapshot.value as? [String: [String]] {
                if !NSDictionary(dictionary: self.favAct).isEqual(to: favoriteActivitiesSnapshot) {
                    print("favAct")
                    self.favAct = favoriteActivitiesSnapshot
                    self.collectionView.reloadData()
                }
            } else {
                if !self.favAct.isEmpty {
                    self.favAct = [String: [String]]()
                    self.collectionView.reloadData()
                    print("snapshot does not exist")
                }
           }
          })
        { (error) in
            print(error.localizedDescription)
        }
    }
    
    func showActivityIndicator() {
        if let navController = self.navigationController {
            self.showSpinner(onView: navController.view)
        } else {
            self.showSpinner(onView: self.view)
        }
        self.navigationController?.view.isUserInteractionEnabled = false
    }
    
    func hideActivityIndicator() {
        self.navigationController?.view.isUserInteractionEnabled = true
        self.removeSpinner()
    }
    
    func getSelectedFalconUsers(forActivity activity: Activity, completion: @escaping ([User])->()) {
        guard let participantsIDs = activity.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        var selectedFalconUsers = [User]()
        let group = DispatchGroup()
        for id in participantsIDs {
            // Only if the current user is created this activity
            if activity.admin == currentUserID && id == currentUserID {
                continue
            }
            
            group.enter()
            let participantReference = Database.database().reference().child("users").child(id)
            participantReference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), var dictionary = snapshot.value as? [String: AnyObject] {
                    dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                    let user = User(dictionary: dictionary)
                    selectedFalconUsers.append(user)
                }
                group.leave()
            })
        }
        
        group.notify(queue: .main) {
            completion(selectedFalconUsers)
        }
    }
    
}

extension ActivityTypeViewController: CompositionalHeaderDelegate {
    func viewTapped(labelText: String) {
        switch labelText {
        case "Recipes":
            let destination = RecipeTypeViewController()
            destination.hidesBottomBarWhenPushed = true
            if let recipes = groups[.recipes] as? [Recipe], !recipes.isEmpty {
                destination.groups[.american] = recipes
            }
            destination.favAct = favAct
            destination.users = users
            destination.filteredUsers = filteredUsers
            destination.conversations = conversations
            destination.activities = activities
            destination.conversation = conversation
            destination.schedule = schedule
            destination.umbrellaActivity = umbrellaActivity
            destination.delegate = self
            navigationController?.pushViewController(destination, animated: true)
        case "Events":
            print("Event")
            let destination = EventTypeViewController()
            destination.hidesBottomBarWhenPushed = true
            destination.favAct = favAct
            destination.users = users
            destination.filteredUsers = filteredUsers
            destination.conversations = conversations
            destination.activities = activities
            destination.conversation = conversation
            destination.schedule = schedule
            destination.umbrellaActivity = umbrellaActivity
            destination.delegate = self
            navigationController?.pushViewController(destination, animated: true)
        case "Workouts":
            print("Workouts")
            let destination = WorkoutTypeViewController()
            destination.hidesBottomBarWhenPushed = true
            destination.favAct = favAct
            destination.users = users
            destination.filteredUsers = filteredUsers
            destination.conversations = conversations
            destination.activities = activities
            destination.conversation = conversation
            destination.schedule = schedule
            destination.umbrellaActivity = umbrellaActivity
            destination.delegate = self
            navigationController?.pushViewController(destination, animated: true)
        case "Attractions":
            print("Attractions")
            let destination = EventTypeViewController()
            destination.hidesBottomBarWhenPushed = true
            destination.favAct = favAct
            destination.users = users
            destination.filteredUsers = filteredUsers
            destination.conversations = conversations
            destination.activities = activities
            destination.conversation = conversation
            destination.schedule = schedule
            destination.umbrellaActivity = umbrellaActivity
            destination.delegate = self
            navigationController?.pushViewController(destination, animated: true)
        case "Food":
            print("Food")
            let destination = FoodTypeViewController()
            destination.hidesBottomBarWhenPushed = true
            destination.favAct = favAct
            destination.users = users
            destination.filteredUsers = filteredUsers
            destination.conversations = conversations
            destination.activities = activities
            destination.conversation = conversation
            destination.schedule = schedule
            destination.umbrellaActivity = umbrellaActivity
            destination.delegate = self
            navigationController?.pushViewController(destination, animated: true)
        default:
            print("Default")
        }
    }
}

extension ActivityTypeViewController: UpdateScheduleDelegate {
    func updateSchedule(schedule: Activity) {
        delegate?.updateSchedule(schedule: schedule)
    }
    func updateIngredients(recipe: Recipe?, recipeID: String?) {
        if let recipeID = recipeID {
            self.delegate?.updateIngredients(recipe: nil, recipeID: recipeID)
        } else if let recipe = recipe {
            self.delegate?.updateIngredients(recipe: recipe, recipeID: nil)
        }
    }
}

extension ActivityTypeViewController: ActivityTypeCellDelegate {
    func plusButtonTapped(type: Any) {
        print("plusButtonTapped")
        if schedule {
            let activityID = UUID().uuidString
            activity = Activity(dictionary: ["activityID": activityID as AnyObject])
        } else if !schedule {
            if let currentUserID = Auth.auth().currentUser?.uid {
                let activityID = Database.database().reference().child("user-activities").child(currentUserID).childByAutoId().key ?? ""
                activity = Activity(dictionary: ["activityID": activityID as AnyObject])
            }
        }
        if let recipe = type as? Recipe {
            activity.name = recipe.title
            activity.recipeID = "\(recipe.id)"
            activity.activityType = "recipe"
            if schedule, let umbrellaActivity = umbrellaActivity {
                if let startDate = umbrellaActivity.startDateTime {
                    startDateTime = Date(timeIntervalSince1970: startDate as! TimeInterval)
                    endDateTime = startDateTime!.addingTimeInterval(Double(recipe.readyInMinutes ?? 0) * 60)
                } else {
                    let original = Date()
                    let rounded = Date(timeIntervalSinceReferenceDate:
                        (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    let timezone = TimeZone.current
                    let seconds = TimeInterval(timezone.secondsFromGMT(for: Date()))
                    startDateTime = rounded.addingTimeInterval(seconds)
                    endDateTime = startDateTime!.addingTimeInterval(Double(recipe.readyInMinutes ?? 0) * 60)
                }
                if let localName = umbrellaActivity.locationName, localName != "locationName", let localAddress = umbrellaActivity.locationAddress {
                    activity.locationName = localName
                    activity.locationAddress = localAddress
                }
            } else if !schedule {
                let original = Date()
                let rounded = Date(timeIntervalSinceReferenceDate:
                    (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                let timezone = TimeZone.current
                let seconds = TimeInterval(timezone.secondsFromGMT(for: Date()))
                startDateTime = rounded.addingTimeInterval(seconds)
                endDateTime = startDateTime!.addingTimeInterval(Double(recipe.readyInMinutes ?? 0) * 60)
            }
            activity.allDay = false
            activity.startDateTime = NSNumber(value: Int((startDateTime!).timeIntervalSince1970))
            activity.endDateTime = NSNumber(value: Int((endDateTime!).timeIntervalSince1970))
        } else if let workout = type as? Workout {
            activity.name = workout.title
            activity.activityType = "workout"
            activity.workoutID = "\(workout.identifier)"
            if schedule, let umbrellaActivity = umbrellaActivity {
                if let startDate = umbrellaActivity.startDateTime {
                    startDateTime = Date(timeIntervalSince1970: startDate as! TimeInterval)
                    if let workoutDuration = workout.workoutDuration, let duration = Double(workoutDuration) {
                        endDateTime = startDateTime!.addingTimeInterval(duration * 60)
                    } else {
                        endDateTime = startDateTime
                    }
                } else {
                    let original = Date()
                    let rounded = Date(timeIntervalSinceReferenceDate:
                        (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    let timezone = TimeZone.current
                    let seconds = TimeInterval(timezone.secondsFromGMT(for: Date()))
                    startDateTime = rounded.addingTimeInterval(seconds)
                    if let workoutDuration = workout.workoutDuration, let duration = Double(workoutDuration) {
                        endDateTime = startDateTime!.addingTimeInterval(duration * 60)
                    } else {
                        endDateTime = startDateTime!
                    }
                }
                if let localName = umbrellaActivity.locationName, localName != "locationName", let localAddress = umbrellaActivity.locationAddress {
                    activity.locationName = localName
                    activity.locationAddress = localAddress
                }
            } else if !schedule {
                let original = Date()
                let rounded = Date(timeIntervalSinceReferenceDate:
                    (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                let timezone = TimeZone.current
                let seconds = TimeInterval(timezone.secondsFromGMT(for: Date()))
                startDateTime = rounded.addingTimeInterval(seconds)
                if let workoutDuration = workout.workoutDuration, let duration = Double(workoutDuration) {
                    endDateTime = startDateTime!.addingTimeInterval(duration * 60)
                } else {
                    endDateTime = startDateTime!
                }
            }
            activity.allDay = false
            activity.startDateTime = NSNumber(value: Int((startDateTime!).timeIntervalSince1970))
            activity.endDateTime = NSNumber(value: Int((endDateTime!).timeIntervalSince1970))
        } else if let event = type as? Event {
            activity.name = event.name
            activity.activityType = "event"
            activity.eventID = "\(event.id)"
            if schedule, let umbrellaActivity = umbrellaActivity {
                if let startDate = event.dates?.start?.dateTime, let date = startDate.toDate() {
                    startDateTime = date
                    endDateTime = date
                } else if let startDate = umbrellaActivity.startDateTime {
                    startDateTime = Date(timeIntervalSince1970: startDate as! TimeInterval)
                    endDateTime = startDateTime
                } else {
                    let original = Date()
                    let rounded = Date(timeIntervalSinceReferenceDate:
                        (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    let timezone = TimeZone.current
                    let seconds = TimeInterval(timezone.secondsFromGMT(for: Date()))
                    startDateTime = rounded.addingTimeInterval(seconds)
                    endDateTime = startDateTime
                }
            } else if !schedule {
                if let startDate = event.dates?.start?.dateTime, let date = startDate.toDate() {
                    startDateTime = date
                    endDateTime = date
                } else {
                    let original = Date()
                    let rounded = Date(timeIntervalSinceReferenceDate:
                        (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    let timezone = TimeZone.current
                    let seconds = TimeInterval(timezone.secondsFromGMT(for: Date()))
                    startDateTime = rounded.addingTimeInterval(seconds)
                    endDateTime = startDateTime
                }
            }
            activity.allDay = false
            activity.startDateTime = NSNumber(value: Int((startDateTime!).timeIntervalSince1970))
            activity.endDateTime = NSNumber(value: Int((endDateTime!).timeIntervalSince1970))
            if let locationName = event.embedded?.venues?[0].address?.line1, let latitude = event.embedded?.venues?[0].location?.latitude, let longitude = event.embedded?.venues?[0].location?.longitude {
                var newLocationName = locationName
                if newLocationName.contains("/") {
                    newLocationName = newLocationName.replacingOccurrences(of: "/", with: "")
                }
                if newLocationName.contains(".") {
                    newLocationName = newLocationName.replacingOccurrences(of: ".", with: "")
                }
                if newLocationName.contains("#") {
                    newLocationName = newLocationName.replacingOccurrences(of: "#", with: "")
                }
                if newLocationName.contains("$") {
                    newLocationName = newLocationName.replacingOccurrences(of: "$", with: "")
                }
                if newLocationName.contains("[") {
                    newLocationName = newLocationName.replacingOccurrences(of: "[", with: "")
                }
                if newLocationName.contains("]") {
                    newLocationName = newLocationName.replacingOccurrences(of: "]", with: "")
                }
                activity.locationName = newLocationName
                activity.locationAddress = [newLocationName: [Double(latitude)!, Double(longitude)!]]
            }
        } else if let attraction = type as? Attraction {
            activity.name = attraction.name
        } else if let place = type as? FSVenue {
            activity.name = place.name
            activity.activityType = "place"
            activity.placeID = "\(place.id)"
            if schedule, let umbrellaActivity = umbrellaActivity {
                if let startDate = umbrellaActivity.startDateTime {
                    startDateTime = Date(timeIntervalSince1970: startDate as! TimeInterval)
                    endDateTime = Date(timeIntervalSince1970: startDate as! TimeInterval)
                } else {
                    let original = Date()
                    let rounded = Date(timeIntervalSinceReferenceDate:
                        (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    let timezone = TimeZone.current
                    let seconds = TimeInterval(timezone.secondsFromGMT(for: Date()))
                    startDateTime = rounded.addingTimeInterval(seconds)
                    endDateTime = rounded.addingTimeInterval(seconds)
                }
            } else if !schedule {
                let original = Date()
                let rounded = Date(timeIntervalSinceReferenceDate:
                    (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                let timezone = TimeZone.current
                let seconds = TimeInterval(timezone.secondsFromGMT(for: Date()))
                startDateTime = rounded.addingTimeInterval(seconds)
                endDateTime = rounded.addingTimeInterval(seconds)
            }
            if let locationName = place.location?.address, let latitude = place.location?.lat, let longitude = place.location?.lng {
                var newLocationName = locationName
                if newLocationName.contains("/") {
                    newLocationName = newLocationName.replacingOccurrences(of: "/", with: "")
                }
                if newLocationName.contains(".") {
                    newLocationName = newLocationName.replacingOccurrences(of: ".", with: "")
                }
                if newLocationName.contains("#") {
                    newLocationName = newLocationName.replacingOccurrences(of: "#", with: "")
                }
                if newLocationName.contains("$") {
                    newLocationName = newLocationName.replacingOccurrences(of: "$", with: "")
                }
                if newLocationName.contains("[") {
                    newLocationName = newLocationName.replacingOccurrences(of: "[", with: "")
                }
                if newLocationName.contains("]") {
                    newLocationName = newLocationName.replacingOccurrences(of: "]", with: "")
                }
                activity.locationName = newLocationName
                activity.locationAddress = [newLocationName: [latitude, longitude]]
            }
            activity.allDay = false
            activity.startDateTime = NSNumber(value: Int((startDateTime!).timeIntervalSince1970))
            activity.endDateTime = NSNumber(value: Int((endDateTime!).timeIntervalSince1970))
        } else {
            return
        }
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if schedule, let _ = umbrellaActivity {
            alert.addAction(UIAlertAction(title: "Add to Schedule", style: .default, handler: { (_) in
                print("User click Approve button")
                self.delegate?.updateSchedule(schedule: self.activity)
                if let recipeID = self.activity.recipeID {
                    self.delegate?.updateIngredients(recipe: nil, recipeID: recipeID)
                }
                
                self.movingBackwards = false
                self.navigationController?.backToViewController(viewController: CreateActivityViewController.self)
            }))
            
        } else if !schedule {
            alert.addAction(UIAlertAction(title: "Create New Activity", style: .default, handler: { (_) in
                print("User click Approve button")
                // create new activity
                
                self.showActivityIndicator()
                let createActivity = ActivityActions(activity: self.activity, active: false, selectedFalconUsers: [])
                createActivity.createNewActivity()
                self.hideActivityIndicator()
                
                self.movingBackwards = false
                (self.tabBarController?.viewControllers![1] as? MasterActivityContainerController)?.changeToIndex(index: 2)
                self.tabBarController?.selectedIndex = 1
            }))
            
            alert.addAction(UIAlertAction(title: "Merge with Existing Activity", style: .default, handler: { (_) in
                
                // ChooseActivityTableViewController
                let destination = ChooseActivityTableViewController()
                let navController = UINavigationController(rootViewController: destination)
                destination.delegate = self
                destination.activity = self.activity
                destination.activities = self.activities
                destination.filteredActivities = self.activities
                self.present(navController, animated: true, completion: nil)
                
            }))
            
        }
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
    
    func shareButtonTapped(activityObject: ActivityObject) {
        print("shareButtonTapped")
        
        let alert = UIAlertController(title: "Share Activity", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Inside of Plot", style: .default, handler: { (_) in
            print("User click Approve button")
            let destination = ChooseChatTableViewController()
            let navController = UINavigationController(rootViewController: destination)
            destination.activityObject = activityObject
            destination.users = self.users
            destination.filteredUsers = self.filteredUsers
            destination.conversations = self.conversations
            destination.filteredConversations = self.conversations
            destination.filteredPinnedConversations = self.conversations
            self.present(navController, animated: true, completion: nil)
            
        }))
        
        alert.addAction(UIAlertAction(title: "Outside of Plot", style: .default, handler: { (_) in
            print("User click Edit button")
            // Fallback on earlier versions
            let shareText = "Hey! Download Plot on the App Store so I can share an activity with you."
            guard let url = URL(string: "https://apps.apple.com/us/app/plot-scheduling-app/id1473764067?ls=1")
                else { return }
            let shareContent: [Any] = [shareText, url]
            let activityController = UIActivityViewController(activityItems: shareContent,
                                                              applicationActivities: nil)
            self.present(activityController, animated: true, completion: nil)
            activityController.completionWithItemsHandler = { (activityType: UIActivity.ActivityType?, completed:
                Bool, arrayReturnedItems: [Any]?, error: Error?) in
                if completed {
                    print("share completed")
                    return
                } else {
                    print("cancel")
                }
                if let shareError = error {
                    print("error while sharing: \(shareError.localizedDescription)")
                }
            }
            
        }))
        
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
    
    func heartButtonTapped(type: Any) {
        print("heartButtonTapped")
        if let currentUserID = Auth.auth().currentUser?.uid {
            let databaseReference = Database.database().reference().child("user-fav-activities").child(currentUserID)
            if let recipe = type as? Recipe {
                print(recipe.title)
                databaseReference.child("recipes").observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists() {
                        var value = snapshot.value as! [String]
                        if value.contains("\(recipe.id)") {
                            if let index = value.firstIndex(of: "\(recipe.id)") {
                                value.remove(at: index)
                            }
                            databaseReference.updateChildValues(["recipes": value as NSArray])
                        } else {
                            value.append("\(recipe.id)")
                            databaseReference.updateChildValues(["recipes": value as NSArray])
                        }
                        self.favAct["recipes"] = value
                    } else {
                        self.favAct["recipes"] = ["\(recipe.id)"]
                        databaseReference.updateChildValues(["recipes": ["\(recipe.id)"]])
                    }
                })
            } else if let workout = type as? Workout {
                print(workout.title)
                databaseReference.child("workouts").observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists() {
                        var value = snapshot.value as! [String]
                        if value.contains("\(workout.identifier)") {
                            if let index = value.firstIndex(of: "\(workout.identifier)") {
                                value.remove(at: index)
                            }
                            databaseReference.updateChildValues(["workouts": value as NSArray])
                        } else {
                            value.append("\(workout.identifier)")
                            databaseReference.updateChildValues(["workouts": value as NSArray])
                        }
                        self.favAct["workouts"] = value
                    } else {
                        self.favAct["workouts"] = ["\(workout.identifier)"]
                        databaseReference.updateChildValues(["workouts": ["\(workout.identifier)"]])
                    }
                })
            } else if let event = type as? Event {
                print(event.name)
                databaseReference.child("events").observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists() {
                        var value = snapshot.value as! [String]
                        if value.contains("\(event.id)") {
                            if let index = value.firstIndex(of: "\(event.id)") {
                                value.remove(at: index)
                            }
                            databaseReference.updateChildValues(["events": value as NSArray])
                        } else {
                            value.append("\(event.id)")
                            databaseReference.updateChildValues(["events": value as NSArray])
                        }
                        self.favAct["events"] = value
                    } else {
                        self.favAct["events"] = ["\(event.id)"]
                        databaseReference.updateChildValues(["events": ["\(event.id)"]])
                    }
                })
            } else if let attraction = type as? Attraction {
                print(attraction.name)
                databaseReference.child("attractions").observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists() {
                        var value = snapshot.value as! [String]
                        if value.contains("\(attraction.id)") {
                            if let index = value.firstIndex(of: "\(attraction.id)") {
                                value.remove(at: index)
                            }
                            databaseReference.updateChildValues(["attractions": value as NSArray])
                        } else {
                            value.append("\(attraction.id)")
                            databaseReference.updateChildValues(["attractions": value as NSArray])
                        }
                        self.favAct["attractions"] = value
                    } else {
                        self.favAct["attractions"] = ["\(attraction.id)"]
                        databaseReference.updateChildValues(["attractions": ["\(attraction.id)"]])
                    }
                })
            } else if let place = type as? FSVenue {
                print(place.name)
                databaseReference.child("places").observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists() {
                        var value = snapshot.value as! [String]
                        if value.contains("\(place.id)") {
                            if let index = value.firstIndex(of: "\(place.id)") {
                                value.remove(at: index)
                            }
                            databaseReference.updateChildValues(["places": value as NSArray])
                        } else {
                            value.append("\(place.id)")
                            databaseReference.updateChildValues(["places": value as NSArray])
                        }
                        self.favAct["places"] = value
                    } else {
                        self.favAct["places"] = ["\(place.id)"]
                        databaseReference.updateChildValues(["places": ["\(place.id)"]])
                    }
                })
            }
        }
    }
}

extension ActivityTypeViewController: ChooseActivityDelegate {
    func chosenActivity(mergeActivity: Activity) {
        if let activity = activity {
            let dispatchGroup = DispatchGroup()
            if mergeActivity.recipeID != nil || mergeActivity.workoutID != nil || mergeActivity.eventID != nil {
                if let currentUserID = Auth.auth().currentUser?.uid {
                    let newActivityID = Database.database().reference().child("user-activities").child(currentUserID).childByAutoId().key ?? ""
                    let newActivity = mergeActivity.copy() as! Activity
                    newActivity.activityID = newActivityID
                    newActivity.recipeID = nil
                    newActivity.workoutID = nil
                    newActivity.eventID = nil
                    
                    mergeActivity.participantsIDs = newActivity.participantsIDs
                    activity.participantsIDs = newActivity.participantsIDs
                    
                    let scheduleList = [mergeActivity, activity]
                    newActivity.schedule = scheduleList
                    
                    self.showActivityIndicator()
                    
                    // need to delete merge activity
                    dispatchGroup.enter()
                    self.getSelectedFalconUsers(forActivity: mergeActivity) { (participants) in
                        let deleteActivity = ActivityActions(activity: mergeActivity, active: true, selectedFalconUsers: participants)
                        deleteActivity.deleteActivity()
                        dispatchGroup.leave()
                    }
                    
                    dispatchGroup.enter()
                    self.getSelectedFalconUsers(forActivity: newActivity) { (participants) in
                        let createActivity = ActivityActions(activity: newActivity, active: false, selectedFalconUsers: participants)
                        createActivity.createNewActivity()
                        dispatchGroup.leave()
                    }
                    self.hideActivityIndicator()
                }
            } else {
                if mergeActivity.schedule != nil {
                    var scheduleList = mergeActivity.schedule!
                    scheduleList.append(activity)
                    mergeActivity.schedule = scheduleList
                } else {
                    let scheduleList = [activity]
                    mergeActivity.schedule = scheduleList
                }
                
                dispatchGroup.enter()
                self.getSelectedFalconUsers(forActivity: mergeActivity) { (participants) in
                    print("\(participants)")
                    self.showActivityIndicator()
                    let createActivity = ActivityActions(activity: mergeActivity, active: true, selectedFalconUsers: participants)
                    createActivity.createNewActivity()
                    dispatchGroup.leave()
                    self.hideActivityIndicator()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                self.movingBackwards = false
                (self.tabBarController?.viewControllers![1] as? MasterActivityContainerController)?.changeToIndex(index: 2)
                self.tabBarController?.selectedIndex = 1
            }
        }
    }
}
