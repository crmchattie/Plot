//
//  StateController.swift
//  Plot
//
//  Created by Cory McHattie on 12/24/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

extension NSNotification.Name {
    static let variablesUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".variablesUpdated")
    static let hasLoadedListGoalActivities = NSNotification.Name(Bundle.main.bundleIdentifier! + ".hasLoadedListGoalActivities")
}

class NetworkController {
    private var isRunning: Bool
    var isGoalRunning: Bool
    
    let activityService = ActivityService()
    let financeService = FinanceService()
    let healthService = HealthService()
    let userService = UserService()
    let conversationService = ConversationService()
    let listService = ListService()
    let trackingService = TrackingService()
    
    let activityDetailService = ActivityDetailService()
    let healthDetailService = HealthDetailService()
    let financeDetailService = FinanceDetailService()
    
    var isOldUser = false
    
    var timeGoalsSetup = false
    var healthGoalsSetup = false
    var financeGoalsSetup = false
    
    var hasLoadedListGoalActivities = false {
        didSet {
            NotificationCenter.default.post(name: .hasLoadedListGoalActivities, object: nil)
        }
    }
    
    init() {
        isRunning = false
        isGoalRunning = false
        addObservers()
    }
    
    func setupKeyVariables(_ completion: @escaping () -> Void) {
        guard !isRunning else {
            completion()
            return
        }
        
        isRunning = true
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        print("grabActivities")
        activityService.grabActivities {
            print("done grabActivities")
            dispatchGroup.leave()
        }
        dispatchGroup.enter()
        print("grabFinances")
        financeService.grabFinances {
            print("done grabFinances")
            dispatchGroup.leave()
        }
        dispatchGroup.enter()
        print("grabHealth")
        healthService.grabHealth {
            print("done grabHealth")
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            completion()
            print("checkGoalsForCompletion")
            self.checkGoalsForCompletion() {
                print("done checkGoalsForCompletion")
                self.hasLoadedListGoalActivities = true
                self.isRunning = false
                self.isGoalRunning = false
            }
        }
    }
    
    func setupFirebase() {
        print("setupFirebase")
        activityService.setupFirebase {}
        financeService.setupFirebase {}
        healthService.setupFirebase {}

    }
    
    func setupOtherVariables() {
        userService.grabContacts()
    }
    
    func reloadKeyVariables(_ completion: @escaping () -> Void) {
        guard !isRunning else {
            completion()
            return
        }
        
        isRunning = true
        hasLoadedListGoalActivities = false
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        print("regrabActivities")
        activityService.regrabActivities {
            print("done regrabActivities")
            dispatchGroup.leave()
        }
        dispatchGroup.enter()
        print("regrabFinances")
        financeService.regrabFinances {
            print("done regrabFinances")
            dispatchGroup.leave()
        }
        dispatchGroup.enter()
        print("regrabHealth")
        healthService.regrabHealth {
            print("done regrabHealth")
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            completion()
            print("checkGoalsForCompletion")
            self.checkGoalsForCompletion() {
                print("done checkGoalsForCompletion")
                self.hasLoadedListGoalActivities = true
                self.isRunning = false
                self.isGoalRunning = false
            }
        }
    }
    
    func checkGoals(_ completion: @escaping () -> Void) {
        print("checkGoals")
        guard !isRunning else {
            completion()
            return
        }
                
        isRunning = true
        hasLoadedListGoalActivities = false
        
        print("checkGoalsForCompletion")
        self.checkGoalsForCompletion() {
            print("done checkGoalsForCompletion")
            self.hasLoadedListGoalActivities = true
            self.isRunning = false
            self.isGoalRunning = false
            completion()
        }
    }
        
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(oldUserLoggedIn), name: .oldUserLoggedIn, object: nil)
    }
    
    @objc fileprivate func oldUserLoggedIn() {
        isOldUser = true
    }
    
    func askPermissionToTrack() {
        trackingService.requestPermission()
    }
    
    func newUserItems() {
        sendWelcomeMessage()
    }
    
    func sendUserTextMessage(type_of_user: String, completion: @escaping () -> Void) {
        Service.shared.sendUserTextMessage(type_of_user: type_of_user) { (json, err) in
            completion()
        }
    }
}

