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
    
    weak var delegate : UpdateScheduleDelegate?
        
    fileprivate var reference: DatabaseReference!
        
    private let kActivityTypeCell = "ActivityTypeCell"
    private let headerId = "headerId"
    
    var sections: [String] = ["Food", "Nightlife", "Events", "Sightseeing", "Recreation", "Shopping", "Travel", "Workouts", "Recipes"]
    var attractionsString = [String]()
    var types: [ActivityType] = [.basic, .flight]
    var favAct = [String: [String]]()
    
    var recipes: [Recipe]?
    var workouts = [Workout]()
    var events: [Event]?
    var attractions: [Attraction]?
    var fsFoodItems: [GroupItem]?
    var fsRecreationItems: [GroupItem]?
    var fsNightLifeItems: [GroupItem]?
    var fsShoppingItems: [GroupItem]?
    var fsTravelItems: [GroupItem]?
    var sygicPlaces: [SygicPlace]?
    
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
        
    var groups = [Any]()
    
    var locationManager = CLLocationManager()
    
    let navigationItemActivityIndicator = NavigationItemActivityIndicator()
    
    init() {
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        collectionView.register(ActivityTypeCell.self, forCellWithReuseIdentifier: kActivityTypeCell)
        collectionView.register(ActivityHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerId)
                
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        
        addObservers()
                
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        managePresense()
        if groups.isEmpty {
            fetchData()
        }
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
    
    fileprivate func fetchData() {
        
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        // help you sync your data fetches together
        let dispatchGroup = DispatchGroup()
                    
        //Events

        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways {
            dispatchGroup.enter()
            Service.shared.fetchFSExploreLatLong(limit: "20", offset: "", time: "", day: "", openNow: 1, sortByDistance: 0, sortByPopularity: 1, price: [], query: "", radius: "", city: "", stateCode: "", countryCode: "", categoryId: "4d4b7105d754a06374d81259", section: "", lat: self.locationManager.location?.coordinate.latitude ?? 0.0, long: self.locationManager.location?.coordinate.longitude ?? 0.0) { (search, err) in
                self.fsFoodItems = search?.response?.groups
                dispatchGroup.leave()
                dispatchGroup.notify(queue: .main) {
                    if let group = self.fsFoodItems {
                        self.groups.append(group)
                    } else {
                        self.sections.removeAll{ $0 == "Food"}
                    }
                    self.collectionView.reloadData()
                    
                    dispatchGroup.enter()
                    Service.shared.fetchFSExploreLatLong(limit: "20", offset: "", time: "", day: "", openNow: 1, sortByDistance: 0, sortByPopularity: 1, price: [], query: "", radius: "", city: "", stateCode: "", countryCode: "", categoryId: "4d4b7105d754a06376d81259", section: "", lat: self.locationManager.location?.coordinate.latitude ?? 0.0, long: self.locationManager.location?.coordinate.longitude ?? 0.0) { (search, err) in
                        self.fsNightLifeItems = search?.response?.groups
                        dispatchGroup.leave()
                        dispatchGroup.notify(queue: .main) {
                            if let group = self.fsNightLifeItems {
                                self.groups.append(group)
                            } else {
                                self.sections.removeAll{ $0 == "Nightlife"}
                            }
                            self.collectionView.reloadData()
                            
                            dispatchGroup.enter()
                            Service.shared.fetchEventsSegmentLatLong(size: "50", id: "", keyword: "", attractionId: "", venueId: "", postalCode: "", radius: "", unit: "", startDateTime: "", endDateTime: "", city: "", stateCode: "", countryCode: "", classificationName: "", classificationId: "", lat: self.locationManager.location?.coordinate.latitude ?? 0.0, long: self.locationManager.location?.coordinate.longitude ?? 0.0) { (search, err) in
                                self.events = search?.embedded?.events
                                dispatchGroup.leave()
                                dispatchGroup.notify(queue: .main) {
                                    if let group = self.events {
                                        let finalEvents = sortEvents(events: group)
                                        self.groups.append(finalEvents)
                                    } else {
                                        self.sections.removeAll{ $0 == "Events"}
                                    }
                                    
                                    self.collectionView.reloadData()
                                    
                                    dispatchGroup.enter()
                                    Service.shared.fetchSygicPlacesLatLong(limit: "20", offset: "", query: "", categories: ["discovering", "sightseeing"], categories_not: [], parent_place_id: "", place_ids: "", tags: "", tags_not: "", prefer_unique: "", city: "", stateCode: "", countryCode: "", lat: self.locationManager.location?.coordinate.latitude ?? 0.0, long: self.locationManager.location?.coordinate.longitude ?? 0.0, radius: "100") { (search, err) in
                                        self.sygicPlaces = search?.data?.places
                                        dispatchGroup.leave()
                                        dispatchGroup.notify(queue: .main) {
                                            if let group = self.sygicPlaces {
                                                self.groups.append(group)
                                            } else {
                                                self.sections.removeAll{ $0 == "Events"}
                                            }
                                            
                                            self.collectionView.reloadData()
                                            
                                            dispatchGroup.enter()
                                            Service.shared.fetchFSExploreLatLong(limit: "20", offset: "", time: "", day: "", openNow: 1, sortByDistance: 0, sortByPopularity: 1, price: [], query: "", radius: "", city: "", stateCode: "", countryCode: "", categoryId: "4d4b7105d754a06377d81259", section: "", lat: self.locationManager.location?.coordinate.latitude ?? 0.0, long: self.locationManager.location?.coordinate.longitude ?? 0.0) { (search, err) in
                                                self.fsRecreationItems = search?.response?.groups
                                                dispatchGroup.leave()
                                                dispatchGroup.notify(queue: .main) {
                                                    if let group = self.fsRecreationItems {
                                                        self.groups.append(group)
                                                    } else {
                                                        self.sections.removeAll{ $0 == "Recreation"}
                                                    }
                                                    self.collectionView.reloadData()
                                                    
                                                    dispatchGroup.enter()
                                                    Service.shared.fetchFSExploreLatLong(limit: "20", offset: "", time: "", day: "", openNow: 1, sortByDistance: 0, sortByPopularity: 1, price: [], query: "", radius: "", city: "", stateCode: "", countryCode: "", categoryId: "4d4b7105d754a06378d81259", section: "", lat: self.locationManager.location?.coordinate.latitude ?? 0.0, long: self.locationManager.location?.coordinate.longitude ?? 0.0) { (search, err) in
                                                        self.fsShoppingItems = search?.response?.groups
                                                        dispatchGroup.leave()
                                                        dispatchGroup.notify(queue: .main) {
                                                            if let group = self.fsShoppingItems {
                                                                self.groups.append(group)
                                                            } else {
                                                                self.sections.removeAll{ $0 == "Shopping"}
                                                            }
                                                            self.collectionView.reloadData()
                                                            
                                                            dispatchGroup.enter()
                                                            Service.shared.fetchFSExploreLatLong(limit: "20", offset: "", time: "", day: "", openNow: 1, sortByDistance: 0, sortByPopularity: 1, price: [], query: "", radius: "", city: "", stateCode: "", countryCode: "", categoryId: "4d4b7105d754a06379d81259", section: "", lat: self.locationManager.location?.coordinate.latitude ?? 0.0, long: self.locationManager.location?.coordinate.longitude ?? 0.0) { (search, err) in
                                                                self.fsTravelItems = search?.response?.groups
                                                                dispatchGroup.leave()
                                                                dispatchGroup.notify(queue: .main) {
                                                                    if let group = self.fsTravelItems {
                                                                        self.groups.append(group)
                                                                    } else {
                                                                        self.sections.removeAll{ $0 == "Travel"}
                                                                    }
                                                                    self.collectionView.reloadData()
                                                                    
                                                                    for workoutID in self.workoutIDs {
                                                                        dispatchGroup.enter()
                                                                        self.reference = Database.database().reference().child("workouts").child("workouts")
                                                                        self.reference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                                                                            if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                                                                                if let workout = try? FirebaseDecoder().decode(Workout.self, from: workoutSnapshotValue) {
                                                                                    self.workouts.append(workout)
                                                                                    dispatchGroup.leave()
                                                                                }
                                                                            }
                                                                          })
                                                                        { (error) in
                                                                            print(error.localizedDescription)
                                                                        }
                                                                    }
                                                                    
                                                                    dispatchGroup.notify(queue: .main) {
                                                                        self.groups.append(self.workouts)
                                                                        self.collectionView.reloadData()
                                                                        
                                                                        dispatchGroup.enter()
                                                                        Service.shared.fetchRecipesComplex(query: "", cuisine: ["American"], excludeCuisine: [""], diet: "", intolerances: [""], type: "") { (search, err) in
                                                                            self.recipes = search?.recipes
                                                                            dispatchGroup.leave()
                                                                            
                                                                            dispatchGroup.notify(queue: .main) {
                                                                                if let group = self.recipes {
                                                                                    self.groups.append(group)
                                                                                    self.recipes = group
                                                                                } else {
                                                                                    self.sections.removeAll{ $0 == "Recipes"}
                                                                                }
                                                                                
                                                                                self.collectionView.reloadData()
                                                                                
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            dispatchGroup.enter()
            Service.shared.fetchFSExplore(limit: "20", offset: "", time: "", day: "", openNow: 1, sortByDistance: 0, sortByPopularity: 1, price: [], query: "", radius: "", city: "", stateCode: "", countryCode: "", categoryId: "4d4b7105d754a06374d81259", section: "") { (search, err) in
                self.fsFoodItems = search?.response?.groups
                dispatchGroup.leave()
                dispatchGroup.notify(queue: .main) {
                    if let group = self.fsFoodItems {
                        self.groups.append(group)
                    } else {
                        self.sections.removeAll{ $0 == "Food"}
                    }
                    self.collectionView.reloadData()
                    
                    dispatchGroup.enter()
                    Service.shared.fetchFSExplore(limit: "20", offset: "", time: "", day: "", openNow: 1, sortByDistance: 0, sortByPopularity: 1, price: [], query: "", radius: "", city: "", stateCode: "", countryCode: "", categoryId: "4d4b7105d754a06376d81259", section: "") { (search, err) in
                        self.fsNightLifeItems = search?.response?.groups
                        dispatchGroup.leave()
                        dispatchGroup.notify(queue: .main) {
                            if let group = self.fsNightLifeItems {
                                self.groups.append(group)
                            } else {
                                self.sections.removeAll{ $0 == "Nightlife"}
                            }
                            self.collectionView.reloadData()
                            
                            dispatchGroup.enter()
                            Service.shared.fetchEventsSegment(size: "50", id: "", keyword: "", attractionId: "", venueId: "", postalCode: "", radius: "", unit: "", startDateTime: "", endDateTime: "", city: "", stateCode: "", countryCode: "", classificationName: "", classificationId: "") { (search, err) in
                                self.events = search?.embedded?.events
                                dispatchGroup.leave()
                                dispatchGroup.notify(queue: .main) {
                                    if let group = self.events {
                                        let finalEvents = sortEvents(events: group)
                                        self.groups.append(finalEvents)
                                    } else {
                                        self.sections.removeAll{ $0 == "Events"}
                                    }
                                    
                                    self.collectionView.reloadData()
                                    
                                    dispatchGroup.enter()
                                    Service.shared.fetchSygicPlaces(limit: "20", offset: "", query: "", categories: ["discovering", "sightseeing"], categories_not: [], parent_place_id: "", place_ids: "", tags: "", tags_not: "", prefer_unique: "", city: "", stateCode: "", countryCode: "", radius: "100") { (search, err) in
                                        self.sygicPlaces = search?.data?.places
                                        dispatchGroup.leave()
                                        dispatchGroup.notify(queue: .main) {
                                            if let group = self.sygicPlaces {
                                                self.groups.append(group)
                                            } else {
                                                self.sections.removeAll{ $0 == "Events"}
                                            }
                                            
                                            self.collectionView.reloadData()
                                            
                                            dispatchGroup.enter()
                                            Service.shared.fetchFSExplore(limit: "20", offset: "", time: "", day: "", openNow: 1, sortByDistance: 0, sortByPopularity: 1, price: [], query: "", radius: "", city: "", stateCode: "", countryCode: "", categoryId: "4d4b7105d754a06377d81259", section: "") { (search, err) in
                                                self.fsRecreationItems = search?.response?.groups
                                                dispatchGroup.leave()
                                                dispatchGroup.notify(queue: .main) {
                                                    if let group = self.fsRecreationItems {
                                                        self.groups.append(group)
                                                    } else {
                                                        self.sections.removeAll{ $0 == "Recreation"}
                                                    }
                                                    self.collectionView.reloadData()
                                                    
                                                    dispatchGroup.enter()
                                                    Service.shared.fetchFSExplore(limit: "20", offset: "", time: "", day: "", openNow: 1, sortByDistance: 0, sortByPopularity: 1, price: [], query: "", radius: "", city: "", stateCode: "", countryCode: "", categoryId: "4d4b7105d754a06378d81259", section: "") { (search, err) in
                                                        self.fsShoppingItems = search?.response?.groups
                                                        dispatchGroup.leave()
                                                        dispatchGroup.notify(queue: .main) {
                                                            if let group = self.fsShoppingItems {
                                                                self.groups.append(group)
                                                            } else {
                                                                self.sections.removeAll{ $0 == "Shopping"}
                                                            }
                                                            self.collectionView.reloadData()
                                                            
                                                            dispatchGroup.enter()
                                                            Service.shared.fetchFSExplore(limit: "20", offset: "", time: "", day: "", openNow: 1, sortByDistance: 0, sortByPopularity: 1, price: [], query: "", radius: "", city: "", stateCode: "", countryCode: "", categoryId: "4d4b7105d754a06379d81259", section: "") { (search, err) in
                                                                self.fsTravelItems = search?.response?.groups
                                                                dispatchGroup.leave()
                                                                dispatchGroup.notify(queue: .main) {
                                                                    if let group = self.fsTravelItems {
                                                                        self.groups.append(group)
                                                                    } else {
                                                                        self.sections.removeAll{ $0 == "Travel"}
                                                                    }
                                                                    self.collectionView.reloadData()
                                                                    
                                                                    for workoutID in self.workoutIDs {
                                                                        dispatchGroup.enter()
                                                                        self.reference = Database.database().reference().child("workouts").child("workouts")
                                                                        self.reference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                                                                            if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                                                                                if let workout = try? FirebaseDecoder().decode(Workout.self, from: workoutSnapshotValue) {
                                                                                    self.workouts.append(workout)
                                                                                    dispatchGroup.leave()
                                                                                }
                                                                            }
                                                                          })
                                                                        { (error) in
                                                                            print(error.localizedDescription)
                                                                        }
                                                                    }
                                                                    
                                                                    dispatchGroup.notify(queue: .main) {
                                                                        self.groups.append(self.workouts)
                                                                        self.collectionView.reloadData()
                                                                        
                                                                        dispatchGroup.enter()
                                                                        Service.shared.fetchRecipesComplex(query: "", cuisine: ["American"], excludeCuisine: [""], diet: "", intolerances: [""], type: "") { (search, err) in
                                                                            self.recipes = search?.recipes
                                                                            dispatchGroup.leave()
                                                                            
                                                                            dispatchGroup.notify(queue: .main) {
                                                                                if let group = self.recipes {
                                                                                    self.groups.append(group)
                                                                                    self.recipes = group
                                                                                } else {
                                                                                    self.sections.removeAll{ $0 == "Recipes"}
                                                                                }
                                                                                
                                                                                self.collectionView.reloadData()
                                                                                
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
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
                        if let activity = self!.umbrellaActivity {
                            let destination = ScheduleViewController()
                            destination.hidesBottomBarWhenPushed = true
                            destination.users = self!.users
                            destination.filteredUsers = self!.filteredUsers
                            destination.delegate = self!
                            destination.startDateTime = Date(timeIntervalSince1970: activity.startDateTime as! TimeInterval)
                            destination.endDateTime = Date(timeIntervalSince1970: activity.endDateTime as! TimeInterval)
                            self?.navigationController?.pushViewController(destination, animated: true)
                        } else {
                            let destination = CreateActivityViewController()
                            destination.hidesBottomBarWhenPushed = true
                            destination.users = self!.users
                            destination.filteredUsers = self!.filteredUsers
                            destination.conversations = self!.conversations
                            self?.navigationController?.pushViewController(destination, animated: true)
                        }
                    case "flight":
                        print("flight")
                        let destination = FlightSearchViewController()
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
        cell.horizontalController.conversations = conversations
        cell.horizontalController.activities = activities
        cell.horizontalController.users = users
        cell.horizontalController.filteredUsers = filteredUsers
        cell.horizontalController.favAct = favAct
        cell.horizontalController.conversation = conversation
        cell.horizontalController.schedule = schedule
        cell.horizontalController.umbrellaActivity = umbrellaActivity
        cell.delegate = self
        cell.titleLabel.text = sections[indexPath.item]

        if indexPath.item < groups.count {
            let cellData = groups[indexPath.item]
            if let recipes = cellData as? [Recipe] {
                cell.horizontalController.recipes = recipes
                cell.horizontalController.attractions = nil
                cell.horizontalController.events = nil
                cell.horizontalController.workouts = nil
                cell.horizontalController.attractions = nil
                cell.horizontalController.groupItems = nil
                cell.horizontalController.sygicPlaces = nil
            } else if let events = cellData as? [Event] {
                cell.horizontalController.events = events
                cell.horizontalController.attractions = nil
                cell.horizontalController.recipes = nil
                cell.horizontalController.workouts = nil
                cell.horizontalController.groupItems = nil
                cell.horizontalController.sygicPlaces = nil
            } else if let workouts = cellData as? [Workout] {
                cell.horizontalController.workouts = workouts
                cell.horizontalController.attractions = nil
                cell.horizontalController.recipes = nil
                cell.horizontalController.events = nil
                cell.horizontalController.groupItems = nil
                cell.horizontalController.sygicPlaces = nil
            } else if let attractions = cellData as? [Attraction] {
                cell.horizontalController.attractions = attractions
                cell.horizontalController.workouts = nil
                cell.horizontalController.recipes = nil
                cell.horizontalController.events = nil
                cell.horizontalController.groupItems = nil
                cell.horizontalController.sygicPlaces = nil
            } else if let groupItems = cellData as? [GroupItem] {
                cell.horizontalController.attractions = nil
                cell.horizontalController.workouts = nil
                cell.horizontalController.recipes = nil
                cell.horizontalController.events = nil
                cell.horizontalController.groupItems = groupItems
                cell.horizontalController.sygicPlaces = nil
            } else if let sygicPlaces = cellData as? [SygicPlace] {
                cell.horizontalController.attractions = nil
                cell.horizontalController.workouts = nil
                cell.horizontalController.recipes = nil
                cell.horizontalController.events = nil
                cell.horizontalController.groupItems = nil
                cell.horizontalController.sygicPlaces = sygicPlaces
            }
            else {
                cell.horizontalController.cellData = cellData
            }
            cell.horizontalController.collectionView.reloadData()
            cell.horizontalController.didSelectHandler = { [weak self] cellData, favAct in
                                
                if let recipe = cellData as? Recipe {
                    print("meal \(recipe.title)")
                    let destination = MealDetailViewController()
                    destination.hidesBottomBarWhenPushed = true
                    destination.favAct = favAct
                    destination.recipe = recipe
                    destination.users = self!.users
                    destination.filteredUsers = self!.filteredUsers
                    destination.conversations = self!.conversations
                    destination.activities = self!.activities
                    destination.conversation = self!.conversation
                    destination.schedule = self!.schedule
                    destination.umbrellaActivity = self!.umbrellaActivity
                    destination.delegate = self!
                    self?.navigationController?.pushViewController(destination, animated: true)
                } else if let event = cellData as? Event {
                    print("event \(String(describing: event.name))")
                    let destination = EventDetailViewController()
                    destination.hidesBottomBarWhenPushed = true
                    destination.favAct = favAct
                    destination.event = event
                    destination.users = self!.users
                    destination.filteredUsers = self!.filteredUsers
                    destination.conversations = self!.conversations
                    destination.activities = self!.activities
                    destination.conversation = self!.conversation
                    destination.schedule = self!.schedule
                    destination.umbrellaActivity = self!.umbrellaActivity
                    destination.delegate = self!
                    self?.navigationController?.pushViewController(destination, animated: true)
                } else if let workout = cellData as? Workout {
                    print("workout \(String(describing: workout.title))")
                    let destination = WorkoutDetailViewController()
                    destination.hidesBottomBarWhenPushed = true
                    destination.favAct = favAct
                    destination.workout = workout
                    if let index = self!.workoutIDs.firstIndex(of: workout.identifier) {
                        destination.intColor = (index % 5)
                    }
                    destination.users = self!.users
                    destination.filteredUsers = self!.filteredUsers
                    destination.conversations = self!.conversations
                    destination.activities = self!.activities
                    destination.conversation = self!.conversation
                    destination.schedule = self!.schedule
                    destination.umbrellaActivity = self!.umbrellaActivity
                    destination.delegate = self!
                    self?.navigationController?.pushViewController(destination, animated: true)
                } else if let attraction = cellData as? Attraction {
                    print("attraction \(String(describing: attraction.name))")
                    let destination = EventDetailViewController()
                    destination.hidesBottomBarWhenPushed = true
                    destination.favAct = favAct
                    destination.attraction = attraction
                    destination.users = self!.users
                    destination.filteredUsers = self!.filteredUsers
                    destination.conversations = self!.conversations
                    destination.activities = self!.activities
                    destination.conversation = self!.conversation
                    destination.schedule = self!.schedule
                    destination.umbrellaActivity = self!.umbrellaActivity
                    destination.delegate = self!
                    self?.navigationController?.pushViewController(destination, animated: true)
                }
                else {
                    print("neither meals or events")
                }
            }
            cell.horizontalController.removeControllerHandler = { [weak self] type, activity in
                if type == "activity" {
                    self!.movingBackwards = false
                    (self!.tabBarController?.viewControllers![1] as? MasterActivityContainerController)?.changeToIndex(index: 2)
                    self!.tabBarController?.selectedIndex = 1
                } else if type == "schedule" {
                    self!.movingBackwards = false
                    self!.updateSchedule(schedule: activity)
                    if let recipeID = activity.recipeID {
                        self!.updateIngredients(recipe: nil, recipeID: recipeID)
                    }
                    self!.navigationController?.backToViewController(viewController: CreateActivityViewController.self)
                }
            }
            cell.horizontalController.favActHandler = { [weak self] favAct in
                self!.favAct = favAct
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
    
    func fetchFavAct() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        self.reference = Database.database().reference().child("user-fav-activities").child(currentUserID)
        self.reference.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists(), let favoriteActivitiesSnapshot = snapshot.value as? [String: [String]] {
                print("snapshot exists")
                print(self.favAct)
                print(favoriteActivitiesSnapshot)
                if !NSDictionary(dictionary: self.favAct).isEqual(to: favoriteActivitiesSnapshot) {
                    let updateFavoriteActivitiesSnapshot = favoriteActivitiesSnapshot.minus(dict: self.favAct)
                    let updateFavAct = self.favAct.minus(dict: favoriteActivitiesSnapshot)
                    print(updateFavAct)
                    print(updateFavoriteActivitiesSnapshot)
                    self.favAct = favoriteActivitiesSnapshot
                    for (_, values) in updateFavoriteActivitiesSnapshot {
                        for value in values {
                            print(value)
                            if let _ = self.recipes?.firstIndex(where: {"\($0.id)" == value}) {
                                let indexPath = IndexPath(row: 0, section: 0)
                                print(indexPath)
                                self.collectionView.reloadItems(at: [indexPath])
                            } else if let _ = self.workouts.firstIndex(where: {"\($0.identifier)" == value}) {
                                let indexPath = IndexPath(row: 1, section: 0)
                                print(indexPath)
                                self.collectionView.reloadItems(at: [indexPath])
                            } else if let _ = self.events?.firstIndex(where: {"\($0.id)" == value}) {
                                let indexPath = IndexPath(row: 2, section: 0)
                                print(indexPath)
                                self.collectionView.reloadItems(at: [indexPath])
                            }
                        }
                    }
                    for (_, values) in updateFavAct {
                        for value in values {
                            print(value)
                            if let _ = self.recipes?.firstIndex(where: {"\($0.id)" == value}) {
                                let indexPath = IndexPath(row: 0, section: 0)
                                print(indexPath)
                                self.collectionView.reloadItems(at: [indexPath])
                            } else if let _ = self.workouts.firstIndex(where: {"\($0.identifier)" == value}) {
                                let indexPath = IndexPath(row: 1, section: 0)
                                print(indexPath)
                                self.collectionView.reloadItems(at: [indexPath])
                            } else if let _ = self.events?.firstIndex(where: {"\($0.id)" == value}) {
                                let indexPath = IndexPath(row: 2, section: 0)
                                print(indexPath)
                                self.collectionView.reloadItems(at: [indexPath])
                            }
                        }
                    }
                }
             } else {
                print("snapshot does not exist")
                print(self.favAct)
                if !self.favAct.isEmpty {
                    let updateFavAct = self.favAct
                    print(updateFavAct)
                    self.favAct = [String: [String]]()
                    for (_, values) in updateFavAct {
                        for value in values {
                            print(value)
                            if let _ = self.recipes?.firstIndex(where: {"\($0.id)" == value}) {
                                let indexPath = IndexPath(row: 0, section: 0)
                                print(indexPath)
                                self.collectionView.reloadItems(at: [indexPath])
                            } else if let _ = self.workouts.firstIndex(where: {"\($0.identifier)" == value}) {
                                let indexPath = IndexPath(row: 1, section: 0)
                                print(indexPath)
                                self.collectionView.reloadItems(at: [indexPath])
                            } else if let _ = self.events?.firstIndex(where: {"\($0.id)" == value}) {
                                let indexPath = IndexPath(row: 2, section: 0)
                                print(indexPath)
                                self.collectionView.reloadItems(at: [indexPath])
                            }
                        }
                    }
                }
            }
          })
        { (error) in
            print(error.localizedDescription)
        }
        
    }
  
}

extension ActivityTypeViewController: ActivityTypeCellDelegate {
    func viewTapped(labelText: String) {
        switch labelText {
        case "Recipes":
            let destination = MealTypeViewController()
            destination.hidesBottomBarWhenPushed = true
            if let recipes = self.recipes, !recipes.isEmpty {
                destination.groups.append(recipes)
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
