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

class ActivityTypeViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, CLLocationManagerDelegate {
    
    weak var delegate : UpdateActivityDelegate?
    
    fileprivate var reference: DatabaseReference!
    
    private let kCompositionalHeader = "CompositionalHeader"
    private let kActivityTypeCell = "ActivityTypeCell"
    private let kActivityHeaderCell = "ActivityHeaderCell"
    
    var attractionsString = [String]()
    var customTypes: [CustomType] = [.event]
    var favAct = [String: [String]]()
    
    var sections: [SectionType] = [.custom, .food, .nightlife, .events, .sightseeing, .recreation, .shopping, .workout, .recipes]
    var groups = [SectionType: [AnyHashable]]()
    
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
    var listList = [ListContainer]()
    
    var activity: Activity!
    var activeList: Bool = false
    var listType: String?
    var activityType: String!
    
    var startDateTime: Date?
    var endDateTime: Date?
    
    var locationManager = CLLocationManager()
    var lat: Double?
    var lon: Double?
    
    var networkController = NetworkController()
    
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
                    .init(layoutSize: .init(widthDimension: .fractionalWidth(0.92), heightDimension: .absolute(30)), elementKind: kind, alignment: .topLeading)
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
        
        let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(0.92), heightDimension: .absolute(175)), subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPaging
        section.contentInsets.leading = 16
        
        let kind = UICollectionView.elementKindSectionHeader
        section.boundarySupplementaryItems = [
            .init(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(30)), elementKind: kind, alignment: .topLeading)
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
        
        
        let mapBarButton = UIBarButtonItem(image: UIImage(named: "map"), style: .plain, target: self, action: #selector(goToMap))
        let doneBarButton = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(updateLocal))
        navigationItem.rightBarButtonItems = [mapBarButton, doneBarButton]
        
        extendedLayoutIncludesOpaqueBars = true
        definesPresentationContext = true
        edgesForExtendedLayout = UIRectEdge.top
        view.backgroundColor = .systemGroupedBackground
        
        collectionView.indicatorStyle = .default
        collectionView.backgroundColor = .systemGroupedBackground
        
        collectionView.register(CompositionalHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: kCompositionalHeader)
        collectionView.register(ActivityHeaderCell.self, forCellWithReuseIdentifier: kActivityHeaderCell)
        collectionView.register(ActivityTypeCell.self, forCellWithReuseIdentifier: kActivityTypeCell)
                        
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways {
            lat = self.locationManager.location?.coordinate.latitude
            lon = self.locationManager.location?.coordinate.longitude
        } else {
            requestUserLocation()
        }
        
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
        
        if movingBackwards && navigationController?.visibleViewController is EventViewController {
            let activity = Activity(dictionary: ["activityID": UUID().uuidString as AnyObject])
            delegate?.updateActivity(activity: activity)
        }
        
    }
    
    fileprivate func managePresense() {
        if currentReachabilityStatus == .notReachable {
            navigationItemActivityIndicator.showActivityIndicator(for: navigationItem, with: .connecting,
                                                                  activityPriority: .high,
                                                                  color: .label)
        }
        
        let connectedReference = Database.database().reference(withPath: ".info/connected")
        connectedReference.observe(.value, with: { (snapshot) in
            
            if self.currentReachabilityStatus != .notReachable {
                self.navigationItemActivityIndicator.hideActivityIndicator(for: self.navigationItem, activityPriority: .crazy)
            } else {
                self.navigationItemActivityIndicator.showActivityIndicator(for: self.navigationItem, with: .noInternet, activityPriority: .crazy, color: .label)
            }
        })
    }
    
    fileprivate func requestUserLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse:
            print("Received authorization of user location")
            // request for where the user actually is
            locationManager.startUpdatingLocation()
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            
        default:
            print("Failed to authorize")
        }
    }
    
    @objc fileprivate func goToMap() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWithClose(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        let destination = MapViewController()
        var locationSections = [SectionType]()
        var locations = [SectionType: AnyHashable]()
        for section in sections {
            if section.type == "FSVenue" || section.type == "Event" {
                locationSections.append(section)
                locations[section] = groups[section]
            }
        }
        destination.sections = locationSections
        destination.locations = locations
        destination.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(destination, animated: true)
        
    }
    
    @objc fileprivate func updateLocal() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWithClose(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        let destination = LocationFinderTableViewController()
        destination.delegate = self
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    lazy var diffableDataSource: UICollectionViewDiffableDataSource<SectionType, AnyHashable> = .init(collectionView: self.collectionView) { (collectionView, indexPath, object) -> UICollectionViewCell? in
        if let object = object as? CustomType {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kActivityHeaderCell, for: indexPath) as! ActivityHeaderCell
            cell.intColor = (indexPath.item % 5)
            cell.activityType = object
            return cell
        } else if let object = object as? GroupItem {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kActivityTypeCell, for: indexPath) as! ActivityTypeCell
            cell.delegate = self
            if let places = self.favAct["places"], places.contains(object.venue?.id ?? "") {
                cell.bookmarkButtonImage = "bookmark-filled"
            } else {
                cell.bookmarkButtonImage = "bookmark"
            }
            cell.intColor = (indexPath.item % 5)
            cell.imageURL = self.sections[indexPath.section].image
            cell.groupItem = object
            return cell
        } else if let object = object as? FSVenue {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kActivityTypeCell, for: indexPath) as! ActivityTypeCell
            cell.delegate = self
            if let places = self.favAct["places"], places.contains(object.id) {
                cell.bookmarkButtonImage = "bookmark-filled"
            } else {
                cell.bookmarkButtonImage = "bookmark"
            }
            cell.intColor = (indexPath.item % 5)
            cell.imageURL = self.sections[indexPath.section].image
            cell.fsVenue = object
            return cell
        } else if let object = object as? TicketMasterEvent {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kActivityTypeCell, for: indexPath) as! ActivityTypeCell
            cell.delegate = self
            if let events = self.favAct["events"], events.contains(object.id) {
                cell.bookmarkButtonImage = "bookmark-filled"
            } else {
                cell.bookmarkButtonImage = "bookmark"
            }
            cell.intColor = (indexPath.item % 5)
            cell.imageURL = self.sections[indexPath.section].image
            cell.event = object
            return cell
        } else if let object = object as? SygicPlace {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kActivityTypeCell, for: indexPath) as! ActivityTypeCell
            cell.delegate = self
            if let places = self.favAct["places"], places.contains(object.id) {
                cell.bookmarkButtonImage = "bookmark-filled"
            } else {
                cell.bookmarkButtonImage = "bookmark"
            }
            cell.intColor = (indexPath.item % 5)
            cell.imageURL = self.sections[indexPath.section].image
            cell.sygicPlace = object
            return cell
        } else if let object = object as? PreBuiltWorkout {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kActivityTypeCell, for: indexPath) as! ActivityTypeCell
            cell.delegate = self
            if let workouts = self.favAct["workouts"], workouts.contains(object.identifier) {
                cell.bookmarkButtonImage = "bookmark-filled"
            } else {
                cell.bookmarkButtonImage = "bookmark"
            }
            cell.intColor = (indexPath.item % 5)
            cell.imageURL = self.sections[indexPath.section].image
            cell.workout = object
            return cell
        } else if let object = object as? Recipe {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kActivityTypeCell, for: indexPath) as! ActivityTypeCell
            cell.delegate = self
            if let recipes = self.favAct["recipes"], recipes.contains("\(object.id)") {
                cell.bookmarkButtonImage = "bookmark-filled"
            } else {
                cell.bookmarkButtonImage = "bookmark"
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
//        let snapshot = self.diffableDataSource.snapshot()
//        let section = snapshot.sectionIdentifier(containingItem: object!)
        if let activityType = object as? CustomType {
            let activityTypeName = activityType.rawValue
            switch activityTypeName {
            case "basic":
                print("basic")
                if let _ = self.umbrellaActivity {
                    let destination = ScheduleViewController()
                    destination.hidesBottomBarWhenPushed = true
                    destination.users = self.users
                    destination.filteredUsers = self.filteredUsers
                    destination.delegate = self
                    self.navigationController?.pushViewController(destination, animated: true)
                } else {
                    let destination = EventViewController(networkController: networkController)
                    destination.hidesBottomBarWhenPushed = true
                    self.navigationController?.pushViewController(destination, animated: true)
                }
            case "meal":
                let destination = MealViewController(networkController: networkController)
                destination.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(destination, animated: true)
            case "workout":
                let destination = WorkoutViewController(networkController: networkController)
                destination.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(destination, animated: true)
            default:
                print("default")
            }
        }
    }
    
    private func fetchData() {
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
        var snapshot = self.diffableDataSource.snapshot()
        snapshot.deleteAllItems()
        self.diffableDataSource.apply(snapshot)
                        
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
        
        activityIndicatorView.startAnimating()
                
        let dispatchGroup = DispatchGroup()
        
        for section in sections {
            if let object = groups[section] {
                snapshot.appendSections([section])
                snapshot.appendItems(object, toSection: section)
                self.diffableDataSource.apply(snapshot)
                continue
            } else if let lat = lat, let lon = lon {
                if section.type == "FSVenue" {
                    dispatchGroup.enter()
                    Service.shared.fetchFSExploreLatLong(limit: "30", offset: "", time: "", day: "", openNow: 0, sortByDistance: 0, sortByPopularity: 1, price: section.price, query: "", radius: "", city: "", stateCode: "", countryCode: "", categoryId: section.searchTerm, section: section.extras, lat: lat, long: lon) { (search, err) in
                        if let object = search?.response?.groups?[0].items, !object.isEmpty {
                            self.groups[section] = object
                        } else {
                            self.sections.removeAll(where: {$0 == section})
                        }
                        dispatchGroup.leave()
                    }
                } else if section.type == "Event" {
                    dispatchGroup.enter()
                    Service.shared.fetchEventsSegmentLatLong(size: "30", id: "", keyword: "", attractionId: "", venueId: "", postalCode: "", radius: "", unit: "", startDateTime: "", endDateTime: "", city: "", stateCode: "", countryCode: "", classificationName: "", classificationId: "", lat: lat, long: lon) { (search, err) in
                        if let object = search?.embedded?.events, !object.isEmpty {
                            self.groups[section] = object
                        } else {
                            self.sections.removeAll(where: {$0 == section})
                        }
                        dispatchGroup.leave()
                    }
                } else if section.type == "SygicPlace" {
                    dispatchGroup.enter()
                    Service.shared.fetchSygicPlacesLatLong(limit: "30", offset: "", query: "", categories: ["discovering", "sightseeing"], categories_not: [], parent_place_id: "", place_ids: "", tags: "", tags_not: "", prefer_unique: "", city: "", stateCode: "", countryCode: "", lat: lat, long: lon, radius: "1000") { (search, err) in
                        if let object = search?.data?.places, !object.isEmpty {
                            self.groups[section] = object
                        } else {
                            self.sections.removeAll(where: {$0 == section})
                        }
                        dispatchGroup.leave()
                    }
                } else if section.type == "Workout" {
                    var workouts = [PreBuiltWorkout]()
                    for workoutID in self.workoutIDs {
                        dispatchGroup.enter()
                        self.reference = Database.database().reference().child("workouts").child("workouts")
                        self.reference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                            if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                                if let workout = try? FirebaseDecoder().decode(PreBuiltWorkout.self, from: workoutSnapshotValue) {
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
                        if let object = search?.recipes, !object.isEmpty {
                            self.groups[section] = object
                        } else {
                            self.sections.removeAll(where: {$0 == section})
                        }
                        dispatchGroup.leave()
                    }
                }
            } else {
                if section.type == "FSVenue" {
                    dispatchGroup.enter()
                    Service.shared.fetchFSExplore(limit: "30", offset: "", time: "", day: "", openNow: 0, sortByDistance: 0, sortByPopularity: 1, price: section.price, query: "", radius: "", city: "", stateCode: "", countryCode: "", categoryId: section.searchTerm, section: section.extras) { (search, err) in
                        if let object = search?.response?.groups?[0].items, !object.isEmpty {
                            self.groups[section] = object
                        } else {
                            self.sections.removeAll(where: {$0 == section})
                        }
                        dispatchGroup.leave()
                    }
                } else if section.type == "Event" {
                    dispatchGroup.enter()
                    Service.shared.fetchEventsSegment(size: "30", id: "", keyword: "", attractionId: "", venueId: "", postalCode: "", radius: "", unit: "", startDateTime: "", endDateTime: "", city: "", stateCode: "", countryCode: "", classificationName: "", classificationId: "") { (search, err) in
                        if let object = search?.embedded?.events, !object.isEmpty {
                            self.groups[section] = object
                        } else {
                            self.sections.removeAll(where: {$0 == section})
                        }
                        dispatchGroup.leave()
                    }
                } else if section.type == "SygicPlace" {
                    dispatchGroup.enter()
                    Service.shared.fetchSygicPlaces(limit: "30", offset: "", query: "", categories: ["discovering", "sightseeing"], categories_not: [], parent_place_id: "", place_ids: "", tags: "", tags_not: "", prefer_unique: "", city: "", stateCode: "", countryCode: "", radius: "1000") { (search, err) in
                        if let object = search?.data?.places, !object.isEmpty {
                            self.groups[section] = object
                        } else {
                            self.sections.removeAll(where: {$0 == section})
                        }
                        dispatchGroup.leave()
                    }
                } else if section.type == "Workout" {
                    var workouts = [PreBuiltWorkout]()
                    for workoutID in self.workoutIDs {
                        dispatchGroup.enter()
                        self.reference = Database.database().reference().child("workouts").child("workouts")
                        self.reference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                            if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                                if let workout = try? FirebaseDecoder().decode(PreBuiltWorkout.self, from: workoutSnapshotValue) {
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
                        if let object = search?.recipes, !object.isEmpty {
                            self.groups[section] = object
                        } else {
                            self.sections.removeAll(where: {$0 == section})
                        }
                        dispatchGroup.leave()
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
        
        self.reference = Database.database().reference().child(userFavActivitiesEntity).child(currentUserID)
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
        
    }
}

extension ActivityTypeViewController: UpdateActivityDelegate {
    func updateActivity(activity: Activity) {
        delegate?.updateActivity(activity: activity)
    }
}

extension ActivityTypeViewController: ActivityTypeCellDelegate {
    func plusButtonTapped(type: AnyHashable) {
        let snapshot = self.diffableDataSource.snapshot()
        let _ = snapshot.sectionIdentifier(containingItem: type)
        if activeList {
            self.movingBackwards = false
            if let object = type as? Recipe {
                var updatedObject = object
                updatedObject.title = updatedObject.title.removeCharacters()
            } else if let object = type as? TicketMasterEvent {
                var updatedObject = object
                updatedObject.name = updatedObject.name.removeCharacters()
            } else if let object = type as? PreBuiltWorkout {
                var updatedObject = object
                updatedObject.title = updatedObject.title.removeCharacters()
            } else if let object = type as? FSVenue {
                var updatedObject = object
                updatedObject.name = updatedObject.name.removeCharacters()
            } else if let groupItem = type as? GroupItem, let object = groupItem.venue {
                var updatedObject = object
                updatedObject.name = updatedObject.name.removeCharacters()
            }
            self.actAddAlert()
            self.removeActAddAlert()
            return
        }
        
        if schedule {
            let activityID = UUID().uuidString
            activity = Activity(dictionary: ["activityID": activityID as AnyObject])
        } else if !schedule {
            if let currentUserID = Auth.auth().currentUser?.uid {
                let activityID = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key ?? ""
                activity = Activity(dictionary: ["activityID": activityID as AnyObject])
            }
        } else {
            return
        }
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if schedule, let _ = umbrellaActivity {
            alert.addAction(UIAlertAction(title: "Add to Schedule", style: .default, handler: { (_) in
                print("User click Approve button")
                self.movingBackwards = false
                self.delegate?.updateActivity(activity: self.activity)
                self.actAddAlert()
                self.removeActAddAlert()
            }))
            
        } else if !schedule {
            alert.addAction(UIAlertAction(title: "Create New Activity", style: .default, handler: { (_) in
                print("User click Approve button")
                // create new activity
                
                self.showActivityIndicator()
                let createActivity = ActivityActions(activity: self.activity, active: false, selectedFalconUsers: [])
                createActivity.createNewActivity(updateDirectAssociation: true)
                self.hideActivityIndicator()
                
                self.movingBackwards = false
//                (self.tabBarController?.viewControllers![1] as? MasterActivityContainerController)?.changeToIndex(index: 2)
                self.tabBarController?.selectedIndex = 1
            }))
            
            alert.addAction(UIAlertAction(title: "Add to Existing Activity", style: .default, handler: { (_) in
                
                // ChooseEventTableViewController
                let destination = ChooseEventTableViewController(networkController: self.networkController)
                let navController = UINavigationController(rootViewController: destination)
                destination.delegate = self
                destination.event = self.activity
                destination.events = self.activities
                destination.filteredEvents = self.activities
                self.present(navController, animated: true, completion: nil)
                
            }))
            
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
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
        
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
    
    func bookmarkButtonTapped(type: Any) {
        print("bookmarkButtonTapped")
        if let currentUserID = Auth.auth().currentUser?.uid {
            let databaseReference = Database.database().reference().child(userFavActivitiesEntity).child(currentUserID)
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
            } else if let workout = type as? PreBuiltWorkout {
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
            } else if let event = type as? TicketMasterEvent {
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
            } else if let attraction = type as? TicketMasterAttraction {
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
    
    func mapButtonTapped(type: AnyHashable) {
        let snapshot = self.diffableDataSource.snapshot()
        let section = snapshot.sectionIdentifier(containingItem: type)
                
        if let section = section {
            let destination = MapViewController()
            destination.sections = [section]
            destination.locations = [section: [type]]
            destination.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(destination, animated: true)

        }
    }
}

extension ActivityTypeViewController: ChooseActivityDelegate {
    func chosenActivity(mergeActivity: Activity) {
//        if let activity = activity {
//            let dispatchGroup = DispatchGroup()
//                if mergeActivity.schedule != nil {
//                    var scheduleList = mergeActivity.schedule!
//                    scheduleList.append(activity)
//                    mergeActivity.schedule = scheduleList
//                } else {
//                    let scheduleList = [activity]
//                    mergeActivity.schedule = scheduleList
//                }
//
//            dispatchGroup.enter()
//            self.getSelectedFalconUsers(forActivity: mergeActivity) { (participants) in
//                self.showActivityIndicator()
//                let createActivity = ActivityActions(activity: mergeActivity, active: true, selectedFalconUsers: participants)
//                createActivity.createNewActivity(updateDirectAssociation: true)
//                self.hideActivityIndicator()
//                dispatchGroup.leave()
//            }
//
//            dispatchGroup.notify(queue: .main) {
//               self.actAddAlert()
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
//                    self.removeActAddAlert()
//                })
//            }
//        }
    }
}

extension ActivityTypeViewController: UpdateLocationDelegate {
    func updateLocation(locationName: String, locationAddress: [String : [Double]], zipcode: String, city: String, state: String, country: String) {
        for (_, value) in locationAddress {
            lat = value[0]
            lon = value[1]
            groups = [SectionType: [AnyHashable]]()
            groups[.custom] = customTypes
            fetchData()
        }
    }
}