extension NetworkController {
    func updateUserActivities() {
        print("updateUserActivities")
        let ref = Database.database().reference()
        ref.child(activitiesEntity).observeSingleEvent(of: .value, with: { snapshot in
            let IDs = snapshot.value as? [String: AnyObject] ?? [:]
            for (ID, info) in IDs {
                let values = info as? [String: [String: AnyObject]] ?? [:]
                for (_, value) in values {
                    let activity = Activity(dictionary: value)
                    if let participants = activity.participantsIDs {
                        for memberID in participants {
                            let userReference = Database.database().reference().child(userActivitiesEntity).child(memberID).child(ID).child(messageMetaDataFirebaseFolder)
                            userReference.observeSingleEvent(of: .value) { snapshot in
                                if snapshot.exists() {
                                    print(activity.name)
                                    print(memberID)
                                    print(activity.startDateTime)
                                    let values: [String : Any] = ["startDateTime": activity.startDateTime as Any,
                                                                  "recurrences": activity.recurrences as Any]
                                    userReference.updateChildValues(values)
                                }
                            }
                        }
                    }
                }
            }
        })
    }
    func updateUserWorkouts() {
        print("updateUserWorkouts")
        let ref = Database.database().reference()
        ref.child(workoutsEntity).observeSingleEvent(of: .value, with: { snapshot in
            let IDs = snapshot.value as? [String: AnyObject] ?? [:]
            for (_, info) in IDs {
                let value = info as? [String: AnyObject] ?? [:]
                if let workout = try? FirebaseDecoder().decode(Workout.self, from: value), let participants = workout.participantsIDs {
                    for memberID in participants {
                        let userReference = Database.database().reference().child(userWorkoutsEntity).child(memberID).child(workout.id)
                        userReference.observeSingleEvent(of: .value) { snapshot in
                            if snapshot.exists() {
                                do {
                                    let value = try FirebaseEncoder().encode(workout.startDateTime)
                                    let values: [String : Any] = ["startDateTime": value]
                                    userReference.updateChildValues(values)
                                } catch let error {
                                    print(error)
                                }
                            }
                        }
                    }
                }
            }
        })
    }
    func updateUserMindfulness() {
        print("updateUserMindfulness")
        let ref = Database.database().reference()
        ref.child(mindfulnessEntity).observeSingleEvent(of: .value, with: { snapshot in
            let IDs = snapshot.value as? [String: AnyObject] ?? [:]
            for (_, info) in IDs {
                let value = info as? [String: AnyObject] ?? [:]
                if let mindfulness = try? FirebaseDecoder().decode(Mindfulness.self, from: value), let participants = mindfulness.participantsIDs {
                    for memberID in participants {
                        let userReference = Database.database().reference().child(userMindfulnessEntity).child(memberID).child(mindfulness.id)
                        userReference.observeSingleEvent(of: .value) { snapshot in
                            if snapshot.exists() {
                                do {
                                    let value = try FirebaseEncoder().encode(mindfulness.startDateTime)
                                    let values: [String : Any] = ["startDateTime": value]
                                    userReference.updateChildValues(values)
                                } catch let error {
                                    print(error)
                                }
                            }
                        }
                        
                    }
                }
            }
        })
    }
    func updateUserMood() {
        print("updateUserMood")
        let ref = Database.database().reference()
        ref.child(moodEntity).observeSingleEvent(of: .value, with: { snapshot in
            let IDs = snapshot.value as? [String: AnyObject] ?? [:]
            for (_, info) in IDs {
                let value = info as? [String: AnyObject] ?? [:]
                if let mood = try? FirebaseDecoder().decode(Mood.self, from: value), let participants = mood.participantsIDs {
                    for memberID in participants {
                        let userReference = Database.database().reference().child(userMoodEntity).child(memberID).child(mood.id)
                        userReference.observeSingleEvent(of: .value) { snapshot in
                            if snapshot.exists() {
                                do {
                                    let value = try FirebaseEncoder().encode(mood.moodDate)
                                    let values: [String : Any] = ["moodDate": value as Any]
                                    userReference.updateChildValues(values)
                                } catch let error {
                                    print(error)
                                }
                            }
                        }
                        
                    }
                }
            }
        })
    }
    func updateUserTransaction() {
        print("updateUserTransaction")
        let ref = Database.database().reference()
        ref.child(financialTransactionsEntity).observeSingleEvent(of: .value, with: { snapshot in
            let IDs = snapshot.value as? [String: AnyObject] ?? [:]
            for (_, info) in IDs {
                let value = info as? [String: AnyObject] ?? [:]
                if let transaction = try? FirebaseDecoder().decode(Transaction.self, from: value), let participants = transaction.participantsIDs {
                    for memberID in participants {
                        let userReference = Database.database().reference().child(userFinancialTransactionsEntity).child(memberID).child(transaction.guid)
                        userReference.observeSingleEvent(of: .value) { snapshot in
                            if snapshot.exists() {
                                let values: [String : Any] = ["transacted_at": transaction.transacted_at as Any]
                                userReference.updateChildValues(values)
                            }
                        }
                    }
                }
            }
        })
    }
    
