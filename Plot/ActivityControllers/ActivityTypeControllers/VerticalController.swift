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
    var groupItems: [GroupItem]?
    var sygicPlaces: [SygicPlace]?
    
    var users = [User]()
    var filteredUsers = [User]()
    var selectedFalconUsers = [User]()
    var activities = [Activity]()
    var conversations = [Conversation]()
    var conversation : Conversation?
    var favAct = [String: [String]]()
    var activity: Activity!
    
    var umbrellaActivity: Activity!
    weak var delegate : UpdateScheduleDelegate?
    weak var recipeDelegate : UpdateRecipeDelegate?
    var schedule: Bool = false
    var activeRecipe: Bool = false
    
    var startDateTime: Date?
    var endDateTime: Date?
        
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
        
        addObservers()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
    }
    
    @objc fileprivate func changeTheme() {
        collectionView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        collectionView.reloadData()
        
    }
    
    var didSelectHandler: ((Any, [String: [String]]) -> ())?
    var removeControllerHandler: ((String, Activity) -> ())?
    var favActHandler: (([String: [String]]) -> ())?
    var recipeUpdate: ((Recipe) -> ())?
        
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
        } else if groupItems != nil {
            if let groupItem = groupItems?[indexPath.item].venue {
                didSelectHandler?(groupItem, favAct)
            }
        } else if sygicPlaces != nil {
            if let place = sygicPlaces?[indexPath.item] {
                didSelectHandler?(place, favAct)
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
        } else if groupItems != nil {
            return groupItems!.count
        } else if sygicPlaces != nil {
            return sygicPlaces!.count
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
            cell.fsVenue = nil
            cell.sygicPlace = nil
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
            cell.fsVenue = nil
            cell.sygicPlace = nil
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
            cell.fsVenue = nil
            cell.sygicPlace = nil
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
            cell.fsVenue = nil
            cell.sygicPlace = nil
            return cell
        } else if groupItems != nil {
            let fsVenue = groupItems![indexPath.item].venue
            cell.fsVenue = fsVenue
            if let groupItems = favAct["groupItems"], groupItems.contains(fsVenue!.id) {
                cell.heartButtonImage = "heart-filled"
            } else {
                cell.heartButtonImage = "heart"
            }
            cell.intColor = (indexPath.item % 5)
            cell.event = nil
            cell.workout = nil
            cell.recipe = nil
            cell.sygicPlace = nil
            cell.attraction = nil
            return cell
        } else if sygicPlaces != nil {
            let sygicPlace = sygicPlaces![indexPath.item]
            cell.sygicPlace = sygicPlace
            if let sygicPlaces = favAct["sygicPlaces"], sygicPlaces.contains(sygicPlace.id) {
                cell.heartButtonImage = "heart-filled"
            } else {
                cell.heartButtonImage = "heart"
            }
            cell.intColor = (indexPath.item % 5)
            cell.event = nil
            cell.workout = nil
            cell.recipe = nil
            cell.attraction = nil
            cell.fsVenue = nil
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
    
    func showActivityIndicator() {
        if let navController = self.navigationController {
            self.showSpinner(onView: navController.view)
        } else {
            self.showSpinner(onView: self.view)
        }
        self.navigationController?.view.isUserInteractionEnabled = false
    }

    func hideActivityIndicator() {
        self.navigationController?.view.isUserInteractionEnabled = true
        self.removeSpinner()
    }
    
    func getSelectedFalconUsers(forActivity activity: Activity, completion: @escaping ([User])->()) {
        guard let participantsIDs = activity.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        var selectedFalconUsers = [User]()
        let group = DispatchGroup()
        for id in participantsIDs {
            // Only if the current user is created this activity
            if activity.admin == currentUserID && id == currentUserID {
                continue
            }
            
            group.enter()
            let participantReference = Database.database().reference().child("users").child(id)
            participantReference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), var dictionary = snapshot.value as? [String: AnyObject] {
                    dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                    let user = User(dictionary: dictionary)
                    selectedFalconUsers.append(user)
                }
                group.leave()
            })
        }
        
        group.notify(queue: .main) {
            completion(selectedFalconUsers)
        }
    }
    
}

