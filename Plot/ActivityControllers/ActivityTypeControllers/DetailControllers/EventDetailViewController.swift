//
//  EventDetailViewController.swift
//  Plot
//
//  Created by Cory McHattie on 3/7/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import MapKit


class EventDetailViewController: ActivityDetailViewController {
    
    private let kActivityDetailCell = "ActivityDetailCell"
    private let kActivityExpandedDetailCell = "ActivityExpandedDetailCell"
    private let kEventDetailCell = "EventDetailCell"
    private let kAttractionDetailCell = "AttractionDetailCell"
    
    var event: Event?
    var attraction: Attraction?
    
    var events: [Event]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setActivity()
        
        if !active || !activeList {
            setMoreActivity()
        }
        
        if events == nil {
            fetchData()
        } else {
            updateData()
        }
            
        title = "Event"
                
        collectionView.register(ActivityDetailCell.self, forCellWithReuseIdentifier: kActivityDetailCell)
        collectionView.register(ActivityExpandedDetailCell.self, forCellWithReuseIdentifier: kActivityExpandedDetailCell)
        collectionView.register(EventDetailCell.self, forCellWithReuseIdentifier: kEventDetailCell)
        collectionView.register(AttractionDetailCell.self, forCellWithReuseIdentifier: kAttractionDetailCell)
        
                                        
    }
    
    fileprivate func setMoreActivity() {
        if let event = event {
            activity.activityType = activityType
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

            if locationName == "Location", let locationName = event.embedded?.venues?[0].address?.line1, let latitude = event.embedded?.venues?[0].location?.latitude, let longitude = event.embedded?.venues?[0].location?.longitude {
                let newLocationName = locationName.removeCharacters()
                self.locationName = newLocationName
                self.locationAddress = [newLocationName: [Double(latitude)!, Double(longitude)!]]
                activity.locationName = newLocationName
                activity.locationAddress = locationAddress
            }
            self.collectionView.reloadData()

        }
    }
    
    fileprivate func fetchData() {
        
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        
        if let event = self.event, let attractions = event.embedded?.attractions {
            let attraction = attractions[0]
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways {
                Service.shared.fetchEventsSegmentLatLong(size: "20", id: "", keyword: "", attractionId: attraction.id, venueId: "", postalCode: "", radius: "", unit: "", startDateTime: "", endDateTime: "", city: "", stateCode: "", countryCode: "", classificationName: "", classificationId: "", lat: self.locationManager.location?.coordinate.latitude ?? 0.0, long: self.locationManager.location?.coordinate.longitude ?? 0.0) { (search, err) in
                    self.events = search?.embedded?.events
                    if let events = self.events {
                        var i = 0
                        for tempEvent in events {
                            print("\(tempEvent.name)")
                            dispatchGroup.enter()
                            if tempEvent.id == event.id {
                                self.events!.remove(at: i)
                                dispatchGroup.leave()
                                break
                            }
                            i += 1
                            dispatchGroup.leave()
                        }
                    }
                    self.events = sortEvents(events: self.events ?? [])
                    dispatchGroup.leave()
                    dispatchGroup.notify(queue: .main) {
                        self.collectionView.reloadData()
                    }
                }
            } else {
                Service.shared.fetchEventsSegment(size: "20", id: "", keyword: "", attractionId: attraction.id, venueId: "", postalCode: "", radius: "", unit: "", startDateTime: "", endDateTime: "", city: "", stateCode: "", countryCode: "", classificationName: "", classificationId: "") { (search, err) in
                    self.events = search?.embedded?.events
                    if let events = self.events {
                        var i = 0
                        for tempEvent in events {
                            dispatchGroup.enter()
                            if tempEvent.id == event.id {
                                self.events!.remove(at: i)
                                dispatchGroup.leave()
                                break
                            }
                            i += 1
                            dispatchGroup.leave()
                        }
                    }
                    self.events = sortEvents(events: self.events!)
                    dispatchGroup.leave()
                    dispatchGroup.notify(queue: .main) {
                        self.collectionView.reloadData()
                    }
                }
            }
        }
    }
    
    fileprivate func updateData() {
        let dispatchGroup = DispatchGroup()
        var i = 0
        if let events = self.events, let event = event {
            for tempEvent in events {
                print("\(tempEvent.name)")
                dispatchGroup.enter()
                if tempEvent.id == event.id {
                    self.events!.remove(at: i)
                    dispatchGroup.leave()
                    break
                }
                i += 1
                dispatchGroup.leave()
            }
        }
        self.events = sortEvents(events: self.events!)
        dispatchGroup.notify(queue: .main) {
            self.collectionView.reloadData()
        }
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        if !activeList {
            return 4
        } else {
            return 3
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if !activeList {
            if section == 3 {
                if let events = events {
                    return events.count
                } else {
                    return 0
                }
            } else {
                return 1
            }
        } else {
            if section == 2 {
                if let events = events {
                    return events.count
                } else {
                    return 0
                }
            } else {
                return 1
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kActivityDetailCell, for: indexPath) as! ActivityDetailCell
            cell.delegate = self
            if let event = event {
                if let events = favAct["events"], events.contains(event.id) {
                    cell.heartButtonImage = "heart-filled"
                } else {
                    cell.heartButtonImage = "heart"
                }
                cell.active = active
                cell.activeList = activeList
                cell.event = event
                return cell
            } else if let attraction = attraction {
                cell.attraction = attraction
                return cell
            }
            else {
                return cell
            }
        } else if indexPath.section == 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kEventDetailCell, for: indexPath) as! EventDetailCell
            cell.delegate = self
            return cell
        } else if indexPath.section == 2 && !activeList {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kActivityExpandedDetailCell, for: indexPath) as! ActivityExpandedDetailCell
            cell.delegate = self
            if let event = event {
                cell.locationLabel.text = locationName
                cell.participantsLabel.text = userNamesString
                cell.rightReminderLabel.text = reminder
                if let startDateTime = startDateTime, let endDateTime = endDateTime {
                    dateFormatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                    cell.startDateLabel.text = dateFormatter.string(from: startDateTime)
                    cell.endDateLabel.text = dateFormatter.string(from: endDateTime)
                    cell.startDatePicker.date = startDateTime
                    cell.endDatePicker.date = endDateTime
                }
                cell.event = event
                return cell
            } else {
                return cell
            }
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kAttractionDetailCell, for: indexPath) as! AttractionDetailCell
            cell.delegate = self
            if let events = events {
                cell.count = indexPath.item + 1
                cell.event = events[indexPath.item]
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 328
        if indexPath.section == 0 {
            let dummyCell = ActivityDetailCell(frame: .init(x: 0, y: 0, width: view.frame.width, height: 1000))
            dummyCell.event = event
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: view.frame.width, height: 1000))
            height = estimatedSize.height
            return CGSize(width: view.frame.width, height: height)
        } else if indexPath.section == 1 {
            let dummyCell = EventDetailCell(frame: .init(x: 0, y: 0, width: view.frame.width, height: 17))
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: view.frame.width, height: 17))
            height = estimatedSize.height
            return CGSize(width: view.frame.width, height: height)
        } else if indexPath.section == 2 && !activeList {
            if secondSectionHeight == 0 {
                let dummyCell = ActivityExpandedDetailCell(frame: .init(x: 0, y: 0, width: view.frame.width, height: 150))
                dummyCell.event = event
                dummyCell.layoutIfNeeded()
                let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: view.frame.width, height: 150))
                height = estimatedSize.height
                secondSectionHeight = height
                return CGSize(width: view.frame.width, height: height)
            }
            else {
                return CGSize(width: view.frame.width, height: secondSectionHeight)
            }
        } else {
            let dummyCell = AttractionDetailCell(frame: .init(x: 0, y: 0, width: view.frame.width, height: 1000))
            dummyCell.event = events?[indexPath.item]
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: view.frame.width, height: 1000))
            height = estimatedSize.height
            return CGSize(width: view.frame.width, height: height)
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
     @objc fileprivate func openLocationFinder() {
            guard currentReachabilityStatus != .notReachable else {
                basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
                return
            }
            let destination = LocationFinderTableViewController()
            destination.delegate = self
            self.navigationController?.pushViewController(destination, animated: true)
    //        let navigationViewController = UINavigationController(rootViewController: destination)
    //        self.present(navigationViewController, animated: true, completion: nil)
        }
        
    //update so existing invitees are shown as selected
    @objc fileprivate func openParticipantsInviter() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        let destination = SelectActivityMembersViewController()
        var uniqueUsers = users
        for participant in selectedFalconUsers {
            if let userIndex = users.firstIndex(where: { (user) -> Bool in
                return user.id == participant.id }) {
                uniqueUsers[userIndex] = participant
            } else {
                uniqueUsers.append(participant)
            }
        }
        
        destination.ownerID = self.activity.admin
        destination.users = uniqueUsers
        destination.filteredUsers = uniqueUsers
        if !selectedFalconUsers.isEmpty{
            destination.priorSelectedUsers = selectedFalconUsers
        }
        
        destination.delegate = self
        
        if self.selectedFalconUsers.count > 0 && !schedule {
            let dispatchGroup = DispatchGroup()
            for user in self.selectedFalconUsers {
                dispatchGroup.enter()
                guard let currentUserID = Auth.auth().currentUser?.uid, let userID = user.id else {
                    dispatchGroup.leave()
                    continue
                }
                
                if userID == activity.admin {
                    if userID != currentUserID {
                        self.userInvitationStatus[userID] = .accepted
                    }
                    
                    dispatchGroup.leave()
                    continue
                }
                
                InvitationsFetcher.activityInvitation(forUser: userID, activityID: self.activity.activityID!) { (invitation) in
                    if let invitation = invitation {
                        self.userInvitationStatus[userID] = invitation.status
                    }
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.notify(queue: .main) {
                destination.userInvitationStatus = self.userInvitationStatus
                InvitationsFetcher.getAcceptedParticipant(forActivity: self.activity, allParticipants: self.selectedFalconUsers) { acceptedParticipant in
                    self.acceptedParticipant = acceptedParticipant
                    self.navigationController?.pushViewController(destination, animated: true)
                }
            }
        } else {
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    @objc func goToChat() {
        if activity.conversationID != nil {
            if let convo = conversations.first(where: {$0.chatID == activity!.conversationID}) {
                self.chatLogController = ChatLogController(collectionViewLayout: AutoSizingCollectionViewFlowLayout())
                self.messagesFetcher = MessagesFetcher()
                self.messagesFetcher?.delegate = self
                self.messagesFetcher?.loadMessagesData(for: convo)
            }
        } else {
            let destination = ChooseChatTableViewController()
            let navController = UINavigationController(rootViewController: destination)
            destination.delegate = self
            destination.activity = activity
            destination.conversations = conversations
            destination.pinnedConversations = conversations
            destination.filteredConversations = conversations
            destination.filteredPinnedConversations = conversations
            present(navController, animated: true, completion: nil)
        }
    }
}

extension EventDetailViewController: ActivityExpandedDetailCellDelegate {
    func startDateChanged(startDate: Date) {
        startDateTime = startDate
        activity.startDateTime = NSNumber(value: Int((startDate).timeIntervalSince1970))
        collectionView.reloadData()
        if self.active {
            self.scheduleReminder()
        }
    }
    
    func endDateChanged(endDate: Date) {
        endDateTime = endDate
        activity.endDateTime = NSNumber(value: Int((endDate).timeIntervalSince1970))
        collectionView.reloadData()
    }
    
    func locationViewTapped(labelText: String) {
        print("labelText \(labelText)")
        
        openLocationFinder()
        
    }
    
    func infoViewTapped() {
        print("infoview")
        
        guard let latitude = locationAddress[locationName]?[0], let longitude = locationAddress[locationName]?[1] else {
            return
        }
        
        let ceo: CLGeocoder = CLGeocoder()
        let loc: CLLocation = CLLocation(latitude:latitude, longitude: longitude)
        var addressString : String = ""
        ceo.reverseGeocodeLocation(loc) { (placemark, error) in
            if error != nil {
                return
            }
            let place = placemark![0]
            if place.subThoroughfare != nil {
                addressString = addressString + place.subThoroughfare! + " "
            }
            if place.thoroughfare != nil {
                addressString = addressString + place.thoroughfare! + ", "
            }
            if place.locality != nil {
                addressString = addressString + place.locality! + ", "
            }
            if place.country != nil {
                addressString = addressString + place.country! + ", "
            }
            if place.postalCode != nil {
                addressString = addressString + place.postalCode!
            }
            
            let alertController = UIAlertController(title: self.locationName, message: addressString, preferredStyle: .alert)
            let mapAddress = UIAlertAction(title: "Map Address", style: .default) { (action:UIAlertAction) in
                self.goToMap(locationAddress: self.locationAddress)
            }
            let copyAddress = UIAlertAction(title: "Copy Address", style: .default) { (action:UIAlertAction) in
                let pasteboard = UIPasteboard.general
                pasteboard.string = addressString
            }
            let changeAddress = UIAlertAction(title: "Change Address", style: .default) { (action:UIAlertAction) in
                self.openLocationFinder()
            }
            let removeAddress = UIAlertAction(title: "Remove Address", style: .default) { (action:UIAlertAction) in
                self.locationAddress[self.locationName] = nil
                if let localAddress = self.activity.locationAddress, localAddress[self.locationName] != nil {
                    self.activity.locationAddress![self.locationName] = nil
                }
                self.activity.locationName = "Location"
                self.locationName = "Location"
                self.collectionView.reloadData()
            }
            let cancelAlert = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction) in
                print("You've pressed cancel")
                
            }
            alertController.addAction(mapAddress)
            alertController.addAction(copyAddress)
            alertController.addAction(changeAddress)
            alertController.addAction(removeAddress)
            alertController.addAction(cancelAlert)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func participantsViewTapped(labelText: String) {
        print("labelText \(labelText)")
        openParticipantsInviter()
        
    }
    
    func startViewTapped(isHidden: String) {
        if isHidden == "true" {
            secondSectionHeight -= 200
        } else {
            secondSectionHeight += 200
        }
        collectionView.reloadData()
        
    }
    
    func endViewTapped(isHidden: String) {
        if isHidden == "true" {
            secondSectionHeight -= 200
        } else {
            secondSectionHeight += 200
        }
        collectionView.reloadData()
        
    }
    
    func reminderViewTapped(labelText: String) {
        print("labelText \(labelText)")
        
        let alertController = UIAlertController(title: "Reminder", message: nil, preferredStyle: .alert)
        
        let noneAddress = UIAlertAction(title: EventAlert.None.rawValue, style: .default) { (action:UIAlertAction) in
            print("none")
            self.reminder = EventAlert.None.description
            self.collectionView.reloadData()
            self.activity.reminder = EventAlert.None.description
            if self.active {
                self.scheduleReminder()
            }
        }
        let atTimeAddress = UIAlertAction(title: EventAlert.At_time_of_event.rawValue, style: .default) { (action:UIAlertAction) in
            print("atTimeAddress")
            self.reminder = EventAlert.At_time_of_event.description
            self.collectionView.reloadData()
            self.activity.reminder = EventAlert.At_time_of_event.description
            if self.active {
                self.scheduleReminder()
            }

        }
        let fifteenAddress = UIAlertAction(title: EventAlert.Fifteen_Minutes.rawValue, style: .default) { (action:UIAlertAction) in
            print("fifteenAddress")
            self.reminder = EventAlert.Fifteen_Minutes.description
            self.collectionView.reloadData()
            self.activity.reminder = EventAlert.Fifteen_Minutes.description
            if self.active {
                self.scheduleReminder()
            }
        }
        let halfHourAddress = UIAlertAction(title: EventAlert.Half_Hour.rawValue, style: .default) { (action:UIAlertAction) in
            print("halfHourAddress")
            self.reminder = EventAlert.Half_Hour.description
            self.collectionView.reloadData()
            self.activity.reminder = EventAlert.Half_Hour.description
            if self.active {
                self.scheduleReminder()
            }
        }
        let oneHourAddress = UIAlertAction(title: EventAlert.One_Hour.rawValue, style: .default) { (action:UIAlertAction) in
            print("oneHourAddress")
            self.reminder = EventAlert.One_Hour.description
            self.collectionView.reloadData()
            self.activity.reminder = EventAlert.One_Hour.description
            if self.active {
                self.scheduleReminder()
            }
        }
        let oneDayAddress = UIAlertAction(title: EventAlert.One_Day.rawValue, style: .default) { (action:UIAlertAction) in
            print("oneDayAddress")
            self.reminder = EventAlert.One_Day.description
            self.collectionView.reloadData()
            self.activity.reminder = EventAlert.One_Day.description
            if self.active {
                self.scheduleReminder()
            }
        }
        let oneWeekAddress = UIAlertAction(title: EventAlert.One_Week.rawValue, style: .default) { (action:UIAlertAction) in
            print("oneWeekAddress")
            self.reminder = EventAlert.One_Week.description
            self.collectionView.reloadData()
            self.activity.reminder = EventAlert.One_Week.description
            if self.active {
                self.scheduleReminder()
            }
        }
        let oneMonthAddress = UIAlertAction(title: EventAlert.One_Month.rawValue, style: .default) { (action:UIAlertAction) in
            print("oneMonthAddress")
            self.reminder = EventAlert.One_Month.description
            self.collectionView.reloadData()
            self.activity.reminder = EventAlert.One_Month.description
            if self.active {
                self.scheduleReminder()
            }
        }
        let cancelAlert = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction) in
            print("You've pressed cancel")
            
        }
        alertController.addAction(noneAddress)
        alertController.addAction(atTimeAddress)
        alertController.addAction(fifteenAddress)
        alertController.addAction(halfHourAddress)
        alertController.addAction(oneHourAddress)
        alertController.addAction(oneDayAddress)
        alertController.addAction(oneWeekAddress)
        alertController.addAction(oneMonthAddress)
        alertController.addAction(cancelAlert)
        self.present(alertController, animated: true, completion: nil)
        
    }
    
}