    func createNewUserActivities() {
        let currentUserID = Auth.auth().currentUser?.uid
        
        let activityID = Database.database().reference().child(userActivitiesEntity).child(currentUserID!).childByAutoId().key ?? ""
        let checklistID = Database.database().reference().child(userChecklistsEntity).child(currentUserID!).childByAutoId().key ?? ""
        
        let dispatchGroup = DispatchGroup()
        guard let mainActivitiesUrl = Bundle.main.url(forResource: "NewUserActivities", withExtension: "json") else { return }
        
        do {
            let jsonData = try Data(contentsOf: mainActivitiesUrl)
            let decoder = JSONDecoder()
            let activities = try decoder.decode([Activity].self, from: jsonData)
            
            for activity in activities {
                activity.activityID = activityID
                activity.checklistIDs = [checklistID]
                activity.admin = currentUserID
                activity.participantsIDs = [currentUserID!]
                
                var dateComponents = DateComponents()
                dateComponents.year = Date.yearNumber(Date())()
                dateComponents.month = Date.monthNumber(Date())()
                dateComponents.day = Date.dayNumber(Date())()
                dateComponents.timeZone = TimeZone.current
                dateComponents.hour = 17
                dateComponents.minute = 20
                
                // Create date from components
                let userCalendar = Calendar.current
                let someDateTime = userCalendar.date(from: dateComponents)!
                
                let timezone = TimeZone.current
                let seconds = TimeInterval(timezone.secondsFromGMT(for: someDateTime))
                let startDateTime = Date().addingTimeInterval(seconds)
                let endDateTime = startDateTime.addingTimeInterval(512100)
                activity.startDateTime = NSNumber(value: Int((startDateTime).timeIntervalSince1970))
                activity.endDateTime = NSNumber(value: Int((endDateTime).timeIntervalSince1970))
                activity.allDay = true
                
//                for schedule in activity.schedule! {
//                    dispatchGroup.enter()
//                    switch schedule.name {
//                    case "Flight from EWR to DUB":
//                        schedule.startDateTime = activity.startDateTime
//                        schedule.endDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(41400)).timeIntervalSince1970))
//                        schedule.allDay = false
//                        schedule.participantsIDs = [currentUserID!]
//                    case "Flight from DUB to EDI":
//                        schedule.startDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(79500)).timeIntervalSince1970))
//                        schedule.endDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(84300)).timeIntervalSince1970))
//                        schedule.allDay = false
//                        schedule.participantsIDs = [currentUserID!]
//                    case "Edinburgh":
//                        schedule.startDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(172800)).timeIntervalSince1970))
//                        schedule.endDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(345600)).timeIntervalSince1970))
//                        schedule.allDay = true
//                        schedule.participantsIDs = [currentUserID!]
//                    case "Aizle Reservation":
//                        schedule.startDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(182400)).timeIntervalSince1970))
//                        schedule.endDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(189600)).timeIntervalSince1970))
//                        schedule.allDay = false
//                        schedule.participantsIDs = [currentUserID!]
//                    case "Kitchin Reservation":
//                        schedule.startDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(268800)).timeIntervalSince1970))
//                        schedule.endDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(276000)).timeIntervalSince1970))
//                        schedule.allDay = false
//                        schedule.participantsIDs = [currentUserID!]
//                    case "St. Andrews":
//                        schedule.startDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(353400)).timeIntervalSince1970))
//                        schedule.endDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(526200)).timeIntervalSince1970))
//                        schedule.allDay = true
//                        schedule.participantsIDs = [currentUserID!]
//                    case "Flight from EDI to DUB":
//                        schedule.startDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(490200)).timeIntervalSince1970))
//                        schedule.endDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(495000)).timeIntervalSince1970))
//                        schedule.allDay = false
//                        schedule.participantsIDs = [currentUserID!]
//                    case "Flight from DUB to EWR":
//                        schedule.startDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(502800)).timeIntervalSince1970))
//                        schedule.endDateTime = NSNumber(value: Int((startDateTime.addingTimeInterval(512100)).timeIntervalSince1970))
//                        schedule.allDay = false
//                        schedule.participantsIDs = [currentUserID!]
//                    default:
//                        schedule.startDateTime = activity.startDateTime
//                        schedule.endDateTime = activity.endDateTime
//                        schedule.allDay = false
//                        schedule.participantsIDs = [currentUserID!]
//                    }
//                    dispatchGroup.leave()
//                }
                
                
                let activityDict = activity.toAnyObject()
                let activityReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
                dispatchGroup.enter()
                activityReference.updateChildValues(activityDict) { (error, reference) in
                    dispatchGroup.leave()
                }
                
                let userReference = Database.database().reference().child(userActivitiesEntity).child(currentUserID!).child(activityID).child(messageMetaDataFirebaseFolder)
                let values:[String : Any] = ["isGroupActivity": true]
                dispatchGroup.enter()
                userReference.updateChildValues(values, withCompletionBlock: { (error, reference) in
                    dispatchGroup.leave()
                })
            }
        } catch {
            print("new user error")
            print(error)
        }
        
        guard let mainChecklistsUrl = Bundle.main.url(forResource: "NewUserChecklists", withExtension: "json") else { return }
        
        do {
            let jsonData = try Data(contentsOf: mainChecklistsUrl)
            let decoder = JSONDecoder()
            let checklists = try decoder.decode([Checklist].self, from: jsonData)
            
            for checklist in checklists {
                checklist.ID = checklistID
                checklist.activityID = activityID
                checklist.admin = currentUserID
                checklist.participantsIDs = [currentUserID!]
                
                let checklistDict = checklist.toAnyObject()
                let checklistReference = Database.database().reference().child(checklistsEntity).child(checklistID)
                dispatchGroup.enter()
                checklistReference.updateChildValues(checklistDict) { (error, reference) in
                    dispatchGroup.leave()
                }
                
                let userReference = Database.database().reference().child(userChecklistsEntity).child(currentUserID!).child(checklistID)
                let values:[String : Any] = ["isGroupChecklist": true]
                dispatchGroup.enter()
                userReference.updateChildValues(values, withCompletionBlock: { (error, reference) in
                    dispatchGroup.leave()
                })
            }
        } catch {
            print("new user error")
            print(error)
        }
        
        dispatchGroup.notify(queue: .main) {
            
        }
    }
    
