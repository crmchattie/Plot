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
    
    var groups = [[Workout]]()
    var searchActivities = [Workout]()

    var filters: [filter] = [.workoutType, .muscles, .duration]
    var filterDictionary = [String: [String]]()
    var sections: [String] = ["Quick", "HIIT", "Cardio"]


            
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Workouts"

        let doneBarButton = UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(filter))
        navigationItem.rightBarButtonItem = doneBarButton

//        setupSearchBar()
        
        fetchData()
                
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
            self.complexSearch(query: searchText.lowercased(), workoutType: self.filterDictionary["workoutType"]?[0] ?? "", muscles: self.filterDictionary["muscles"] ?? [], duration: self.filterDictionary["duration"]?[0] ?? "", favorites: self.filterDictionary["favorites"]?[0] ?? "")
        })
    }
    
    func complexSearch(query: String, workoutType: String, muscles: [String], duration: String, favorites: String) {
        print("query \(query), workoutType \(workoutType), muscles \(muscles), duration \(duration), favorites \(favorites)")
        
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }

        self.searchActivities = [Workout]()
        var workoutIDs = [String]()
        self.workoutTypeReference = Database.database().reference().child("workouts").child("types_of_workouts")

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
            if let workouts = self.favAct["workouts"] {
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
                    self.workoutTypeReference.child("type_of_workouts").child(newValue).child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                            if !snapshot.exists() {
                                include = false
                                if let index = workoutIDs.firstIndex(of: workoutID) {
                                    workoutIDs.remove(at: index)
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
                    self.workoutTypeReference.child("muscle_groups").child(newValue).child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                        if !snapshot.exists() {
                            include = false
                            if let index = workoutIDs.firstIndex(of: workoutID) {
                                workoutIDs.remove(at: index)
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
                    self.workoutTypeReference.child("workout_durations").child(newValue).child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                        if !snapshot.exists() {
                            include = false
                            if let index = workoutIDs.firstIndex(of: workoutID) {
                                workoutIDs.remove(at: index)
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
                        let existingWorkoutIDsSet = Set(workoutIDs)
                        let newWorkoutIDsSet = Set(workoutsSnapshotValue)
                        let bothWorkoutIDsSet = existingWorkoutIDsSet.intersection(newWorkoutIDsSet)
                        workoutIDs = Array(bothWorkoutIDsSet)
                        print("workoutIDs \(workoutIDs)")
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
                        print("workoutsSnapshotValue \(workoutsSnapshotValue)")
                        let existingWorkoutIDsSet = Set(workoutIDs)
                        let newWorkoutIDsSet = Set(workoutsSnapshotValue)
                        let bothWorkoutIDsSet = existingWorkoutIDsSet.intersection(newWorkoutIDsSet)
                        workoutIDs = Array(bothWorkoutIDsSet)
                        print("workoutIDs \(workoutIDs)")
                    }
                    dispatchGroup.leave()
                })
            }
        }
        
        print("workoutIDs \(workoutIDs)")
        dispatchGroup.notify(queue: .main) {
            print("looking up workouts")
            if query == "" {
                for workoutID in workoutIDs {
                    print(workoutID)
                    dispatchGroup.enter()
                    self.workoutReference = Database.database().reference().child("workouts").child("workouts")
                    self.workoutReference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                        if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                            if let workout = try? FirebaseDecoder().decode(Workout.self, from:      workoutSnapshotValue) {
                                print("workoutSnapshotValue \(workoutSnapshotValue)")
                                print("added workout to searchActivities")
                                print(workout.identifier)
                                self.searchActivities.append(workout)
                                self.collectionView.reloadData()
                            }
                        }
                        dispatchGroup.leave()
                      })
                }
            } else {
                for workoutID in workoutIDs {
                    print(workoutID)
                    dispatchGroup.enter()
                    self.workoutReference = Database.database().reference().child("workouts").child("workouts")
                    self.workoutReference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                        if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                            if let workout = try? FirebaseDecoder().decode(Workout.self, from:      workoutSnapshotValue) {
                                print("workoutSnapshotValue \(workoutSnapshotValue)")
                                let notes = workout.notes ?? ""
                                let tags = workout.tagsStr ?? ""
                                let title = workout.title
                                if notes.contains(query) || tags.contains(query) || title.contains(query) {
                                    print("added workout to searchActivities")
                                    print(workout.identifier)
                                    self.searchActivities.append(workout)
                                    self.collectionView.reloadData()
                                }
                            }
                        }
                        dispatchGroup.leave()
                      })
                }
            }
        }
        self.removeSpinner()
        checkIfThereAnyActivities()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if !filterDictionary.values.isEmpty && searchActivities.isEmpty {
            showGroups = false
            complexSearch(query: "", workoutType: self.filterDictionary["workoutType"]?[0] ?? "", muscles: self.filterDictionary["muscles"] ?? [], duration: self.filterDictionary["duration"]?[0] ?? "", favorites: self.filterDictionary["favorites"]?[0] ?? "")
        } else if !filterDictionary.values.isEmpty && !searchActivities.isEmpty {
            self.checkIfThereAnyActivities()
            showGroups = false
            self.headerheight = view.frame.height
            self.cellheight = 0
            self.collectionView.reloadData()
        } else {
            viewPlaceholder.remove(from: view, priority: .medium)
            searchActivities = [Workout]()
            showGroups = true
            headerheight = 0
            cellheight = 397
            checkIfThereAnyActivities()
        }
    }
    
    fileprivate func fetchData() {
        
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
                
        headerheight = 0
        cellheight = 397
            
        var workout1 = [Workout]()
        var workout2 = [Workout]()
        var workout3 = [Workout]()
        
        // help you sync your data fetches together
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        self.workoutTypeReference = Database.database().reference().child("workouts").child("types_of_workouts")
        self.workoutTypeReference.child("workout_durations").child("short").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists(), let workoutsSnapshotValue = snapshot.value as! [String]? {
                dispatchGroup.leave()
//                print(workoutsSnapshotValue)
                // no need to look up every workout at node
                for index in 0...19 {
                    let workoutID = workoutsSnapshotValue[index]
                    print(workoutID)
                    dispatchGroup.enter()
                    self.workoutReference = Database.database().reference().child("workouts").child("workouts")
                    self.workoutReference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                        if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                            if let workout = try? FirebaseDecoder().decode(Workout.self, from: workoutSnapshotValue) {
                                print("added workout to workout1")
                                print(workout.identifier)
                                workout1.append(workout)
                                dispatchGroup.leave()

                            }
                        }
                      })
                    { (error) in
                        dispatchGroup.leave()
                        print(error.localizedDescription)
                        self.sections.removeAll{ $0 == "Quick"}
                    }
                }
                
                dispatchGroup.notify(queue: .main) {
                    print("added to groups")
                    self.groups.append(workout1)
                    self.collectionView.reloadData()
                    
                    dispatchGroup.enter()
                    self.workoutTypeReference.child("type_of_workouts").child("hiit").observeSingleEvent(of: .value, with: { (snapshot) in
                        if snapshot.exists(), let workoutsSnapshotValue = snapshot.value as! [String]? {
                            dispatchGroup.leave()
                            print(workoutsSnapshotValue)
                            for workoutID in workoutsSnapshotValue {
                                print(workoutID)
                                dispatchGroup.enter()
                                self.workoutReference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                                    if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                                        if let workout = try? FirebaseDecoder().decode(Workout.self, from: workoutSnapshotValue) {
                                            print("added workout to workout1")
                                            print(workout.identifier)
                                            workout2.append(workout)
                                            dispatchGroup.leave()

                                        }
                                    }
                                  })
                                { (error) in
                                    dispatchGroup.leave()
                                    print(error.localizedDescription)
                                    self.sections.removeAll{ $0 == "HIIT"}
                                }
                            }
                            
                            dispatchGroup.notify(queue: .main) {
                                print("added to groups")
                                self.groups.append(workout2)
                                self.collectionView.reloadData()
                                
                                dispatchGroup.enter()
                                self.workoutTypeReference.child("type_of_workouts").child("cardio").observeSingleEvent(of: .value, with: { (snapshot) in
                                    if snapshot.exists(), let workoutsSnapshotValue = snapshot.value as! [String]? {
                                        dispatchGroup.leave()
                        //                print(workoutsSnapshotValue)
                                        for index in 0...19 {
                                            let workoutID = workoutsSnapshotValue[index]
                                            print(workoutID)
                                            dispatchGroup.enter()
                                            self.workoutReference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                                                if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                                                    if let workout = try? FirebaseDecoder().decode(Workout.self, from: workoutSnapshotValue) {
                                                        print("added workout to workout1")
                                                        print(workout.identifier)
                                                        workout3.append(workout)
                                                        dispatchGroup.leave()

                                                    }
                                                }
                                              })
                                            { (error) in
                                                dispatchGroup.leave()
                                                print(error.localizedDescription)
                                                self.sections.removeAll{ $0 == "Cardio"}
                                            }
                                        }
                                        
                                        dispatchGroup.notify(queue: .main) {
                                            print("added to groups")
                                            self.groups.append(workout3)
                                            self.collectionView.reloadData()
                                                
                                        }
                                    }
                                })
                                { (error) in
                                    dispatchGroup.leave()
                                    print(error.localizedDescription)
                                    self.sections.removeAll{ $0 == "Cardio"}
                                }
                            }
                        }
                    })
                    { (error) in
                        dispatchGroup.leave()
                        print(error.localizedDescription)
                        self.sections.removeAll{ $0 == "HIIT"}
                    }
                        
                }
            }
          })
        { (error) in
            dispatchGroup.leave()
            print(error.localizedDescription)
            self.sections.removeAll{ $0 == "Quick"}
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
                let workouts = groups[indexPath.item]
                cell.horizontalController.workouts = workouts
                cell.horizontalController.collectionView.reloadData()
                cell.horizontalController.didSelectHandler = { [weak self] workout, favAct in
                    if let workout = workout as? Workout {
                        print("workout \(String(describing: workout.title))")
                        let destination = WorkoutDetailViewController()
                        destination.favAct = favAct
                        destination.workout = workout
                        if let index = workouts.firstIndex(where: {$0.identifier == workout.identifier} ) {
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
        let workouts = searchActivities
        header.verticalController.favAct = favAct
        header.verticalController.workouts = workouts
        header.verticalController.collectionView.reloadData()
        header.verticalController.conversations = conversations
        header.verticalController.activities = activities
        header.verticalController.users = users
        header.verticalController.filteredUsers = filteredUsers
        header.verticalController.favAct = favAct
        header.verticalController.conversation = conversation
        header.verticalController.schedule = schedule
        header.verticalController.umbrellaActivity = umbrellaActivity
        header.verticalController.didSelectHandler = { [weak self] workout, favAct in
            if let workout = workout as? Workout {
                print("workout \(String(describing: workout.title))")
                let destination = WorkoutDetailViewController()
                destination.favAct = favAct
                destination.workout = workout
                if let index = workouts.firstIndex(where: {$0.identifier == workout.identifier} ) {
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
            }
        }
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return .init(width: view.frame.width, height: headerheight)
    }
    
    
    func checkIfThereAnyActivities() {
        if searchActivities.count > 0 {
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
            complexSearch(query: "", workoutType: self.filterDictionary["workoutType"]?[0] ?? "", muscles: self.filterDictionary["muscles"] ?? [], duration: self.filterDictionary["duration"]?[0] ?? "", favorites: self.filterDictionary["favorites"]?[0] ?? "")
        } else {
            viewPlaceholder.remove(from: view, priority: .medium)
            searchActivities = [Workout]()
            self.filterDictionary = filterDictionary
            showGroups = true
            headerheight = 0
            cellheight = 397
            self.collectionView.reloadData()
        }
    }
        
}