extension VerticalController: ActivitySubTypeCellDelegate {
    func plusButtonTapped(type: Any) {
        print("plusButtonTapped")
        
        if activeRecipe {
            if let recipe = type as? Recipe {
                var updatedRecipe = recipe
                if updatedRecipe.title.contains("/") {
                    updatedRecipe.title = updatedRecipe.title.replacingOccurrences(of: "/", with: "")
                }
                if updatedRecipe.title.contains(".") {
                    updatedRecipe.title = updatedRecipe.title.replacingOccurrences(of: ".", with: "")
                }
                if updatedRecipe.title.contains("#") {
                    updatedRecipe.title = updatedRecipe.title.replacingOccurrences(of: "#", with: "")
                }
                if updatedRecipe.title.contains("$") {
                    updatedRecipe.title = updatedRecipe.title.replacingOccurrences(of: "$", with: "")
                }
                if updatedRecipe.title.contains("[") {
                    updatedRecipe.title = updatedRecipe.title.replacingOccurrences(of: "[", with: "")
                }
                if updatedRecipe.title.contains("]") {
                    updatedRecipe.title = updatedRecipe.title.replacingOccurrences(of: "]", with: "")
                }
                self.recipeUpdate?(updatedRecipe)
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
            activity.activityType = "recipe"
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
        } else if let workout = type as? Workout {
            activity.name = workout.title
            activity.activityType = "workout"
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
            activity.activityType = "event"
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
                var newLocationName = locationName
                if newLocationName.contains("/") {
                    newLocationName = newLocationName.replacingOccurrences(of: "/", with: "")
                }
                if newLocationName.contains(".") {
                    newLocationName = newLocationName.replacingOccurrences(of: ".", with: "")
                }
                if newLocationName.contains("#") {
                    newLocationName = newLocationName.replacingOccurrences(of: "#", with: "")
                }
                if newLocationName.contains("$") {
                    newLocationName = newLocationName.replacingOccurrences(of: "$", with: "")
                }
                if newLocationName.contains("[") {
                    newLocationName = newLocationName.replacingOccurrences(of: "[", with: "")
                }
                if newLocationName.contains("]") {
                    newLocationName = newLocationName.replacingOccurrences(of: "]", with: "")
                }
                activity.locationName = newLocationName
                activity.locationAddress = [newLocationName: [Double(latitude)!, Double(longitude)!]]
            }
        } else if let attraction = type as? Attraction {
            activity.name = attraction.name
        } else {
            return
        }
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if schedule, let _ = umbrellaActivity {
            alert.addAction(UIAlertAction(title: "Add to Schedule", style: .default, handler: { (_) in
                print("User click Approve button")
                
//                self.delegate?.updateSchedule(schedule: self.activity)
//                if let recipeID = self.activity.recipeID {
//                    self.delegate?.updateIngredients(recipe: nil, recipeID: recipeID)
//                }
                self.removeControllerHandler?("schedule", self.activity)
                
            }))
            
        } else if !schedule {
            alert.addAction(UIAlertAction(title: "Create New Activity", style: .default, handler: { (_) in
                print("User click Approve button")
                // create new activity
                                                    
                self.showActivityIndicator()
                let createActivity = ActivityActions(activity: self.activity, active: false, selectedFalconUsers: [])
                createActivity.createNewActivity()
                self.hideActivityIndicator()
                self.removeControllerHandler?("activity", self.activity)
                                                    
            }))
            
            alert.addAction(UIAlertAction(title: "Merge with Existing Activity", style: .default, handler: { (_) in
                    
                    // ChooseActivityTableViewController
                    let destination = ChooseActivityTableViewController()
                    let navController = UINavigationController(rootViewController: destination)
                    destination.delegate = self
                    destination.activity = self.activity
                    destination.activities = self.activities
                    destination.filteredActivities = self.activities
                    self.present(navController, animated: true, completion: nil)
            
            }))

        }
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))

        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
    
    func shareButtonTapped(activityObject: ActivityObject) {
        
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
                    self.favActHandler?(self.favAct)
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
                    self.favActHandler?(self.favAct)
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
                    self.favActHandler?(self.favAct)
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
                    self.favActHandler?(self.favAct)
                })
            }
        }
    }
    
}

extension VerticalController: ChooseActivityDelegate {
    func chosenActivity(mergeActivity: Activity) {
        if let activity = activity {
            let dispatchGroup = DispatchGroup()
            if mergeActivity.recipeID != nil || mergeActivity.workoutID != nil || mergeActivity.eventID != nil {
                if let currentUserID = Auth.auth().currentUser?.uid {
                    let newActivityID = Database.database().reference().child("user-activities").child(currentUserID).childByAutoId().key ?? ""
                    let newActivity = mergeActivity.copy() as! Activity
                    newActivity.activityID = newActivityID
                    newActivity.recipeID = nil
                    newActivity.workoutID = nil
                    newActivity.eventID = nil
                    
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
                self.removeControllerHandler?("activity", activity)
            }
        }
    }
}
