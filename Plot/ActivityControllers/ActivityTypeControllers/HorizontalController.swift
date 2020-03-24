//
//  HorizontalController.swift
//  Plot
//
//  Created by Cory McHattie on 1/4/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase

class HorizontalController: HorizontalSnappingController, UICollectionViewDelegateFlowLayout {
    
    fileprivate var databaseReference: DatabaseReference!
    
    private let kActivitySubTypeCell = "ActivitySubTypeCell"
    
    var cellData: Any?
    var customActivities: [ActivityType]?
    var recipes: [Recipe]?
    var events: [Event]?
    var attractions: [Attraction]?
    var workouts: [Workout]?
    
    var users = [User]()
    var filteredUsers = [User]()
    var conversations = [Conversation]()
    var favAct = [String: [String]]()
    
    let activityIndicatorView: UIActivityIndicatorView = {
        let aiv = UIActivityIndicatorView(style: .whiteLarge)
        aiv.color = .darkGray
        aiv.startAnimating()
        aiv.hidesWhenStopped = true
        return aiv
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        collectionView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        collectionView.register(ActivitySubTypeCell.self, forCellWithReuseIdentifier: kActivitySubTypeCell)
        collectionView.contentInset = .init(top: 0, left: 16, bottom: 10, right: 16)
        
        view.addSubview(activityIndicatorView)
        activityIndicatorView.centerInSuperview()

    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }
    
    var didSelectHandler: ((Any, [String: [String]]) -> ())?
        
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("item selected")
        if recipes != nil {
            if let recipe = recipes?[indexPath.item] {
                didSelectHandler?(recipe, favAct)
            }
        } else if events != nil {
            if let event = events?[indexPath.item] {
                didSelectHandler?(event, favAct)
            }
        } else if workouts != nil {
            if let workout = workouts?[indexPath.item] {
                didSelectHandler?(workout, favAct)
            }
        } else if attractions != nil {
            if let attraction = attractions?[indexPath.item] {
                didSelectHandler?(attraction, favAct)
            }
        }
        else {
            
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if recipes != nil {
            return recipes!.count
        } else if events != nil {
            return events!.count
        } else if workouts != nil {
            return workouts!.count
        } else if attractions != nil {
            return attractions!.count
        }
        else {
            return 0
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kActivitySubTypeCell, for: indexPath) as! ActivitySubTypeCell
        cell.delegate = self
        if recipes != nil {
            self.activityIndicatorView.stopAnimating()
            let recipe = recipes![indexPath.item]
            if let recipes = favAct["recipes"], recipes.contains("\(recipe.id)") {
                cell.heartButtonImage = "heart-filled"
            } else {
                cell.heartButtonImage = "heart"
            }
            cell.recipe = recipe
            cell.event = nil
            cell.workout = nil
            cell.attraction = nil
            return cell
        } else if events != nil {
            self.activityIndicatorView.stopAnimating()
            let event = events![indexPath.item]
            if let events = favAct["events"], events.contains(event.id) {
                cell.heartButtonImage = "heart-filled"
            } else {
                cell.heartButtonImage = "heart"
            }
            cell.event = event
            cell.recipe = nil
            cell.workout = nil
            cell.attraction = nil
            return cell
        } else if workouts != nil {
            self.activityIndicatorView.stopAnimating()
            let workout = workouts![indexPath.item]
            if let workouts = favAct["workouts"], workouts.contains(workout.identifier) {
                cell.heartButtonImage = "heart-filled"
            } else {
                cell.heartButtonImage = "heart"
            }
            cell.intColor = (indexPath.item % 5)
            cell.workout = workout
            cell.event = nil
            cell.recipe = nil
            cell.attraction = nil
            return cell
        } else if attractions != nil {
            self.activityIndicatorView.stopAnimating()
            let attraction = attractions![indexPath.item]
            cell.attraction = attraction
            if let attractions = favAct["attractions"], attractions.contains(attraction.id) {
                cell.heartButtonImage = "heart-filled"
            } else {
                cell.heartButtonImage = "heart"
            }
            cell.event = nil
            cell.workout = nil
            cell.recipe = nil
            return cell
        }
        else {
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: view.frame.width - 48, height: view.frame.height)
    }

    
}

extension HorizontalController: ActivitySubTypeCellDelegate {
    func plusButtonTapped() {
        print("plusButtonTapped")
    }
    
    func shareButtonTapped() {
        print("shareButtonTapped")
    }
    
    func heartButtonTapped(type: Any) {
        print("heartButtonTapped")
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
            } else if let workout = type as? Workout {
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
            }
        }
        
    }
}
