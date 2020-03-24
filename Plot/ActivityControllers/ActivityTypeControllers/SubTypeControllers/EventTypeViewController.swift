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
    var searchEvents = [Event]()
    
    private let musicSegmentID = "KZFzniwnSyZfZ7v7nJ"
    private let sportsSegmentID = "KZFzniwnSyZfZ7v7nE"
    private let artstheatreSegmentID = "KZFzniwnSyZfZ7v7na"

    var filters: [filter] = [.cuisine, .excludeCuisine, .diet, .intolerances, .type]
    var filterDictionary = [String: [String]]()
    var sections: [String] = ["Concerts", "Sports", "Shows"]
    var attractions = [String]()

    
    var locationManager = CLLocationManager()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Events"

        let doneBarButton = UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(filter))
        navigationItem.rightBarButtonItem = doneBarButton

        setupSearchBar()
        
        fetchData()
        
        locationManager.requestWhenInUseAuthorization()
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
        
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { (_) in
            self.complexSearch(query: searchText.lowercased())
        })
    }
    
    func complexSearch(query: String) {
        print("query \(query)")

        self.searchEvents = [Event]()
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

        dispatchGroup.enter()
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways {
            dispatchGroup.enter()
            Service.shared.fetchEventsSegmentLatLong(keyword: query, segmentId: "", lat: self.locationManager.location?.coordinate.latitude ?? 0.0, long: self.locationManager.location?.coordinate.longitude ?? 0.0) { (search, err) in
                self.removeSpinner()
                dispatchGroup.leave()
                if let events = search?.embedded?.events {
                    self.searchEvents = events
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                }
            }
        } else {
            dispatchGroup.enter()
            Service.shared.fetchEventsSegment(keyword: "", segmentId: "") { (search, err) in
                self.removeSpinner()
                dispatchGroup.leave()
                if let events = search?.embedded?.events {
                    self.searchEvents = events
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                }
            }
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchEvents = [Event]()
        showGroups = true
        headerheight = 0
        cellheight = 397
        self.collectionView.reloadData()
    }
    
    fileprivate func fetchData() {
                
        headerheight = 0
        cellheight = 397
            
        var musicEvents: [Event]?
        var sportsEvents: [Event]?
        var arttheatreEvents: [Event]?
        
        // help you sync your data fetches together
        let dispatchGroup = DispatchGroup()
        
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways {
                dispatchGroup.enter()
                Service.shared.fetchEventsSegmentLatLong(keyword: "", segmentId: self.musicSegmentID, lat: self.locationManager.location?.coordinate.latitude ?? 0.0, long: self.locationManager.location?.coordinate.longitude ?? 0.0) { (search, err) in
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
                            self.sections.removeAll{ $0 == "Concerts"}
                        }
                        
                        self.collectionView.reloadData()
                        dispatchGroup.enter()
                        Service.shared.fetchEventsSegmentLatLong(keyword: "", segmentId: self.sportsSegmentID, lat: self.locationManager.location?.coordinate.latitude ?? 0.0, long: self.locationManager.location?.coordinate.longitude ?? 0.0) { (search, err) in
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
                                Service.shared.fetchEventsSegmentLatLong(keyword: "", segmentId: self.artstheatreSegmentID, lat: self.locationManager.location?.coordinate.latitude ?? 0.0, long: self.locationManager.location?.coordinate.longitude ?? 0.0) { (search, err) in
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
                Service.shared.fetchEventsSegment(keyword: "", segmentId: self.musicSegmentID) { (search, err) in
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
                            self.sections.removeAll{ $0 == "Concerts"}
                        }
        
                        self.collectionView.reloadData()
                            
                        dispatchGroup.enter()
                        Service.shared.fetchEventsSegment(keyword: "", segmentId: self.sportsSegmentID) { (search, err) in
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
                                Service.shared.fetchEventsSegment(keyword: "", segmentId: self.artstheatreSegmentID) { (search, err) in
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
        cell.horizontalController.favAct = favAct
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
                        destination.hidesBottomBarWhenPushed = true
                        destination.favAct = favAct
                        destination.event = event
                        destination.users = self!.users
                        destination.filteredUsers = self!.filteredUsers
                        destination.conversations = self!.conversations
                        self?.navigationController?.pushViewController(destination, animated: true)
                    }
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
        let events = searchEvents
        header.verticalController.favAct = favAct
        header.verticalController.events = events
        header.verticalController.collectionView.reloadData()
        header.verticalController.didSelectHandler = { [weak self] event, favAct in
            if let event = event as? Event {
                print("event \(String(describing: event.name))")
                let destination = EventDetailViewController()
                destination.hidesBottomBarWhenPushed = true
                destination.favAct = favAct
                destination.event = event
                destination.users = self!.users
                destination.filteredUsers = self!.filteredUsers
                destination.conversations = self!.conversations
                self?.navigationController?.pushViewController(destination, animated: true)
            }
        }
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return .init(width: view.frame.width, height: headerheight)
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
        if !filterDictionary.values.isEmpty {
            showGroups = false
            self.filterDictionary = filterDictionary
            complexSearch(query: "")
        } else {
            searchEvents = [Event]()
            self.filterDictionary = filterDictionary
            showGroups = true
            headerheight = 0
            cellheight = 397
            self.collectionView.reloadData()
        }
    }
        
}
