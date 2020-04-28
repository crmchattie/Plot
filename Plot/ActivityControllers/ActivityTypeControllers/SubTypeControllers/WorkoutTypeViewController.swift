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

    var filters: [filter] = [.workoutType, .muscles, .duration, .equipmentLevel, .equipment]
    var filterDictionary = [String: [String]]()
    var sections: [String] = ["Quick", "HIIT", "Cardio", "Yoga", "Medium Length", "Strength"]


            
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
            self.complexSearch(query: searchText.lowercased(), workoutType: self.filterDictionary["workoutType"]?[0] ?? "", muscles: self.filterDictionary["muscles"] ?? [], duration: self.filterDictionary["duration"]?[0] ?? "", equipmentLevel: self.filterDictionary["equipmentLevel"]?[0] ?? "", equipment: self.filterDictionary["equipment"] ?? [], favorites: self.filterDictionary["favorites"]?[0] ?? "")
        })
    }
    
    func complexSearch(query: String, workoutType: String, muscles: [String], duration: String, equipmentLevel: String, equipment: [String], favorites: String) {
        print("query \(query), workoutType \(workoutType), muscles \(muscles), duration \(duration), equipmentLevel \(equipmentLevel), equipment \(equipment), favorites \(favorites)")
        
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

        self.showSpinner(onView: self.view)

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
        self.removeSpinner()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActivities = [Workout]()
        showGroups = true
        headerheight = 0
        cellheight = 397
        self.checkIfThereAnyActivities()
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
        var workout4 = [Workout]()
        var workout5 = [Workout]()
        var workout6 = [Workout]()
        
        // help you sync your data fetches together
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        self.workoutTypeReference = Database.database().reference().child("workouts").child("types_of_workouts")
        self.workoutTypeReference.child("workout_durations").child("short").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists(), let workoutsSnapshotValue = snapshot.value as! [String]? {
                dispatchGroup.leave()
                // no need to look up every workout at node
                for index in 0...19 {
                    let workoutID = workoutsSnapshotValue[index]
                    dispatchGroup.enter()
                    self.workoutReference = Database.database().reference().child("workouts").child("workouts")
                    self.workoutReference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                        if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                            if let workout = try? FirebaseDecoder().decode(Workout.self, from: workoutSnapshotValue) {
                                workout1.append(workout)
                                dispatchGroup.leave()

                            } else {
                                print("else")
                                print(workoutSnapshotValue)
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
                    self.groups.append(workout1)
                    self.collectionView.reloadData()
                    
                    dispatchGroup.enter()
                    self.workoutTypeReference.child("type_of_workouts").child("hiit").observeSingleEvent(of: .value, with: { (snapshot) in
                        if snapshot.exists(), let workoutsSnapshotValue = snapshot.value as! [String]? {
                            dispatchGroup.leave()
                            for workoutID in workoutsSnapshotValue {
                                dispatchGroup.enter()
                                self.workoutReference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                                    if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                                        if let workout = try? FirebaseDecoder().decode(Workout.self, from: workoutSnapshotValue) {
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
                                self.groups.append(workout2)
                                self.collectionView.reloadData()
                                
                                dispatchGroup.enter()
                                self.workoutTypeReference.child("type_of_workouts").child("cardio").observeSingleEvent(of: .value, with: { (snapshot) in
                                    if snapshot.exists(), let workoutsSnapshotValue = snapshot.value as! [String]? {
                                        dispatchGroup.leave()
                                        for index in 0...19 {
                                            let workoutID = workoutsSnapshotValue[index]
                                            dispatchGroup.enter()
                                            self.workoutReference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                                                if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                                                    if let workout = try? FirebaseDecoder().decode(Workout.self, from: workoutSnapshotValue) {
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
                                            self.groups.append(workout3)
                                            self.collectionView.reloadData()
                                            
                                            dispatchGroup.enter()
                                        self.workoutTypeReference.child("type_of_workouts").child("yoga").observeSingleEvent(of: .value, with: { (snapshot) in
                                            if snapshot.exists(), let workoutsSnapshotValue = snapshot.value as! [String]? {
                                                dispatchGroup.leave()
                                                for workoutID in workoutsSnapshotValue {
                                                    dispatchGroup.enter()
                                                    self.workoutReference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                                                        if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                                                            if let workout = try? FirebaseDecoder().decode(Workout.self, from: workoutSnapshotValue) {
                                                                workout4.append(workout)
                                                                dispatchGroup.leave()

                                                            }
                                                        }
                                                      })
                                                    { (error) in
                                                        dispatchGroup.leave()
                                                        print(error.localizedDescription)
                                                        self.sections.removeAll{ $0 == "Yoga"}
                                                    }
                                                }
                                                
                                                dispatchGroup.notify(queue: .main) {
                                                    self.groups.append(workout4)
                                                    self.collectionView.reloadData()
                                                    
                                                    dispatchGroup.enter()
                                                self.workoutTypeReference.child("workout_durations").child("medium").observeSingleEvent(of: .value, with: { (snapshot) in
                                                    if snapshot.exists(), let workoutsSnapshotValue = snapshot.value as! [String]? {
                                                        dispatchGroup.leave()
                                                        for workoutID in workoutsSnapshotValue {
                                                            dispatchGroup.enter()
                                                            self.workoutReference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                                                                if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                                                                    if let workout = try? FirebaseDecoder().decode(Workout.self, from: workoutSnapshotValue) {
                                                                        workout5.append(workout)
                                                                        dispatchGroup.leave()

                                                                    }
                                                                }
                                                              })
                                                            { (error) in
                                                                dispatchGroup.leave()
                                                                print(error.localizedDescription)
                                                                self.sections.removeAll{ $0 == "Medium Length"}
                                                            }
                                                        }
                                                        
                                                        dispatchGroup.notify(queue: .main) {
                                                            self.groups.append(workout5)
                                                            self.collectionView.reloadData()
                                                            
                                                            dispatchGroup.enter()
                                                        self.workoutTypeReference.child("type_of_workouts").child("workout").observeSingleEvent(of: .value, with: { (snapshot) in
                                                            if snapshot.exists(), let workoutsSnapshotValue = snapshot.value as! [String]? {
                                                                dispatchGroup.leave()
                                                                for index in 0...19 {
                                                                    let workoutID = workoutsSnapshotValue[index]
                                                                    dispatchGroup.enter()
                                                                    self.workoutReference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                                                                        if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                                                                            if let workout = try? FirebaseDecoder().decode(Workout.self, from: workoutSnapshotValue) {
                                                                                workout6.append(workout)
                                                                                dispatchGroup.leave()

                                                                            }
                                                                        }
                                                                      })
                                                                    { (error) in
                                                                        dispatchGroup.leave()
                                                                        print(error.localizedDescription)
                                                                        self.sections.removeAll{ $0 == "Strength"}
                                                                    }
                                                                }
                                                                
                                                                dispatchGroup.notify(queue: .main) {
                                                                    self.groups.append(workout6)
                                                                    self.collectionView.reloadData()
                                                                    
                                                                }
                                                            }
                                                        })
                                                        { (error) in
                                                            dispatchGroup.leave()
                                                            print(error.localizedDescription)
                                                            self.sections.removeAll{ $0 == "Strength"}
                                                        }
                                                            
                                                        }
                                                    }
                                                })
                                                { (error) in
                                                    dispatchGroup.leave()
                                                    print(error.localizedDescription)
                                                    self.sections.removeAll{ $0 == "Medium Length"}
                                                }
                                                    
                                                }
                                            }
                                        })
                                        { (error) in
                                            dispatchGroup.leave()
                                            print(error.localizedDescription)
                                            self.sections.removeAll{ $0 == "Yoga"}
                                        }
                                            
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
                cell.horizontalController.indexPathItem = indexPath.item
                cell.horizontalController.workouts = workouts
                cell.horizontalController.collectionView.reloadData()
                cell.horizontalController.didSelectHandler = { [weak self] workout, favAct in
                    if let workout = workout as? Workout {
                        print("workout \(String(describing: workout.title))")
                        let destination = WorkoutDetailViewController()
                        destination.favAct = favAct
                        destination.workout = workout
                        if let index = workouts.firstIndex(where: {$0.identifier == workout.identifier} ) {
                            destination.intColor = ((index + indexPath.item % 5) % 5)
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
                cell.horizontalController.removeControllerHandler = { [weak self] type, activity in
                    if type == "activity" {
                        let nav = self?.tabBarController!.viewControllers![1] as! UINavigationController
                        if nav.topViewController is MasterActivityContainerController {
                            let homeTab = nav.topViewController as! MasterActivityContainerController
                            homeTab.customSegmented.setIndex(index: 2)
                            homeTab.changeToIndex(index: 2)
                        }
                        self!.tabBarController?.selectedIndex = 1
                        self!.navigationController?.backToViewController(viewController: ActivityTypeViewController.self)
                    } else if type == "schedule" {
                        self!.updateSchedule(schedule: activity)
                        self!.navigationController?.backToViewController(viewController: CreateActivityViewController.self)
                    }
                }
                cell.horizontalController.favActHandler = { [weak self] favAct in
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
        header.verticalController.removeControllerHandler = { [weak self] type, activity in
            if type == "activity" {
                self!.navigationController?.backToViewController(viewController: ActivityViewController.self)
            } else if type == "schedule" {
                self!.updateSchedule(schedule: activity)
                self!.navigationController?.backToViewController(viewController: CreateActivityViewController.self)
            }
        }
        header.verticalController.favActHandler = { [weak self] favAct in
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
            searchActivities = [Workout]()
            self.filterDictionary = filterDictionary
            showGroups = true
            headerheight = 0
            cellheight = 397
            checkIfThereAnyActivities()
        }
    }
        
}
