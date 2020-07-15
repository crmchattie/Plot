//
//  RecipeTypeViewController.swift
//  Plot
//
//  Created by Cory McHattie on 1/20/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase

class RecipeTypeViewController: ActivitySubTypeViewController, UISearchBarDelegate {
    
    var sections: [ActivitySection] = [.american, .italian, .vegetarian, .mexican, .breakfast, .dessert]
    var groups = [ActivitySection: [Recipe]]()
    var searchActivities = [Recipe]()
    fileprivate var movingBackwards: Bool = true

    var filters: [filter] = [.cuisine, .excludeCuisine, .diet, .intolerances, .recipeType]
    var filterDictionary = [String: [String]]()
    
    weak var recipeDelegate : UpdateRecipeDelegate?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Recipes"
                
        let doneBarButton = UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(filter))
        navigationItem.rightBarButtonItem = doneBarButton

        searchController.searchBar.delegate = self
        
        fetchData()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.movingBackwards {
            self.recipeDelegate?.updateRecipe(recipe: nil)
        }
    }
    
    lazy var diffableDataSource: UICollectionViewDiffableDataSource<ActivitySection, AnyHashable> = .init(collectionView: self.collectionView) { (collectionView, indexPath, object) -> UICollectionViewCell? in
        if let object = object as? ActivityType {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kActivityHeaderCell, for: indexPath) as! ActivityHeaderCell
            cell.intColor = (indexPath.item % 5)
            cell.activityType = object
            return cell
        } else if let object = object as? GroupItem {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kActivityTypeCell, for: indexPath) as! ActivityTypeCell
            cell.delegate = self
            if let places = self.favAct["places"], places.contains(object.venue?.id ?? "") {
                cell.heartButtonImage = "heart-filled"
            } else {
                cell.heartButtonImage = "heart"
            }
            cell.intColor = (indexPath.item % 5)
            cell.imageURL = self.sections[indexPath.section].image
            cell.fsVenue = object.venue
            return cell
        } else if let object = object as? FSVenue {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kActivityTypeCell, for: indexPath) as! ActivityTypeCell
            cell.delegate = self
            if let places = self.favAct["places"], places.contains(object.id) {
                cell.heartButtonImage = "heart-filled"
            } else {
                cell.heartButtonImage = "heart"
            }
            cell.intColor = (indexPath.item % 5)
            cell.imageURL = self.sections[indexPath.section].image
            cell.fsVenue = object
            return cell
        } else if let object = object as? Event {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kActivityTypeCell, for: indexPath) as! ActivityTypeCell
            cell.delegate = self
            if let events = self.favAct["events"], events.contains(object.id) {
                cell.heartButtonImage = "heart-filled"
            } else {
                cell.heartButtonImage = "heart"
            }
            cell.intColor = (indexPath.item % 5)
            cell.imageURL = self.sections[indexPath.section].image
            cell.event = object
            return cell
        } else if let object = object as? SygicPlace {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kActivityTypeCell, for: indexPath) as! ActivityTypeCell
            cell.delegate = self
            if let places = self.favAct["places"], places.contains(object.id) {
                cell.heartButtonImage = "heart-filled"
            } else {
                cell.heartButtonImage = "heart"
            }
            cell.intColor = (indexPath.item % 5)
            cell.imageURL = self.sections[indexPath.section].image
            cell.sygicPlace = object
            return cell
        } else if let object = object as? Workout {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kActivityTypeCell, for: indexPath) as! ActivityTypeCell
            cell.delegate = self
            if let workouts = self.favAct["workouts"], workouts.contains(object.identifier) {
                cell.heartButtonImage = "heart-filled"
            } else {
                cell.heartButtonImage = "heart"
            }
            cell.intColor = (indexPath.item % 5)
            cell.imageURL = self.sections[indexPath.section].image
            cell.workout = object
            return cell
        } else if let object = object as? Recipe {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kActivityTypeCell, for: indexPath) as! ActivityTypeCell
            cell.delegate = self
            if let recipes = self.favAct["recipes"], recipes.contains("\(object.id)") {
                cell.heartButtonImage = "heart-filled"
            } else {
                cell.heartButtonImage = "heart"
            }
            cell.intColor = (indexPath.item % 5)
            cell.imageURL = self.sections[indexPath.section].image
            cell.recipe = object
            return cell
        }
        return nil
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        movingBackwards = false
        let object = diffableDataSource.itemIdentifier(for: indexPath)
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
            destination.schedule = self.schedule
            destination.umbrellaActivity = self.umbrellaActivity
            destination.delegate = self
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
            destination.activities = self.activities
            destination.conversation = self.conversation
            destination.schedule = self.schedule
            destination.umbrellaActivity = self.umbrellaActivity
            destination.delegate = self
            self.navigationController?.pushViewController(destination, animated: true)
        } else if let workout = object as? Workout {
            print("workout \(String(describing: workout.title))")
            let destination = WorkoutDetailViewController()
            destination.hidesBottomBarWhenPushed = true
            destination.favAct = favAct
            destination.workout = workout
            destination.intColor = (indexPath.item % 5)
            destination.users = self.users
            destination.filteredUsers = self.filteredUsers
            destination.conversations = self.conversations
            destination.activities = self.activities
            destination.conversation = self.conversation
            destination.schedule = self.schedule
            destination.umbrellaActivity = self.umbrellaActivity
            destination.delegate = self
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
            destination.activities = self.activities
            destination.conversation = self.conversation
            destination.schedule = self.schedule
            destination.umbrellaActivity = self.umbrellaActivity
            destination.delegate = self
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
            self.complexSearch(query: searchText.lowercased(), cuisine: self.filterDictionary["cuisine"] ?? [], excludeCuisine: self.filterDictionary["excludeCuisine"] ?? [], diet: self.filterDictionary["diet"]?[0] ?? "", intolerances: self.filterDictionary["intolerances"] ?? [""], type: self.filterDictionary["recipeType"]?[0] ?? "", favorites: self.filterDictionary["favorites"]?[0] ?? "")
        })
    }
    
    func complexSearch(query: String, cuisine: [String], excludeCuisine: [String], diet: String, intolerances: [String], type: String, favorites: String) {
        print("query \(query), cuisine \(cuisine), excludeCuisine \(excludeCuisine), diet \(diet), intolerances \(intolerances), type \(type), favorites \(favorites)")
        
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
                                
        let dispatchGroup = DispatchGroup()
        
        if favorites == "true" {
            if let recipes = self.favAct["recipes"] {
                for recipeID in recipes {
                    var recipe: Recipe!
                    var include = true
                    dispatchGroup.enter()
                    Service.shared.fetchRecipesInfo(id: Int(recipeID)!) { (search, err) in
                        recipe = search
                        for type in cuisine {
                            if let cuisines = recipe.cuisines, cuisines.contains(type) {
                                include = true
                                break
                            } else {
                                include = false
                            }
                        }
                        if include == true {
                            for type in excludeCuisine {
                                if let cuisines = recipe.cuisines, cuisines.contains(type) {
                                    include = false
                                    break
                                } else {
                                    include = true
                                }
                            }
                        }
                        if diet != "" && include == true {
                            if let diets = recipe.diets, diets.contains(diet) {
                                include = true
                            } else {
                                include = false
                            }
                        }
                        if type != "" && include == true {
                            if let types = recipe.dishTypes, types.contains(type) {
                                include = true
                            } else {
                                include = false
                            }
                        }
                        if include {
                            self.searchActivities.append(recipe)
                        }
                        dispatchGroup.leave()
                    }
                }
            }
        } else {
            dispatchGroup.enter()
            Service.shared.fetchRecipesComplex(query: query, cuisine: cuisine, excludeCuisine: excludeCuisine, diet: diet, intolerances: intolerances, type: type) { (search, err) in
                if let err = err {
                    print("Failed to fetch apps:", err)
                    return
                }
                
                self.searchActivities = search!.recipes
                                
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            activityIndicatorView.stopAnimating()
            if !self.searchActivities.isEmpty {
                snapshot.appendSections([.search])
                snapshot.appendItems(self.searchActivities, toSection: .search)
                self.diffableDataSource.apply(snapshot)
            } else {
                self.checkIfThereAnyActivities()
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
        
        var snapshot = self.diffableDataSource.snapshot()
        
        // help you sync your data fetches together
        let dispatchGroup = DispatchGroup()
        
        for section in sections {
            if let object = groups[section] {
                activityIndicatorView.stopAnimating()
                snapshot.appendSections([section])
                snapshot.appendItems(object, toSection: section)
                self.diffableDataSource.apply(snapshot)
                continue
            } else if section.subType == "Cuisine" {
                dispatchGroup.enter()
                Service.shared.fetchRecipesComplex(query: "", cuisine: [section.searchTerm], excludeCuisine: [""], diet: "", intolerances: [""], type: "") { (search, err) in
                    dispatchGroup.leave()
                    if let object = search?.recipes {
                        self.groups[section] = object
                    } else {
                        self.sections.removeAll(where: {$0 == section})
                    }
                }
            } else if section.subType == "Diet" {
                dispatchGroup.enter()
                Service.shared.fetchRecipesComplex(query: "", cuisine: [""], excludeCuisine: [""], diet: section.searchTerm, intolerances: [""], type: "") { (search, err) in
                    dispatchGroup.leave()
                    if let object = search?.recipes {
                        self.groups[section] = object
                    } else {
                        self.sections.removeAll(where: {$0 == section})
                    }
                }
            } else {
                dispatchGroup.enter()
                Service.shared.fetchRecipesComplex(query: section.searchTerm, cuisine: [""], excludeCuisine: [""], diet: "", intolerances: [""], type: "") { (search, err) in
                    dispatchGroup.leave()
                    if let object = search?.recipes {
                        self.groups[section] = object
                    } else {
                        self.sections.removeAll(where: {$0 == section})
                    }
                }
            }
            dispatchGroup.notify(queue: .main) {
                if let object = self.groups[section] {
                    activityIndicatorView.stopAnimating()
                    snapshot.appendSections([section])
                    snapshot.appendItems(object, toSection: section)
                    self.diffableDataSource.apply(snapshot)
                }
            }
        }
    }
    
    func checkIfThereAnyActivities() {
        if searchActivities.count > 0 || showGroups {
            viewPlaceholder.remove(from: view, priority: .medium)
        } else {
            viewPlaceholder.add(for: view, title: .emptyRecipes, subtitle: .emptyRecipesEvents, priority: .medium, position: .top)
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

extension RecipeTypeViewController: ActivityTypeCellDelegate {
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
                self.movingBackwards = false
                self.recipeDelegate!.updateRecipe(recipe: recipe)
                self.navigationController?.backToViewController(viewController: GrocerylistViewController.self)
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
        } else if let place = type as? FSVenue {
            activity.name = place.name
            activity.activityType = "place"
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
                                
                self.delegate?.updateSchedule(schedule: self.activity)
                if let recipeID = self.activity.recipeID {
                    self.delegate?.updateIngredients(recipe: nil, recipeID: recipeID)
                }
                
                self.movingBackwards = false
                self.navigationController?.backToViewController(viewController: CreateActivityViewController.self)
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
                let nav = self.tabBarController!.viewControllers![1] as! UINavigationController
                if nav.topViewController is MasterActivityContainerController {
                    let homeTab = nav.topViewController as! MasterActivityContainerController
                    homeTab.customSegmented.setIndex(index: 2)
                    homeTab.changeToIndex(index: 2)
                }
                self.tabBarController?.selectedIndex = 1
                self.navigationController?.backToViewController(viewController: ActivityTypeViewController.self)
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
        

        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))

        self.present(alert, animated: true, completion: {
            print("completion block")
        })
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
}

extension RecipeTypeViewController: UpdateFilter {
    func updateFilter(filterDictionary : [String: [String]]) {
        if !filterDictionary.values.isEmpty {
            showGroups = false
            self.filterDictionary = filterDictionary
            complexSearch(query: "", cuisine: filterDictionary["cuisine"] ?? [], excludeCuisine: filterDictionary["excludeCuisine"] ?? [], diet: filterDictionary["diet"]?[0] ?? "", intolerances: filterDictionary["intolerances"] ?? [], type: filterDictionary["recipeType"]?[0] ?? "", favorites: self.filterDictionary["favorites"]?[0] ?? "")
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

extension RecipeTypeViewController: UpdateRecipeDelegate {
    func updateRecipe(recipe: Recipe?) {
        self.recipeDelegate?.updateRecipe(recipe: recipe)
    }
}

extension RecipeTypeViewController: ChooseActivityDelegate {
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
                self.movingBackwards = false
                let nav = self.tabBarController!.viewControllers![1] as! UINavigationController
                if nav.topViewController is MasterActivityContainerController {
                    let homeTab = nav.topViewController as! MasterActivityContainerController
                    homeTab.customSegmented.setIndex(index: 2)
                    homeTab.changeToIndex(index: 2)
                }
                self.tabBarController?.selectedIndex = 1
                self.navigationController?.backToViewController(viewController: ActivityTypeViewController.self)
            }
        }
    }
}
