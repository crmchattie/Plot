//
//  VerticalController.swift
//  Plot
//
//  Created by Cory McHattie on 1/20/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase

class VerticalController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    private let kActivitySubTypeCell = "ActivitySubTypeCell"
    
    var customActivities: [ActivityType]?
    var recipes: [Recipe]?
    var events: [Event]?
    var workouts: [Workout]?
    var attractions: [Attraction]?
    
    var users = [User]()
    var filteredUsers = [User]()
    var conversations = [Conversation]()
    var favAct = [String: [String]]()
    
    var activityObject: ActivityObject?
    
    init() {
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        collectionView!.collectionViewLayout = layout
        
        collectionView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        collectionView.register(ActivitySubTypeCell.self, forCellWithReuseIdentifier: kActivitySubTypeCell)
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
        if customActivities != nil {
            return customActivities!.count
        } else if recipes != nil {
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.init(top: 0, left: 10, bottom: 10, right: 10)
    }
    
        
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: view.frame.width - 48, height: 367)
    }
    
}

extension VerticalController: ActivitySubTypeCellDelegate {
    func plusButtonTapped(type: Any) {
        print("plusButtonTapped")
    }
    
    func shareButtonTapped(activityObject: ActivityObject) {
        self.activityObject = activityObject
        
        let alert = UIAlertController(title: "Share Activity", message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Inside of Plot", style: .default, handler: { (_) in
            print("User click Approve button")
            let destination = ChooseChatTableViewController()
            let navController = UINavigationController(rootViewController: destination)
            destination.delegate = self
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
        

        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))

        self.present(alert, animated: true, completion: {
            print("completion block")
        })
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

extension VerticalController: UpdateChatDelegate {
    
    func updateChat(chatID: String, activityID: String?) {
        if let conversation = self.conversations.first(where: { $0.chatID! == chatID}), let activityObject = activityObject {
            let messageSender = MessageSender(conversation, text: activityObject.activityName, media: nil, activity: activityObject)
            messageSender.sendMessage()

        }
    }
}
