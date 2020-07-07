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
    
    var sections: [ActivitySection] = [.music, .sports, .artstheatre, .family, .film, .miscellaneous]
    var groups = [ActivitySection: [Event]]()
    var searchActivities = [Event]()
    
    private let musicSegmentID = "KZFzniwnSyZfZ7v7nJ"
    private let sportsSegmentID = "KZFzniwnSyZfZ7v7nE"
    private let artstheatreSegmentID = "KZFzniwnSyZfZ7v7na"

    var filters: [filter] = [.eventType, .eventStartDate, .eventEndDate, .location]
    var filterDictionary = [String: [String]]()
    
    var attractions = [String]()
    
    var locationManager = CLLocationManager()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Events"

        let doneBarButton = UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(filter))
        navigationItem.rightBarButtonItem = doneBarButton

        searchController.searchBar.delegate = self
                
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        
        fetchData()
        
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
        
        var snapshot = diffableDataSource.snapshot()
        snapshot.deleteAllItems()
        self.diffableDataSource.apply(snapshot)
        collectionView.collectionViewLayout = ActivitySubTypeViewController.searchLayout()
        
        activityIndicatorView.startAnimating()
        
        searchActivities = []
        showGroups = false

        let dispatchGroup = DispatchGroup()
        
        if favorites == "true" {
            if let events = self.favAct["events"] {
                for event in events {
                    if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways {
                        dispatchGroup.enter()
                        Service.shared.fetchEventsSegmentLatLong(size: "30", id: event, keyword: query, attractionId: "", venueId: "", postalCode: zipcode, radius: "", unit: "", startDateTime: eventStartDate, endDateTime: eventEndDate, city: city, stateCode: state, countryCode: country, classificationName: eventType, classificationId: "", lat: self.locationManager.location?.coordinate.latitude ?? 0.0, long: self.locationManager.location?.coordinate.longitude ?? 0.0) { (search, err) in
                            activityIndicatorView.stopAnimating()
                            dispatchGroup.leave()
                            if let events = search?.embedded?.events {
                                self.searchActivities = sortEvents(events: events)
                                dispatchGroup.notify(queue: .main) {
                                    self.checkIfThereAnyActivities()
                                    snapshot.appendSections([.search])
                                    snapshot.appendItems(self.searchActivities, toSection: .search)
                                    self.diffableDataSource.apply(snapshot)
                                }
                            }
                        }
                    } else {
                        dispatchGroup.enter()
                        Service.shared.fetchEventsSegment(size: "30", id: event, keyword: query, attractionId: "", venueId: "", postalCode: zipcode, radius: "", unit: "", startDateTime: eventStartDate, endDateTime: eventEndDate, city: city, stateCode: state, countryCode: "", classificationName: eventType, classificationId: "") { (search, err) in
                            activityIndicatorView.stopAnimating()
                            dispatchGroup.leave()
                            if let events = search?.embedded?.events {
                                self.searchActivities = sortEvents(events: events)
                                dispatchGroup.notify(queue: .main) {
                                    self.checkIfThereAnyActivities()
                                    snapshot.appendSections([.search])
                                    snapshot.appendItems(self.searchActivities, toSection: .search)
                                    self.diffableDataSource.apply(snapshot)
                                }
                            }
                        }
                    }
                }
                activityIndicatorView.stopAnimating()
                self.checkIfThereAnyActivities()
            } else {
                activityIndicatorView.stopAnimating()
                self.checkIfThereAnyActivities()
            }
        } else {
            if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways {
                dispatchGroup.enter()
                Service.shared.fetchEventsSegmentLatLong(size: "30", id: "", keyword: query, attractionId: "", venueId: "", postalCode: zipcode, radius: "", unit: "", startDateTime: eventStartDate, endDateTime: eventEndDate, city: city, stateCode: state, countryCode: country, classificationName: eventType, classificationId: "", lat: self.locationManager.location?.coordinate.latitude ?? 0.0, long: self.locationManager.location?.coordinate.longitude ?? 0.0) { (search, err) in
                    activityIndicatorView.stopAnimating()
                    dispatchGroup.leave()
                    if let events = search?.embedded?.events {
                        self.searchActivities = sortEvents(events: events)
                        dispatchGroup.notify(queue: .main) {
                            self.checkIfThereAnyActivities()
                            snapshot.appendSections([.search])
                            snapshot.appendItems(self.searchActivities, toSection: .search)
                            self.diffableDataSource.apply(snapshot)
                        }
                    }
                }
            } else {
                dispatchGroup.enter()
                Service.shared.fetchEventsSegment(size: "30", id: "", keyword: query, attractionId: "", venueId: "", postalCode: zipcode, radius: "", unit: "", startDateTime: eventStartDate, endDateTime: eventEndDate, city: city, stateCode: state, countryCode: "", classificationName: eventType, classificationId: "") { (search, err) in
                    activityIndicatorView.stopAnimating()
                    dispatchGroup.leave()
                    if let events = search?.embedded?.events {
                        self.searchActivities = sortEvents(events: events)
                        dispatchGroup.notify(queue: .main) {
                            self.checkIfThereAnyActivities()
                            snapshot.appendSections([.search])
                            snapshot.appendItems(self.searchActivities, toSection: .search)
                            self.diffableDataSource.apply(snapshot)
                        }
                    }
                }
            }
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActivities = []
        
        collectionView.collectionViewLayout = ActivitySubTypeViewController.initialLayout()
        var snapshot = diffableDataSource.snapshot()
        snapshot.deleteSections([.search])
        for section in sections {
            if let object = groups[section] {
                snapshot.appendSections([section])
                snapshot.appendItems(object, toSection: section)
                diffableDataSource.apply(snapshot)
            }
        }
        showGroups = true
        checkIfThereAnyActivities()
    }
    
    fileprivate func fetchData() {
        
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        
        activityIndicatorView.startAnimating()
        
        diffableDataSource.supplementaryViewProvider = .some({ (collectionView, kind, indexPath) -> UICollectionReusableView? in
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.kCompositionalHeader, for: indexPath) as! CompositionalHeader
            let snapshot = self.diffableDataSource.snapshot()
            if let object = self.diffableDataSource.itemIdentifier(for: indexPath), let section = snapshot.sectionIdentifier(containingItem: object) {
                header.titleLabel.text = section.name
                header.subTitleLabel.isHidden = true
            }
            
            return header
        })
        
        var snapshot = self.diffableDataSource.snapshot()
        
        // help you sync your data fetches together
        let dispatchQueue = DispatchQueue.global(qos: .background)
        let dispatchGroup = DispatchGroup()
        let semaphore = DispatchSemaphore(value: 0)
        
        dispatchQueue.async {
            for section in self.sections {
                if let object = self.groups[section] {
                    activityIndicatorView.stopAnimating()
                    snapshot.appendSections([section])
                    snapshot.appendItems(object, toSection: section)
                    self.diffableDataSource.apply(snapshot)
                    continue
                } else if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways {
                    dispatchGroup.enter()
                    Service.shared.fetchEventsSegmentLatLong(size: "30", id: "", keyword: "", attractionId: "", venueId: "", postalCode: "", radius: "", unit: "", startDateTime: "", endDateTime: "", city: "", stateCode: "", countryCode: "", classificationName: section.searchTerm, classificationId: "", lat: self.locationManager.location?.coordinate.latitude ?? 0.0, long: self.locationManager.location?.coordinate.longitude ?? 0.0) { (search, err) in
                        dispatchGroup.leave()
                        semaphore.signal()
                        if let object = search?.embedded?.events {
                            self.groups[section] = object
                        }
                    }
                } else {
                    dispatchGroup.enter()
                    Service.shared.fetchEventsSegment(size: "30", id: "", keyword: "", attractionId: "", venueId: "", postalCode: "", radius: "", unit: "", startDateTime: "", endDateTime: "", city: "", stateCode: "", countryCode: "", classificationName: section.searchTerm, classificationId: "") { (search, err) in
                        dispatchGroup.leave()
                        semaphore.signal()
                        if let object = search?.embedded?.events {
                            self.groups[section] = object
                        }
                    }
                }
                
                semaphore.wait()
                        
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
            searchActivities = []
            self.filterDictionary = filterDictionary
            showGroups = true
            checkIfThereAnyActivities()
        }
    }
        
}

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