extension EventDetailViewController: EventDetailCellDelegate {
    func viewTapped() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        let destination = WebViewController()
        if let event = event, let url = event.url {
            destination.urlString = url
            destination.controllerTitle = "Tickets"
            let navigationViewController = UINavigationController(rootViewController: destination)
            navigationViewController.modalPresentationStyle = .fullScreen
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }
}

extension EventDetailViewController: AttractionDetailCellDelegate {
    func viewTapped(event: Event) {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        let destination = EventDetailViewController()
        destination.hidesBottomBarWhenPushed = true
        destination.favAct = favAct
        destination.event = event
        destination.events = events
        destination.users = self.users
        destination.filteredUsers = self.filteredUsers
        destination.conversations = self.conversations
        self.navigationController!.pushViewController(destination, animated: true)
    }
}

extension EventDetailViewController: UpdateInvitees {
    func updateInvitees(selectedFalconUsers: [User]) {
        if !schedule {
            if !selectedFalconUsers.isEmpty {
                self.selectedFalconUsers = selectedFalconUsers
                self.acceptedParticipant = acceptedParticipant.filter { selectedFalconUsers.contains($0) }
                
                var participantCount = self.acceptedParticipant.count
                // If user is creating this activity (admin)
                if activity.admin == nil || activity.admin == Auth.auth().currentUser?.uid {
                    participantCount += 1
                }
                
                if participantCount > 1 {
                    self.userNamesString = "\(participantCount) participants"
                } else {
                    self.userNamesString = "1 participant"
                }
            } else {
                self.selectedFalconUsers = selectedFalconUsers
                self.acceptedParticipant = selectedFalconUsers
                self.userNamesString = "1 participant"
            }
            collectionView.reloadData()
            
            if active {
                showActivityIndicator()
                let createActivity = ActivityActions(activity: activity, active: active, selectedFalconUsers: selectedFalconUsers)
                createActivity.updateActivityParticipants()
                hideActivityIndicator()
                
            }
        } else if schedule {
            self.userNamesString = "Participants"
            if !selectedFalconUsers.isEmpty {
                self.selectedFalconUsers = selectedFalconUsers
            } else {
                self.selectedFalconUsers = selectedFalconUsers
            }
            collectionView.reloadData()
        }
    }
}

