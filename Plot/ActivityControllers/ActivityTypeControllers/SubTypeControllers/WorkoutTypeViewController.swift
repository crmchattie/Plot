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
    
    var sections: [ActivitySection] = [.quick, .hiit, .cardio, .medium, .strength]
    var groups = [ActivitySection: [Workout]]()
    var searchActivities = [Workout]()

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
            if workoutIDs.isEmpty {
                self.checkIfThereAnyActivities()
            } else if query == "" {
                for workoutID in workoutIDs {
                    dispatchGroup.enter()
                    self.workoutReference = Database.database().reference().child("workouts").child("workouts")
                    self.workoutReference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                        if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                            if let workout = try? FirebaseDecoder().decode(Workout.self, from:      workoutSnapshotValue) {
                                self.searchActivities.append(workout)
                                self.checkIfThereAnyActivities()
                            }
                        }
                        dispatchGroup.leave()
                      })
                }
            } else {
                for workoutID in workoutIDs {
                    dispatchGroup.enter()
                    self.workoutReference = Database.database().reference().child("workouts").child("workouts")
                    self.workoutReference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                        if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                            if let workout = try? FirebaseDecoder().decode(Workout.self, from:      workoutSnapshotValue) {
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
            }
        }
        dispatchGroup.notify(queue: .main) {
            activityIndicatorView.stopAnimating()
            self.checkIfThereAnyActivities()
            snapshot.appendSections([.search])
            snapshot.appendItems(self.searchActivities, toSection: .search)
            self.diffableDataSource.apply(snapshot)
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
                        var workouts = [Workout]()
                        for workoutID in workoutsSnapshotValue {
                            dispatchGroup.enter()
                            self.workoutReference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                                if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                                    if let workout = try? FirebaseDecoder().decode(Workout.self, from: workoutSnapshotValue) {
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
                        var workouts = [Workout]()
                        for workoutID in workoutsSnapshotValue {
                            dispatchGroup.enter()
                            self.workoutReference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                                if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                                    if let workout = try? FirebaseDecoder().decode(Workout.self, from: workoutSnapshotValue) {
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
    func viewTapped(labelText: String) {
        print(labelText)
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
            showGroups = true
            checkIfThereAnyActivities()
        }
    }
        
}
