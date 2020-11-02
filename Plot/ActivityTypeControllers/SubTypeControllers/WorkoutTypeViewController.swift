//
//  WorkoutTypeViewController.swift
//  Plot
//
//  Created by Cory McHattie on 3/21/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class WorkoutTypeViewController: ActivitySubTypeViewController, UISearchBarDelegate {
    
    fileprivate var workoutTypeReference: DatabaseReference!
    fileprivate var workoutReference: DatabaseReference!
    
    var sections: [SectionType] = [.quick, .hiit, .cardio, .medium, .strength]
    var groups = [SectionType: [PreBuiltWorkout]]()
    var searchActivities = [PreBuiltWorkout]()
    
    var filters: [filter] = [.workoutType, .muscles, .duration, .equipmentLevel, .equipment]
    var filterDictionary = [String: [String]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Workouts"
        
        let doneBarButton = UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(filter))
        navigationItem.rightBarButtonItem = doneBarButton
        
        
        searchController.searchBar.delegate = self
        
        fetchData()
        
    }
    
    lazy var diffableDataSource: UICollectionViewDiffableDataSource<SectionType, AnyHashable> = .init(collectionView: self.collectionView) { (collectionView, indexPath, object) -> UICollectionViewCell? in
        if let object = object as? ActivityType {
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
        } else if let object = object as? Event {
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
        let snapshot = self.diffableDataSource.snapshot()
        let section = snapshot.sectionIdentifier(containingItem: object!)
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
            destination.listList = self.listList
            destination.schedule = self.schedule
            destination.umbrellaActivity = self.umbrellaActivity
            destination.delegate = self
            destination.listDelegate = self
            destination.listType = self.listType
            destination.activityType = section?.image
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
            destination.listList = self.listList
            destination.activities = self.activities
            destination.conversation = self.conversation
            destination.schedule = self.schedule
            destination.umbrellaActivity = self.umbrellaActivity
            destination.delegate = self
            destination.listDelegate = self
            destination.listType = self.listType
            destination.activityType = section?.image
            self.navigationController?.pushViewController(destination, animated: true)
        } else if let workout = object as? PreBuiltWorkout {
            print("workout \(String(describing: workout.title))")
            let destination = WorkoutDetailViewController()
            destination.hidesBottomBarWhenPushed = true
            destination.favAct = favAct
            destination.workout = workout
            destination.intColor = (indexPath.item % 5)
            destination.users = self.users
            destination.filteredUsers = self.filteredUsers
            destination.conversations = self.conversations
            destination.listList = self.listList
            destination.activities = self.activities
            destination.conversation = self.conversation
            destination.schedule = self.schedule
            destination.umbrellaActivity = self.umbrellaActivity
            destination.delegate = self
            destination.listDelegate = self
            destination.listType = self.listType
            destination.activityType = section?.image
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
            destination.listList = self.listList
            destination.activities = self.activities
            destination.conversation = self.conversation
            destination.schedule = self.schedule
            destination.umbrellaActivity = self.umbrellaActivity
            destination.delegate = self
            destination.listDelegate = self
            destination.listType = self.listType
            destination.activityType = section?.image
            self.navigationController?.pushViewController(destination, animated: true)
        } else if let place = object as? FSVenue {
            print("place.id \(String(describing: place.id))")
            let destination = PlaceDetailViewController()
            destination.hidesBottomBarWhenPushed = true
            destination.favAct = favAct
            destination.placeID = place.id
            destination.users = self.users
            destination.filteredUsers = self.filteredUsers
            destination.conversations = self.conversations
            destination.listList = self.listList
            destination.activities = self.activities
            destination.conversation = self.conversation
            destination.schedule = self.schedule
            destination.umbrellaActivity = self.umbrellaActivity
            destination.delegate = self
            destination.listDelegate = self
            destination.listType = self.listType
            destination.activityType = section?.image
            self.navigationController?.pushViewController(destination, animated: true)
        } else if let groupItem = object as? GroupItem, let place = groupItem.venue {
            print("place.id \(String(describing: place.id))")
            let destination = PlaceDetailViewController()
            destination.hidesBottomBarWhenPushed = true
            destination.favAct = favAct
            destination.placeID = place.id
            destination.users = self.users
            destination.filteredUsers = self.filteredUsers
            destination.conversations = self.conversations
            destination.listList = self.listList
            destination.activities = self.activities
            destination.conversation = self.conversation
            destination.schedule = self.schedule
            destination.umbrellaActivity = self.umbrellaActivity
            destination.delegate = self
            destination.listDelegate = self
            destination.listType = self.listType
            destination.activityType = section?.image
            self.navigationController?.pushViewController(destination, animated: true)
        } else {
            print("neither meals or events")
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print(searchText)
        
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { (_) in
            self.complexSearch(query: searchText.lowercased(), workoutType: self.filterDictionary["workoutType"]?[0] ?? "", muscles: self.filterDictionary["muscles"] ?? [], duration: self.filterDictionary["duration"]?[0] ?? "", equipmentLevel: self.filterDictionary["equipmentLevel"]?[0] ?? "", equipment: self.filterDictionary["equipment"] ?? [], favorites: self.filterDictionary["favorites"]?[0] ?? "")
        })
    }
    
    func complexSearch(query: String, workoutType: String, muscles: [String], duration: String, equipmentLevel: String, equipment: [String], favorites: String) {
        print("query \(query), workoutType \(workoutType), muscles \(muscles), duration \(duration), equipmentLevel \(equipmentLevel), equipment \(equipment), favorites \(favorites)")
        
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
        
        var workoutIDs = [String]()
        self.workoutTypeReference = Database.database().reference().child("workouts").child("types_of_workouts")
        
        let dispatchGroup = DispatchGroup()
        
        if favorites == "true" {
            if let workouts = self.favAct["workouts"] {
                print("workouts \(workouts)")
                workoutIDs = workouts
                for workoutID in workouts {
                    var include = true
                    if workoutType != "" {
                        dispatchGroup.enter()
                        var newValue = String()
                        if workoutType == "Strength" {
                            newValue = "workout"
                        } else {
                            newValue = workoutType.replacingOccurrences(of: " ", with: "_")
                            newValue = newValue.replacingOccurrences(of: "/", with: "&")
                            newValue = newValue.lowercased()
                        }
                        self.workoutTypeReference.child("type_of_workouts").child(newValue).observeSingleEvent(of: .value, with: { (snapshot) in
                            if snapshot.exists(), let workoutsSnapshotValue = snapshot.value as! [String]? {
                                if !workoutsSnapshotValue.contains(workoutID) {
                                    include = false
                                    if let index = workoutIDs.firstIndex(of: workoutID) {
                                        workoutIDs.remove(at: index)
                                    }
                                }
                            }
                            dispatchGroup.leave()
                        })
                    }
                    guard include == true else { continue }
                    for muscle in muscles {
                        dispatchGroup.enter()
                        var newValue = muscle.replacingOccurrences(of: " ", with: "_")
                        newValue = newValue.replacingOccurrences(of: "/", with: "&")
                        newValue = newValue.lowercased()
                        self.workoutTypeReference.child("muscle_groups").child(newValue).observeSingleEvent(of: .value, with: { (snapshot) in
                            if snapshot.exists(), let workoutsSnapshotValue = snapshot.value as! [String]? {
                                if !workoutsSnapshotValue.contains(workoutID) {
                                    include = false
                                    if let index = workoutIDs.firstIndex(of: workoutID) {
                                        workoutIDs.remove(at: index)
                                    }
                                }
                            }
                            dispatchGroup.leave()
                        })
                    }
                    guard include == true else { continue }
                    if duration != "" {
                        dispatchGroup.enter()
                        var newValue = duration.replacingOccurrences(of: " ", with: "_")
                        newValue = newValue.replacingOccurrences(of: "/", with: "&")
                        newValue = newValue.lowercased()
                        self.workoutTypeReference.child("workout_durations").child(newValue).observeSingleEvent(of: .value, with: { (snapshot) in
                            if snapshot.exists(), let workoutsSnapshotValue = snapshot.value as! [String]? {
                                if !workoutsSnapshotValue.contains(workoutID) {
                                    include = false
                                    if let index = workoutIDs.firstIndex(of: workoutID) {
                                        workoutIDs.remove(at: index)
                                    }
                                }
                            }
                            dispatchGroup.leave()
                        })
                    }
                    guard include == true else { continue }
                    if equipmentLevel != "" {
                        dispatchGroup.enter()
                        let newValue = equipmentLevel.lowercased()
                        self.workoutTypeReference.child("equipment_level").child(newValue).observeSingleEvent(of: .value, with: { (snapshot) in
                            if snapshot.exists(), let workoutsSnapshotValue = snapshot.value as! [String]? {
                                if !workoutsSnapshotValue.contains(workoutID) {
                                    include = false
                                    if let index = workoutIDs.firstIndex(of: workoutID) {
                                        workoutIDs.remove(at: index)
                                    }
                                }
                            }
                            dispatchGroup.leave()
                        })
                    }
                    guard include == true else { continue }
                    for equip in equipment {
                        dispatchGroup.enter()
                        var newValue = equip.replacingOccurrences(of: " ", with: "_")
                        newValue = newValue.replacingOccurrences(of: "/", with: "&")
                        newValue = newValue.lowercased()
                        self.workoutTypeReference.child("equipment").child(newValue).observeSingleEvent(of: .value, with: { (snapshot) in
                            if snapshot.exists(), let workoutsSnapshotValue = snapshot.value as! [String]? {
                                if !workoutsSnapshotValue.contains(workoutID) {
                                    include = false
                                    if let index = workoutIDs.firstIndex(of: workoutID) {
                                        workoutIDs.remove(at: index)
                                    }
                                }
                            }
                            dispatchGroup.leave()
                        })
                    }
                }
            }
        } else {
            if workoutType != "" {
                dispatchGroup.enter()
                var newValue = String()
                if workoutType == "Strength" {
                    newValue = "workout"
                } else {
                    newValue = workoutType.replacingOccurrences(of: " ", with: "_")
                    newValue = newValue.replacingOccurrences(of: "/", with: "&")
                    newValue = newValue.lowercased()
                }
                print("newValue \(newValue)")
                self.workoutTypeReference.child("type_of_workouts").child(newValue).observeSingleEvent(of: .value, with: { (snapshot) in
                    print("snapshot \(snapshot)")
                    if snapshot.exists(), let workoutsSnapshotValue = snapshot.value as! [String]? {
                        print("workoutsSnapshotValue \(workoutsSnapshotValue)")
                        workoutIDs += workoutsSnapshotValue
                        print("workoutIDs \(workoutIDs)")
                    }
                    dispatchGroup.leave()
                })
            }
            
            for muscle in muscles {
                dispatchGroup.enter()
                var newValue = muscle.replacingOccurrences(of: " ", with: "_")
                newValue = newValue.replacingOccurrences(of: "/", with: "&")
                newValue = newValue.lowercased()
                print("newValue \(newValue)")
                self.workoutTypeReference.child("muscle_groups").child(newValue).observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), let workoutsSnapshotValue = snapshot.value as! [String]? {
                        print("workoutsSnapshotValue \(workoutsSnapshotValue)")
                        if workoutIDs.isEmpty {
                            workoutIDs += workoutsSnapshotValue
                        } else {
                            let existingWorkoutIDsSet = Set(workoutIDs)
                            let newWorkoutIDsSet = Set(workoutsSnapshotValue)
                            let bothWorkoutIDsSet = existingWorkoutIDsSet.intersection(newWorkoutIDsSet)
                            print("bothWorkoutIDsSet \(bothWorkoutIDsSet)")
                            workoutIDs = Array(bothWorkoutIDsSet)
                            print("workoutIDs \(workoutIDs)")
                        }
                    }
                    dispatchGroup.leave()
                })
            }
            if duration != "" {
                dispatchGroup.enter()
                var newValue = duration.replacingOccurrences(of: " ", with: "_")
                newValue = newValue.replacingOccurrences(of: "/", with: "&")
                newValue = newValue.lowercased()
                print("newValue \(newValue)")
                self.workoutTypeReference.child("workout_durations").child(newValue).observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), let workoutsSnapshotValue = snapshot.value as! [String]? {
                        if workoutIDs.isEmpty {
                            workoutIDs += workoutsSnapshotValue
                        } else {
                            let existingWorkoutIDsSet = Set(workoutIDs)
                            let newWorkoutIDsSet = Set(workoutsSnapshotValue)
                            let bothWorkoutIDsSet = existingWorkoutIDsSet.intersection(newWorkoutIDsSet)
                            print("bothWorkoutIDsSet \(bothWorkoutIDsSet)")
                            workoutIDs = Array(bothWorkoutIDsSet)
                            print("workoutIDs \(workoutIDs)")
                        }
                    }
                    dispatchGroup.leave()
                })
            }
            if equipmentLevel != "" {
                dispatchGroup.enter()
                let newValue = equipmentLevel.lowercased()
                print("newValue \(newValue)")
                self.workoutTypeReference.child("equipment_level").child(newValue).observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), let workoutsSnapshotValue = snapshot.value as! [String]? {
                        if workoutIDs.isEmpty {
                            workoutIDs += workoutsSnapshotValue
                        } else {
                            let existingWorkoutIDsSet = Set(workoutIDs)
                            let newWorkoutIDsSet = Set(workoutsSnapshotValue)
                            let bothWorkoutIDsSet = existingWorkoutIDsSet.intersection(newWorkoutIDsSet)
                            print("bothWorkoutIDsSet \(bothWorkoutIDsSet)")
                            workoutIDs = Array(bothWorkoutIDsSet)
                            print("workoutIDs \(workoutIDs)")
                        }
                    }
                    dispatchGroup.leave()
                })
            }
            for equip in equipment {
                dispatchGroup.enter()
                var newValue = equip.replacingOccurrences(of: " ", with: "_")
                newValue = newValue.replacingOccurrences(of: "/", with: "&")
                newValue = newValue.lowercased()
                print("newValue \(newValue)")
                self.workoutTypeReference.child("equipment").child(newValue).observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), let workoutsSnapshotValue = snapshot.value as! [String]? {
                        print("workoutsSnapshotValue \(workoutsSnapshotValue)")
                        workoutIDs += workoutsSnapshotValue
                        workoutIDs = Array(Set(workoutIDs))
                        print("equipmentIDList \(workoutIDs)")
                    }
                    dispatchGroup.leave()
                })
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            print("looking up workouts")
            print("workoutIDs \(workoutIDs)")
            if !workoutIDs.isEmpty, query == "" {
                for workoutID in workoutIDs {
                    dispatchGroup.enter()
                    self.workoutReference = Database.database().reference().child("workouts").child("workouts")
                    self.workoutReference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                        print("snapshot \(snapshot)")
                        if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                            if let workout = try? FirebaseDecoder().decode(PreBuiltWorkout.self, from:      workoutSnapshotValue) {
                                print("adding working to searchActivities")
                                self.searchActivities.append(workout)
                                self.checkIfThereAnyActivities()
                            }
                        }
                        dispatchGroup.leave()
                    })
                }
                dispatchGroup.notify(queue: .main) {
                    print("notify")
                    activityIndicatorView.stopAnimating()
                    if !self.searchActivities.isEmpty {
                        print("not empty")
                        print("!self.searchActivities.isEmpty \(!self.searchActivities.isEmpty)")
                        snapshot.appendSections([.search])
                        snapshot.appendItems(self.searchActivities, toSection: .search)
                        self.diffableDataSource.apply(snapshot)
                    } else {
                        print("!self.searchActivities.isEmpty \(!self.searchActivities.isEmpty)")
                        self.checkIfThereAnyActivities()
                    }
                }
                
            } else if !workoutIDs.isEmpty {
                for workoutID in workoutIDs {
                    dispatchGroup.enter()
                    self.workoutReference = Database.database().reference().child("workouts").child("workouts")
                    self.workoutReference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                        if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                            if let workout = try? FirebaseDecoder().decode(PreBuiltWorkout.self, from:      workoutSnapshotValue) {
                                let notes = workout.notes ?? ""
                                let tags = workout.tagsStr ?? ""
                                let title = workout.title
                                if notes.contains(query) || tags.contains(query) || title.contains(query) {
                                    self.searchActivities.append(workout)
                                    self.checkIfThereAnyActivities()
                                }
                            }
                        }
                        dispatchGroup.leave()
                    })
                }
                
                dispatchGroup.notify(queue: .main) {
                    print("notify")
                    activityIndicatorView.stopAnimating()
                    if !self.searchActivities.isEmpty {
                        print("not empty")
                        print("!self.searchActivities.isEmpty \(!self.searchActivities.isEmpty)")
                        snapshot.appendSections([.search])
                        snapshot.appendItems(self.searchActivities, toSection: .search)
                        self.diffableDataSource.apply(snapshot)
                    } else {
                        print("!self.searchActivities.isEmpty \(!self.searchActivities.isEmpty)")
                        self.checkIfThereAnyActivities()
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
        
        var collectionViewSnapshot = self.diffableDataSource.snapshot()
        
        let dispatchGroup = DispatchGroup()
        
        workoutTypeReference = Database.database().reference().child("workouts").child("types_of_workouts")
        workoutReference = Database.database().reference().child("workouts").child("workouts")
        
        for section in sections {
            if let object = groups[section] {
                activityIndicatorView.stopAnimating()
                collectionViewSnapshot.appendSections([section])
                collectionViewSnapshot.appendItems(object, toSection: section)
                self.diffableDataSource.apply(collectionViewSnapshot)
                continue
            } else if section.subType == "Type" {
                dispatchGroup.enter()
                self.workoutTypeReference.child("type_of_workouts").child(section.searchTerm).observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), let workoutsSnapshotValue = snapshot.value as! [String]? {
                        dispatchGroup.leave()
                        var workouts = [PreBuiltWorkout]()
                        for workoutID in workoutsSnapshotValue {
                            dispatchGroup.enter()
                            self.workoutReference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                                if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                                    if let workout = try? FirebaseDecoder().decode(PreBuiltWorkout.self, from: workoutSnapshotValue) {
                                        workouts.append(workout)
                                        self.groups[section] = workouts
                                        dispatchGroup.leave()
                                    } else {
                                        dispatchGroup.leave()
                                    }
                                }
                            })
                        }
                        dispatchGroup.notify(queue: .main) {
                            if let object = self.groups[section] {
                                activityIndicatorView.stopAnimating()
                                collectionViewSnapshot.appendSections([section])
                                collectionViewSnapshot.appendItems(object, toSection: section)
                                self.diffableDataSource.apply(collectionViewSnapshot)
                            }
                        }
                    }
                })
            } else if section.subType == "Duration" {
                dispatchGroup.enter()
                self.workoutTypeReference.child("workout_durations").child(section.searchTerm).observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), let workoutsSnapshotValue = snapshot.value as! [String]? {
                        dispatchGroup.leave()
                        var workouts = [PreBuiltWorkout]()
                        for workoutID in workoutsSnapshotValue {
                            dispatchGroup.enter()
                            self.workoutReference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                                if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                                    if let workout = try? FirebaseDecoder().decode(PreBuiltWorkout.self, from: workoutSnapshotValue) {
                                        workouts.append(workout)
                                        self.groups[section] = workouts
                                        dispatchGroup.leave()
                                    } else {
                                        dispatchGroup.leave()
                                    }
                                }
                            })
                        }
                        dispatchGroup.notify(queue: .main) {
                            if let object = self.groups[section] {
                                activityIndicatorView.stopAnimating()
                                collectionViewSnapshot.appendSections([section])
                                collectionViewSnapshot.appendItems(object, toSection: section)
                                self.diffableDataSource.apply(collectionViewSnapshot)
                            }
                        }
                    }
                })
            }
        }
    }
    
    
    func checkIfThereAnyActivities() {
        if searchActivities.count > 0 || showGroups {
            viewPlaceholder.remove(from: view, priority: .medium)
        } else {
            viewPlaceholder.add(for: view, title: .emptyWorkouts, subtitle: .emptyWorkouts, priority: .medium, position: .top)
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

extension WorkoutTypeViewController: ActivityTypeCellDelegate {
    func plusButtonTapped(type: AnyHashable) {
        print("plusButtonTapped")
        let snapshot = self.diffableDataSource.snapshot()
        let section = snapshot.sectionIdentifier(containingItem: type)
        if activeList {
            if let object = type as? PreBuiltWorkout {
                var updatedObject = object
                updatedObject.title = updatedObject.title.removeCharacters()
                self.movingBackwards = false
                
                self.listDelegate!.updateList(recipe: nil, workout: updatedObject, event: nil, place: nil, activityType: section?.image)
                self.actAddAlert()
                self.removeActAddAlert()
            }
            return
        }
        
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
            activity.activityType = section?.image
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
        } else if let workout = type as? PreBuiltWorkout {
            activity.name = workout.title
            activity.activityType = section?.image
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
            activity.activityType = section?.image
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
                let newLocationName = locationName.removeCharacters()
                activity.locationName = newLocationName
                activity.locationAddress = [newLocationName: [Double(latitude)!, Double(longitude)!]]
            }
        } else if let attraction = type as? Attraction {
            activity.name = attraction.name
        } else if let place = type as? FSVenue {
            activity.name = place.name
            activity.activityType = section?.image
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
                let newLocationName = locationName.removeCharacters()
                activity.locationName = newLocationName
                activity.locationAddress = [newLocationName: [latitude, longitude]]
            }
            activity.allDay = false
            activity.startDateTime = NSNumber(value: Int((startDateTime!).timeIntervalSince1970))
            activity.endDateTime = NSNumber(value: Int((endDateTime!).timeIntervalSince1970))
        } else if let groupItem = type as? GroupItem, let place = groupItem.venue {
            activity.name = place.name
            activity.activityType = section?.image
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
                let newLocationName = locationName.removeCharacters()
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
                self.movingBackwards = false

                self.delegate?.updateSchedule(schedule: self.activity)
                if let recipeID = self.activity.recipeID {
                    self.delegate?.updateIngredients(recipe: nil, recipeID: recipeID)
                }
                
                self.actAddAlert()
                self.removeActAddAlert()
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
            
            alert.addAction(UIAlertAction(title: "Add to Existing Activity", style: .default, handler: { (_) in
                
                // ChooseActivityTableViewController
                let destination = ChooseActivityTableViewController()
                let navController = UINavigationController(rootViewController: destination)
                destination.delegate = self
                destination.activity = self.activity
                destination.activities = self.activities
                destination.filteredActivities = self.activities
                self.present(navController, animated: true, completion: nil)
                
            }))
            
            alert.addAction(UIAlertAction(title: "Add to List", style: .default, handler: { (_) in
                
                // ChooseActivityTableViewController
                let destination = ChooseListTableViewController()
                let navController = UINavigationController(rootViewController: destination)
                destination.lists = self.listList
                destination.filteredLists = self.listList
                destination.activityType = section?.image
                if let object = type as? Recipe {
                    destination.recipe = object
                } else if let object = type as? Event {
                    destination.event = object
                } else if let object = type as? PreBuiltWorkout {
                    destination.workout = object
                } else if let object = type as? FSVenue {
                    destination.fsVenue = object
                } else if let groupItem = type as? GroupItem, let object = groupItem.venue {
                    destination.fsVenue = object
                }
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
    
    func mapButtonTapped(type: AnyHashable) {
        
    }
}

extension WorkoutTypeViewController: UpdateFilter {
    func updateFilter(filterDictionary : [String: [String]]) {
        print("filterDictionary \(filterDictionary)")
        if !filterDictionary.values.isEmpty {
            showGroups = false
            self.filterDictionary = filterDictionary
            complexSearch(query: "", workoutType: self.filterDictionary["workoutType"]?[0] ?? "", muscles: self.filterDictionary["muscles"] ?? [], duration: self.filterDictionary["duration"]?[0] ?? "", equipmentLevel: self.filterDictionary["equipmentLevel"]?[0] ?? "", equipment: self.filterDictionary["equipment"] ?? [], favorites: self.filterDictionary["favorites"]?[0] ?? "")
        } else {
            searchActivities = []
            self.filterDictionary = filterDictionary
            
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
    }
    
}

extension WorkoutTypeViewController: ChooseActivityDelegate {
    func chosenActivity(mergeActivity: Activity) {
        if let activity = activity {
            let dispatchGroup = DispatchGroup()
            if mergeActivity.recipeID != nil || mergeActivity.workoutID != nil || mergeActivity.eventID != nil || mergeActivity.placeID != nil {
                if let currentUserID = Auth.auth().currentUser?.uid {
                    let newActivityID = Database.database().reference().child("user-activities").child(currentUserID).childByAutoId().key ?? ""
                    let newActivity = mergeActivity.copy() as! Activity
                    newActivity.activityID = newActivityID
                    newActivity.recipeID = nil
                    newActivity.workoutID = nil
                    newActivity.eventID = nil
                    newActivity.placeID = nil
                    
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
               self.actAddAlert()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                    self.removeActAddAlert()
                })
            }
        }
    }
}