extension EventDetailViewController: UpdateLocationDelegate {
    func updateLocation(locationName: String, locationAddress: [String : [Double]], zipcode: String, city: String, state: String, country: String) {
        self.locationAddress[self.locationName] = nil
        if self.activity.locationAddress != nil {
            self.activity.locationAddress![self.locationName] = nil
        }
        for (key, value) in locationAddress {
            let newLocationName = key.removeCharacters()
            self.locationName = newLocationName
            self.locationAddress[newLocationName] = value
            collectionView.reloadData()
            
            self.activity.locationName = newLocationName
            if activity.locationAddress == nil {
                self.activity.locationAddress = self.locationAddress
            } else {
                self.activity.locationAddress![newLocationName] = value
            }
        }
    }
}

extension EventDetailViewController: ChooseChatDelegate {
    func chosenChat(chatID: String, activityID: String?, grocerylistID: String?, checklistID: String?, packinglistID: String?, activitylistID: String?) {
        if let activityID = activityID {
            if let conversation = conversations.first(where: {$0.chatID == chatID}) {
                if conversation.activities != nil {
                       var activities = conversation.activities!
                       activities.append(activityID)
                       let updatedActivities = ["activities": activities as AnyObject]
                       Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
                   } else {
                       let updatedActivities = ["activities": [activityID] as AnyObject]
                       Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
                   }
               }
            let updatedConversationID = ["conversationID": chatID as AnyObject]
            Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder).updateChildValues(updatedConversationID)
        }
    }
}