    func sendWelcomeMessage() {
        repeat {} while Auth.auth().currentUser?.uid == nil
        let dispatchGroup = DispatchGroup()
        let currentUserID = Auth.auth().currentUser?.uid
        let chatID = Database.database().reference().child("user-messages").child(currentUserID!).childByAutoId().key ?? ""
        let groupChatsReference = Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder)
        let plotUser = "acdmpzhmDWaBdcEo17DRMt8gwCh1"
        let memberIDs = [currentUserID!: currentUserID!, plotUser: plotUser]
        let childValues: [String: AnyObject] = ["chatID": chatID as AnyObject, "chatName": "Plot" as AnyObject, "chatParticipantsIDs": memberIDs as AnyObject, "admin": currentUserID as AnyObject, "adminNeeded": false as AnyObject, "isGroupChat": true as AnyObject]
        
        dispatchGroup.enter()
        groupChatsReference.updateChildValues(childValues)
        dispatchGroup.leave()
        
        for (key, _) in memberIDs {
            dispatchGroup.enter()
            let userReference = Database.database().reference().child("user-messages").child(key).child(chatID).child(messageMetaDataFirebaseFolder)
            let values:[String : Any] = ["isGroupChat": true]
            userReference.updateChildValues(values)
            dispatchGroup.leave()
        }
        
        let text = "Welcome to Plot! If you have any questions, thoughts and/or concerns, just send us a message here! Enjoy Plotting"
//        "Hi, thanks for downloading Plot! I’m the founder of Plot and am reaching out to see if you are available for a quick call (< 20 min) to help improve the product? If so, a $20 Amazon gift card is coming your way. Thanks for reading and enjoying Plotting!"
        let messageReference = Database.database().reference().child("messages").childByAutoId()
        guard let messageUID = messageReference.key else { return }
        let messageStatus = messageStatusDelivered
        let timestamp = NSNumber(value: Int(Date().timeIntervalSince1970))
        let defaultData: [String: AnyObject] = ["messageUID": messageUID as AnyObject,
                                                "toId": chatID as AnyObject,
                                                "status": messageStatus as AnyObject,
                                                "seen": false as AnyObject,
                                                "fromId": plotUser as AnyObject,
                                                "timestamp": timestamp,
                                                "text": text as AnyObject]
        dispatchGroup.enter()
        messageReference.updateChildValues(defaultData)
        dispatchGroup.leave()
        
        for (key, _) in memberIDs {
            dispatchGroup.enter()
            let userReference = Database.database().reference().child("user-messages").child(key).child(chatID).child(userMessagesFirebaseFolder)
            userReference.updateChildValues([messageUID: 1])
            
            let ref = Database.database().reference().child("user-messages").child(key).child(chatID).child(messageMetaDataFirebaseFolder)
            ref.updateChildValues(["lastMessageID": messageUID])
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            self.conversationService.conversationsFetcher.fetchConversations()
        }
    }
}
