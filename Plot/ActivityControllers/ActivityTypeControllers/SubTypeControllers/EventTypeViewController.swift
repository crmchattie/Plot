//
//  EventTypeViewController.swift
//  Plot
//
//  Created by Cory McHattie on 3/8/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import MapKit
import Eureka

class EventTypeViewController: ActivitySubTypeViewController, UISearchBarDelegate {
    
    var groups = [[Event]]()
    var searchActivities = [Event]()
    
    private let musicSegmentID = "KZFzniwnSyZfZ7v7nJ"
    private let sportsSegmentID = "KZFzniwnSyZfZ7v7nE"
    private let artstheatreSegmentID = "KZFzniwnSyZfZ7v7na"

    var filters: [filter] = [.eventType, .eventStartDate, .eventEndDate, .location]
    var filterDictionary = [String: [String]]()
    var sections: [String] = ["Music", "Sports", "Shows"]
    var attractions = [String]()
    
    var locationManager = CLLocationManager()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Events"

        let doneBarButton = UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(filter))
        navigationItem.rightBarButtonItem = doneBarButton

        setupSearchBar()
        
        fetchData()
        
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        
    }
    
    fileprivate func setupSearchBar() {
        definesPresentationContext = true
        navigationItem.searchController = self.searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
    }
        
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print(searchText)
        
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { (_) in
            self.complexSearch(query: searchText.lowercased(), eventType: self.filterDictionary["eventType"]?[0] ?? "", eventStartDate: self.filterDictionary["eventStartDate"]?[0] ?? "", eventEndDate: self.filterDictionary["eventEndDate"]?[0] ?? "", zipcode: self.filterDictionary["zipcode"]?[0] ?? "", city: self.filterDictionary["city"]?[0] ?? "", state: self.filterDictionary["state"]?[0] ?? "", country: self.filterDictionary["country"]?[0] ?? "", favorites: self.filterDictionary["favorites"]?[0] ?? "")
        })
    }
    
    func complexSearch(query: String, eventType: String, eventStartDate: String, eventEndDate: String, zipcode: String, city: String, state: String, country: String, favorites: String) {
        print("query \(query), eventType \(eventType), eventStartDate \(eventStartDate), eventEndDate \(eventEndDate), zipcode \(zipcode), city \(city), state \(state), country \(country), favorites \(favorites)")
        
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }

        self.searchActivities = [Event]()
        showGroups = false
        self.headerheight = view.frame.height
        self.cellheight = 0
        self.collectionView.reloadData()

        if let navController = self.navigationController {
            self.showSpinner(onView: navController.view)
        } else {
            self.showSpinner(onView: self.view)
        }

        let dispatchGroup = DispatchGroup()
        
        if favorites == "true" {
            if let events = self.favAct["events"] {
                for event in events {
                    if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways {
                        dispatchGroup.enter()
                        Service.shared.fetchEventsSegmentLatLong(size: "50", id: event, keyword: query, attractionId: "", venueId: "", postalCode: zipcode, radius: "", unit: "", startDateTime: eventStartDate, endDateTime: eventEndDate, city: city, stateCode: state, countryCode: country, classificationName: eventType, classificationId: "", lat: self.locationManager.location?.coordinate.latitude ?? 0.0, long: self.locationManager.location?.coordinate.longitude ?? 0.0) { (search, err) in
                            self.removeSpinner()
                            dispatchGroup.leave()
                            if let events = search?.embedded?.events {
                                self.searchActivities = sortEvents(events: events)
                                dispatchGroup.notify(queue: .main) {
                                    self.checkIfThereAnyActivities()
                                }
                            }
                        }
                    } else {
                        dispatchGroup.enter()
                        Service.shared.fetchEventsSegment(size: "50", id: event, keyword: query, attractionId: "", venueId: "", postalCode: zipcode, radius: "", unit: "", startDateTime: eventStartDate, endDateTime: eventEndDate, city: city, stateCode: state, countryCode: "", classificationName: eventType, classificationId: "") { (search, err) in
                            self.removeSpinner()
                            dispatchGroup.leave()
                            if let events = search?.embedded?.events {
                                self.searchActivities = sortEvents(events: events)
                                dispatchGroup.notify(queue: .main) {
                                    self.checkIfThereAnyActivities()
                                }
                            }
                        }
                    }
                }
                self.removeSpinner()
                self.checkIfThereAnyActivities()
            } else {
                self.removeSpinner()
                self.checkIfThereAnyActivities()
            }
        } else {
            if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways {
                dispatchGroup.enter()
                Service.shared.fetchEventsSegmentLatLong(size: "50", id: "", keyword: query, attractionId: "", venueId: "", postalCode: zipcode, radius: "", unit: "", startDateTime: eventStartDate, endDateTime: eventEndDate, city: city, stateCode: state, countryCode: country, classificationName: eventType, classificationId: "", lat: self.locationManager.location?.coordinate.latitude ?? 0.0, long: self.locationManager.location?.coordinate.longitude ?? 0.0) { (search, err) in
                    self.removeSpinner()
                    dispatchGroup.leave()
                    if let events = search?.embedded?.events {
                        self.searchActivities = sortEvents(events: events)
                        print("added events")
                        print(self.searchActivities)
                        dispatchGroup.notify(queue: .main) {
                            self.checkIfThereAnyActivities()
                        }
                    }
                }
            } else {
                dispatchGroup.enter()
                Service.shared.fetchEventsSegment(size: "50", id: "", keyword: query, attractionId: "", venueId: "", postalCode: zipcode, radius: "", unit: "", startDateTime: eventStartDate, endDateTime: eventEndDate, city: city, stateCode: state, countryCode: "", classificationName: eventType, classificationId: "") { (search, err) in
                    self.removeSpinner()
                    dispatchGroup.leave()
                    if let events = search?.embedded?.events {
                        self.searchActivities = sortEvents(events: events)
                        print(self.searchActivities)
                        print("added events")
                        dispatchGroup.notify(queue: .main) {
                            print("checking for events")
                            self.checkIfThereAnyActivities()
                        }
                    }
                }
            }
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActivities = [Event]()
        showGroups = true
        headerheight = 0
        cellheight = 405
        self.checkIfThereAnyActivities()
    }
    
    fileprivate func fetchData() {
        
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
                
        headerheight = 0
        cellheight = 405
            
        var musicEvents: [Event]?
        var sportsEvents: [Event]?
        var arttheatreEvents: [Event]?
        
        // help you sync your data fetches together
        let dispatchGroup = DispatchGroup()
        
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways {
                dispatchGroup.enter()
                Service.shared.fetchEventsSegmentLatLong(size: "50", id: "", keyword: "", attractionId: "", venueId: "", postalCode: "", radius: "", unit: "", startDateTime: "", endDateTime: "", city: "", stateCode: "", countryCode: "", classificationName: "", classificationId: self.musicSegmentID, lat: self.locationManager.location?.coordinate.latitude ?? 0.0, long: self.locationManager.location?.coordinate.longitude ?? 0.0) { (search, err) in
                    musicEvents = search?.embedded?.events
                    dispatchGroup.leave()
                    dispatchGroup.notify(queue: .main) {
                        if let group = musicEvents {
//                            var finalEvents = [Event]()
//                            for event in group {
//                                print(event.name!)
//                                if let attractions = event.embedded?.attractions, let attraction = attractions[0].id {
//                                    if !self.attractions.contains(attraction) {
//                                        print("attraction")
//                                        self.attractions.append(attraction)
//                                        finalEvents.append(event)
//                                    }
//                                } else {
//                                    finalEvents.append(event)
//                                }
//                            }
//                            finalEvents = sortEvents(events: finalEvents)
                            let finalEvents = sortEvents(events: group)
                            self.groups.append(finalEvents)
                        } else {
                            self.sections.removeAll{ $0 == "Music"}
                        }
                        
                        self.collectionView.reloadData()
                        dispatchGroup.enter()
                        Service.shared.fetchEventsSegmentLatLong(size: "50", id: "", keyword: "", attractionId: "", venueId: "", postalCode: "", radius: "", unit: "", startDateTime: "", endDateTime: "", city: "", stateCode: "", countryCode: "", classificationName: "", classificationId: self.sportsSegmentID, lat: self.locationManager.location?.coordinate.latitude ?? 0.0, long: self.locationManager.location?.coordinate.longitude ?? 0.0) { (search, err) in
                            sportsEvents = search?.embedded?.events
                            dispatchGroup.leave()
                    
                            dispatchGroup.notify(queue: .main) {
                                self.removeSpinner()
                                if let group = sportsEvents {
//                                    var finalEvents = [Event]()
//                                    for event in group {
//                                        print(event.name!)
//                                        if let attractions = event.embedded?.attractions, let attraction = attractions[0].id {
//                                            if !self.attractions.contains(attraction) {
//                                                print("attraction")
//                                                self.attractions.append(attraction)
//                                                finalEvents.append(event)
//                                            }
//                                        } else {
//                                            finalEvents.append(event)
//                                        }
//                                    }
//                                    finalEvents = sortEvents(events: finalEvents)
                                    let finalEvents = sortEvents(events: group)
                                    self.groups.append(finalEvents)
                                } else {
                                    self.sections.removeAll{ $0 == "Sports"}
                                }
                                self.collectionView.reloadData()
                                dispatchGroup.enter()
                                Service.shared.fetchEventsSegmentLatLong(size: "50", id: "", keyword: "", attractionId: "", venueId: "", postalCode: "", radius: "", unit: "", startDateTime: "", endDateTime: "", city: "", stateCode: "", countryCode: "", classificationName: "", classificationId: self.artstheatreSegmentID, lat: self.locationManager.location?.coordinate.latitude ?? 0.0, long: self.locationManager.location?.coordinate.longitude ?? 0.0) { (search, err) in
                                    arttheatreEvents = search?.embedded?.events
                                    dispatchGroup.leave()
                                    
                                    dispatchGroup.notify(queue: .main) {
                                        self.removeSpinner()
                                        if let group = arttheatreEvents {
//                                            var finalEvents = [Event]()
//                                            for event in group {
//                                                print(event.name!)
//                                                if let attractions = event.embedded?.attractions, let attraction = attractions[0].id {
//                                                    if !self.attractions.contains(attraction) {
//                                                        print("attraction")
//                                                        self.attractions.append(attraction)
//                                                        finalEvents.append(event)
//                                                    }
//                                                } else {
//                                                    finalEvents.append(event)
//                                                }
//                                            }
//                                            finalEvents = sortEvents(events: finalEvents)
                                            let finalEvents = sortEvents(events: group)
                                            self.groups.append(finalEvents)
                                        } else {
                                            self.sections.removeAll{ $0 == "Arts & Theatre"}
                                        }
                                    
                                        self.collectionView.reloadData()
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                dispatchGroup.enter()
                Service.shared.fetchEventsSegment(size: "50", id: "", keyword: "", attractionId: "", venueId: "", postalCode: "", radius: "", unit: "", startDateTime: "", endDateTime: "", city: "", stateCode: "", countryCode: "", classificationName: "", classificationId: self.musicSegmentID) { (search, err) in
                    musicEvents = search?.embedded?.events
                    dispatchGroup.leave()
                    dispatchGroup.notify(queue: .main) {
                        if let group = musicEvents {
//                            var finalEvents = [Event]()
//                            for event in group {
//                                print(event.name!)
//                                if let attractions = event.embedded?.attractions, let attraction = attractions[0].id {
//                                    if !self.attractions.contains(attraction) {
//                                        print("attraction")
//                                        self.attractions.append(attraction)
//                                        finalEvents.append(event)
//                                    }
//                                } else {
//                                    finalEvents.append(event)
//                                }
//                            }
//                            finalEvents = sortEvents(events: finalEvents)
                            let finalEvents = sortEvents(events: group)
                            self.groups.append(finalEvents)
                        } else {
                            self.sections.removeAll{ $0 == "Music"}
                        }
        
                        self.collectionView.reloadData()
                            
                        dispatchGroup.enter()
                        Service.shared.fetchEventsSegment(size: "50", id: "", keyword: "", attractionId: "", venueId: "", postalCode: "", radius: "", unit: "", startDateTime: "", endDateTime: "", city: "", stateCode: "", countryCode: "", classificationName: "", classificationId: self.sportsSegmentID) { (search, err) in
                            sportsEvents = search?.embedded?.events
                            dispatchGroup.leave()
                            
                            dispatchGroup.notify(queue: .main) {
                                if let group = sportsEvents {
//                                    var finalEvents = [Event]()
//                                    for event in group {
//                                        print(event.name!)
//                                        if let attractions = event.embedded?.attractions, let attraction = attractions[0].id {
//                                            if !self.attractions.contains(attraction) {
//                                                print("attraction")
//                                                self.attractions.append(attraction)
//                                                finalEvents.append(event)
//                                            }
//                                        } else {
//                                            finalEvents.append(event)
//                                        }
//                                    }
//                                    finalEvents = sortEvents(events: finalEvents)
                                    let finalEvents = sortEvents(events: group)
                                    self.groups.append(finalEvents)
                                } else {
                                    self.sections.removeAll{ $0 == "Sports"}
                                }
                            
                                self.collectionView.reloadData()
                                dispatchGroup.enter()
                                Service.shared.fetchEventsSegment(size: "50", id: "", keyword: "", attractionId: "", venueId: "", postalCode: "", radius: "", unit: "", startDateTime: "", endDateTime: "", city: "", stateCode: "", countryCode: "", classificationName: "", classificationId: self.artstheatreSegmentID) { (search, err) in
                                    arttheatreEvents = search?.embedded?.events
                                    dispatchGroup.leave()
                                    
                                    dispatchGroup.notify(queue: .main) {
                                        if let group = arttheatreEvents {
//                                            var finalEvents = [Event]()
//                                            for event in group {
//                                                print(event.name!)
//                                                if let attractions = event.embedded?.attractions, let attraction = attractions[0].id {
//                                                    if !self.attractions.contains(attraction) {
//                                                        print("attraction")
//                                                        self.attractions.append(attraction)
//                                                        finalEvents.append(event)
//                                                    }
//                                                } else {
//                                                    finalEvents.append(event)
//                                                }
//                                            }
//                                            finalEvents = sortEvents(events: finalEvents)
                                            let finalEvents = sortEvents(events: group)
                                            self.groups.append(finalEvents)
                                        } else {
                                            self.sections.removeAll{ $0 == "Arts & Theatre"}
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
    
    
    // MARK: UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if showGroups {
            return sections.count
        } else {
            return 0
        }
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
        cell.arrowView.isHidden = true
        cell.delegate = self
        if showGroups {
            cell.titleLabel.text = sections[indexPath.item]
            if indexPath.item < groups.count {
                let events = groups[indexPath.item]
                cell.horizontalController.events = events
                cell.horizontalController.collectionView.reloadData()
                cell.horizontalController.didSelectHandler = { [weak self] event, favAct in
                    if let event = event as? Event {
                        print("event \(String(describing: event.name))")
                        let destination = EventDetailViewController()
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
                    }
                }
                cell.horizontalController.removeControllerHandler = { [weak self] type in
                    if type == "activity" {
                        self!.navigationController?.backToViewController(viewController: ActivityViewController.self)
                    } else if type == "schedule" {
                        self!.navigationController?.backToViewController(viewController: CreateActivityViewController.self)
                    }
                }
                cell.horizontalController.favActHandler = { [weak self] favAct in
                    print("fav Act \(favAct)")
                    self!.favAct = favAct
                }
            }
        }
        return cell
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: cellheight)
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerId, for: indexPath) as! SearchHeader
        let events = searchActivities
        header.verticalController.favAct = favAct
        header.verticalController.events = events
        header.verticalController.conversations = conversations
        header.verticalController.activities = activities
        header.verticalController.users = users
        header.verticalController.filteredUsers = filteredUsers
        header.verticalController.favAct = favAct
        header.verticalController.conversation = conversation
        header.verticalController.schedule = schedule
        header.verticalController.umbrellaActivity = umbrellaActivity
        header.verticalController.collectionView.reloadData()
        header.verticalController.didSelectHandler = { [weak self] event, favAct in
            if let event = event as? Event {
                print("event \(String(describing: event.name))")
                let destination = EventDetailViewController()
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
            }
        }
        header.verticalController.removeControllerHandler = { [weak self] type in
            if type == "activity" {
                self!.navigationController?.backToViewController(viewController: ActivityViewController.self)
            } else if type == "schedule" {
                self!.navigationController?.backToViewController(viewController: CreateActivityViewController.self)
            }
        }
        header.verticalController.favActHandler = { [weak self] favAct in
            print("fav Act \(favAct)")
            self!.favAct = favAct
        }
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return .init(width: view.frame.width, height: headerheight)
    }
    
    func checkIfThereAnyActivities() {
        if searchActivities.count > 0 || showGroups {
            viewPlaceholder.remove(from: view, priority: .medium)
        } else {
            viewPlaceholder.add(for: view, title: .emptyEvents, subtitle: .emptyRecipesEvents, priority: .medium, position: .top)
        }
        collectionView?.reloadData()
    }
    
    @objc func filter() {
        let destination = FilterViewController()
        let navigationViewController = UINavigationController(rootViewController: destination)
        destination.delegate = self
        destination.filters = filters
        destination.filterDictionary = filterDictionary
        self.present(navigationViewController, animated: true, completion: nil)
    }

}

extension EventTypeViewController: ActivityTypeCellDelegate {
    func viewTapped(labelText: String) {
        print(labelText)
    }
}

extension EventTypeViewController: UpdateFilter {
    func updateFilter(filterDictionary : [String: [String]]) {
        print("filterDictionary \(filterDictionary)")
        if !filterDictionary.values.isEmpty {
            showGroups = false
            self.filterDictionary = filterDictionary
            complexSearch(query: "", eventType: filterDictionary["eventType"]?[0] ?? "", eventStartDate: filterDictionary["eventStartDate"]?[0] ?? "", eventEndDate: filterDictionary["eventEndDate"]?[0] ?? "", zipcode: filterDictionary["zipcode"]?[0] ?? "", city: filterDictionary["city"]?[0] ?? "", state: filterDictionary["state"]?[0] ?? "", country: self.filterDictionary["country"]?[0] ?? "", favorites: self.filterDictionary["favorites"]?[0] ?? "")
        } else {
            searchActivities = [Event]()
            self.filterDictionary = filterDictionary
            showGroups = true
            headerheight = 0
            cellheight = 397
            checkIfThereAnyActivities()
        }
    }
        
}
