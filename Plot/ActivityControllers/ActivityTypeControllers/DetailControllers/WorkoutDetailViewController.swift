//
//  WorkoutDetailViewController.swift
//  Plot
//
//  Created by Cory McHattie on 3/9/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase

class WorkoutDetailViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    private let kActivityDetailCell = "ActivityDetailCell"
    private let kWorkoutDetailCell = "WorkoutDetailCell"
    private let kExerciseDetailCell = "ExerciseDetailCell"
    
    var sections = [String]()
    
    var users = [User]()
    var filteredUsers = [User]()
    var conversations = [Conversation]()
    var favAct = [String: [String]]()
    
    var workout: Workout?
    var intColor: Int = 0
    
    fileprivate var reference: DatabaseReference!
            
    init() {
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
            
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = true
        
        title = "Workout"
        
        extendedLayoutIncludesOpaqueBars = true
        definesPresentationContext = true
        edgesForExtendedLayout = UIRectEdge.top
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        collectionView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        collectionView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        collectionView.register(ActivityDetailCell.self, forCellWithReuseIdentifier: kActivityDetailCell)
        collectionView.register(WorkoutDetailCell.self, forCellWithReuseIdentifier: kWorkoutDetailCell)
        collectionView.register(ExerciseDetailCell.self, forCellWithReuseIdentifier: kExerciseDetailCell)
        
        if favAct.isEmpty {
            fetchFavAct()
        }

                                        
    }
    
    fileprivate func fetchFavAct() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        self.reference = Database.database().reference().child("user-fav-activities").child(currentUserID)
        self.reference.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists(), let favoriteActivitiesSnapshot = snapshot.value as? [String: [String]] {
                print("snapshot exists")
                self.favAct = favoriteActivitiesSnapshot
                self.collectionView.reloadData()
            }
        })
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }

    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 2 {
            if let exercises = workout?.exercises {
                return exercises.count
            } else {
                return 0
            }
        } else {
            return 1
        }
    }
        
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kActivityDetailCell, for: indexPath) as! ActivityDetailCell
            cell.delegate = self
            if let workout = workout {
                if let workouts = favAct["workouts"], workouts.contains(workout.identifier) {
                    cell.heartButtonImage = "heart-filled"
                } else {
                    cell.heartButtonImage = "heart"
                }
                cell.intColor = intColor
                cell.workout = workout
            }
            return cell
        } else if indexPath.section == 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kWorkoutDetailCell, for: indexPath) as! WorkoutDetailCell
            if let workout = workout {
                cell.workout = workout
                cell.delegate = self
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kExerciseDetailCell, for: indexPath) as! ExerciseDetailCell
            if let workout = workout {
                cell.count = indexPath.item + 1
                cell.exercise = workout.exercises![indexPath.item]
                cell.delegate = self
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 328
        if indexPath.section == 0 {
            let dummyCell = ActivityDetailCell(frame: .init(x: 0, y: 0, width: view.frame.width, height: 328))
            dummyCell.workout = workout
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: view.frame.width, height: 328))
            height = estimatedSize.height
            print("height: \(height)")
            return CGSize(width: view.frame.width, height: height)
        } else if indexPath.section == 1 {
            let dummyCell = WorkoutDetailCell(frame: .init(x: 0, y: 0, width: view.frame.width, height: 50))
            dummyCell.workout = workout
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: view.frame.width, height: 50))
            height = estimatedSize.height
            print("height: \(height)")
            return CGSize(width: view.frame.width, height: height)
        } else {
            let dummyCell = ExerciseDetailCell(frame: .init(x: 0, y: 0, width: view.frame.width, height: 30))
            dummyCell.exercise = workout?.exercises![indexPath.item]
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: view.frame.width, height: 30))
            height = estimatedSize.height
            print("height: \(height)")
            return CGSize(width: view.frame.width, height: height)
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

extension WorkoutDetailViewController: ActivityDetailCellDelegate {
    func plusButtonTapped(type: Any) {
        print("plusButtonTapped")
    }
    
    func shareButtonTapped(id: String) {
        print("shareButtonTapped")
    }
    
    func heartButtonTapped(type: Any) {
        print("heartButtonTapped")
        if let currentUserID = Auth.auth().currentUser?.uid {
            let databaseReference = Database.database().reference().child("user-fav-activities").child(currentUserID)
            if let workout = type as? Workout {
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
            }
        }
        
    }

}

extension WorkoutDetailViewController: WorkoutDetailCellDelegate {
    func viewTapped() {
        
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        
        if let workout = workout {
            print("view tapped")
            let destination = WebViewController()
            destination.urlString = "https://workoutlabs.com/fit/wkt/\(workout.identifier)/?app=plot"
            destination.controllerTitle = "Workout"
            let navigationViewController = UINavigationController(rootViewController: destination)
            navigationViewController.modalPresentationStyle = .fullScreen
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }
}

