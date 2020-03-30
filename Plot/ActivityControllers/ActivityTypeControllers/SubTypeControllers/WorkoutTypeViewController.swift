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
    var searchWorkouts = [Workout]()

    var filters: [filter] = [.cuisine, .excludeCuisine, .diet, .intolerances, .type]
    var filterDictionary = [String: [String]]()
    var sections: [String] = ["Quick", "HIIT", "Cardio"]

            
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Workouts"

        let doneBarButton = UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(filter))
        navigationItem.rightBarButtonItem = doneBarButton

        setupSearchBar()
        
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
            self.complexSearch(query: searchText.lowercased(), cuisine: self.filterDictionary["cuisine"] ?? [""], excludeCuisine: self.filterDictionary["excludeCuisine"] ?? [""], diet: self.filterDictionary["diet"]?[0] ?? "", intolerances: self.filterDictionary["intolerances"] ?? [""], type: self.filterDictionary["type"]?[0] ?? "")
        })
    }
    
    func complexSearch(query: String, cuisine: [String], excludeCuisine: [String], diet: String, intolerances: [String], type: String) {
//        print("query \(query), cuisine \(cuisine), excludeCuisine \(excludeCuisine), diet \(diet), intolerances \(intolerances), type \(type), ")
//
//        self.searchEvents = [Event]()
//        showGroups = false
//        self.headerheight = view.frame.height
//        self.cellheight = 0
//        self.collectionView.reloadData()
//
//        if let navController = self.navigationController {
//            self.showSpinner(onView: navController.view)
//        } else {
//            self.showSpinner(onView: self.view)
//        }
//
//        let dispatchGroup = DispatchGroup()
//
//        dispatchGroup.enter()
//        Service.shared.fetchRecipesComplex(query: query, cuisine: cuisine, excludeCuisine: excludeCuisine, diet: diet, intolerances: intolerances, type: type) { (search, err) in
//            if let err = err {
//                print("Failed to fetch apps:", err)
//                return
//            }
//            self.removeSpinner()
//            self.searchEvents = search!.recipes
//
//            dispatchGroup.leave()
//
//            DispatchQueue.main.async {
//                self.collectionView.reloadData()
//            }
//        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchWorkouts = [Workout]()
        showGroups = true
        headerheight = 0
        cellheight = 397
        self.collectionView.reloadData()
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
        cell.horizontalController.favAct = favAct
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
                        destination.hidesBottomBarWhenPushed = true
                        destination.favAct = favAct
                        destination.workout = workout
                        if let index = workouts.firstIndex(where: {$0.identifier == workout.identifier} ) {
                            destination.intColor = (index % 5)
                        }
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
        let workouts = searchWorkouts
        header.verticalController.favAct = favAct
        header.verticalController.workouts = workouts
        header.verticalController.collectionView.reloadData()
        header.verticalController.didSelectHandler = { [weak self] workout, favAct in
            if let workout = workout as? Workout {
                print("workout \(String(describing: workout.title))")
                let destination = WorkoutDetailViewController()
                destination.hidesBottomBarWhenPushed = true
                destination.favAct = favAct
                destination.workout = workout
                if let index = workouts.firstIndex(where: {$0.identifier == workout.identifier} ) {
                    destination.intColor = (index % 5)
                }
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

extension WorkoutTypeViewController: ActivityTypeCellDelegate {
    func viewTapped(labelText: String) {
        print(labelText)
    }
}

extension WorkoutTypeViewController: UpdateFilter {
    func updateFilter(filterDictionary : [String: [String]]) {
        if !filterDictionary.values.isEmpty {
            showGroups = false
            self.filterDictionary = filterDictionary
            complexSearch(query: "", cuisine: filterDictionary["cuisine"] ?? [""], excludeCuisine: filterDictionary["excludeCuisine"] ?? [""], diet: filterDictionary["diet"]?[0] ?? "", intolerances: filterDictionary["intolerances"] ?? [""], type: filterDictionary["type"]?[0] ?? "")
        } else {
            searchWorkouts = [Workout]()
            self.filterDictionary = filterDictionary
            showGroups = true
            headerheight = 0
            cellheight = 397
            self.collectionView.reloadData()
        }
    }
        
}
