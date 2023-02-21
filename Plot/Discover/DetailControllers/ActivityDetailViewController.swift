//
//  ActivityDetailViewController.swift
//  Plot
//
//  Created by Cory McHattie on 4/10/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import MapKit


class ActivityDetailViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    var umbrellaActivity: Activity!
    
    weak var delegate : UpdateActivityDelegate?
    var activity: Activity!
    
    var sections = [String]()
    
    var users = [User]()
    var filteredUsers = [User]()
    var selectedFalconUsers = [User]()
    var acceptedParticipant: [User] = []
    var activities = [Activity]()
    var conversations = [Conversation]()
    var listList = [ListContainer]()
    var conversation: Conversation?
    var favAct = [String: [String]]()
    
    var userNames : [String] = []
    var userNamesString: String = ""
    
    var activityName: String = ""
    
    var locationName: String = "Location"
    var locationAddress = [String : [Double]]()
    
    var startDateTime: Date?
    var endDateTime: Date?
    
    var reminder: String = "None"
    
    var schedule: Bool = false
    var active: Bool = false
    var activeList: Bool = false
    var listType: String?
    
    var activityType: String!
    
    var activityID = String()
    
    let dispatchGroup = DispatchGroup()
    
    var invitation: Invitation?
    var userInvitationStatus: [String: Status] = [:]
    let invitationsEntity = "invitations"
    let userInvitationsEntity = "user-invitations"
            
    var secondSectionHeight: CGFloat = 0
        
    var reference: DatabaseReference!
    
    var locationManager = CLLocationManager()
    
    let dateFormatter = DateFormatter()
    
    var chatLogController: ChatLogController? = nil
    var messagesFetcher: MessagesFetcher? = nil
    
    var segment: Int = 0
        
    init() {
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.isHidden = false
        navigationItem.largeTitleDisplayMode = .never
        
        extendedLayoutIncludesOpaqueBars = true
        definesPresentationContext = true
        edgesForExtendedLayout = UIRectEdge.top
        view.backgroundColor = .systemGroupedBackground
        collectionView.indicatorStyle = .default
        collectionView.backgroundColor = .systemGroupedBackground
    
                        
        if favAct.isEmpty {
            fetchFavAct()
        }
        
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .short
        
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    func setActivity() {
        if let activity = activity {
            active = true
            if let activityID = activity.activityID {
                self.activityID = activityID
            }
            if let name = activity.name {
                self.activityName = name
            }
            if let localName = activity.locationName, localName != "Location", let localAddress = activity.locationAddress {
                locationName = localName
                locationAddress = localAddress
            }
            if let startDate = activity.startDateTime, let endDate = activity.endDateTime {
                startDateTime = Date(timeIntervalSince1970: startDate as! TimeInterval)
                endDateTime = Date(timeIntervalSince1970: endDate as! TimeInterval)
            }
            if let reminder = activity.reminder {
                self.reminder = reminder
            }
            if umbrellaActivity == nil {
                resetBadgeForSelf()
            }
        } else if schedule {
            activityID = UUID().uuidString
            activity = Activity(dictionary: ["activityID": activityID as AnyObject])
        } else if !schedule {
            if let currentUserID = Auth.auth().currentUser?.uid {
                activityID = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key ?? ""
                activity = Activity(dictionary: ["activityID": activityID as AnyObject])
            }
        }
        
        if !schedule {
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
        } else if schedule {
            userNamesString = "Participants"
            if let participants = activity.participantsIDs {
                for ID in participants {
                    // users equals ACTIVITY selected falcon users
                    if let user = users.first(where: {$0.id == ID}) {
                        selectedFalconUsers.append(user)
                    }
                }
            }

        }
        collectionView.reloadData()
    }
    
    func fetchFavAct() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWithClose(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        self.reference = Database.database().reference().child(userFavActivitiesEntity).child(currentUserID)
        self.reference.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists(), let favoriteActivitiesSnapshot = snapshot.value as? [String: [String]] {
                print("snapshot exists")
                self.favAct = favoriteActivitiesSnapshot
                self.collectionView.reloadData()
            }
        })
    }
    
    fileprivate func resetBadgeForSelf() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        let badgeRef = Database.database().reference().child(userActivitiesEntity).child(currentUserID).child(activityID).child(messageMetaDataFirebaseFolder).child("badge")
        badgeRef.runTransactionBlock({ (mutableData) -> TransactionResult in
            var value = mutableData.value as? Int
            value = 0
            mutableData.value = value!
            return TransactionResult.success(withValue: mutableData)
        })
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func goToMap(activity: Activity) {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWithClose(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        let destination = MapViewController()
        destination.sections = [.event]
        destination.locations = [.event: activity]
        navigationController?.pushViewController(destination, animated: true)
    }
    
}

extension ActivityDetailViewController: MessagesDelegate {
    
    func messages(shouldChangeMessageStatusToReadAt reference: DatabaseReference) {
        chatLogController?.updateMessageStatus(messageRef: reference)
    }
    
    func messages(shouldBeUpdatedTo messages: [Message], conversation: Conversation) {
        
        chatLogController?.hidesBottomBarWhenPushed = true
        chatLogController?.messagesFetcher = messagesFetcher
        chatLogController?.messages = messages
        chatLogController?.conversation = conversation
        
        if let membersIDs = conversation.chatParticipantsIDs, let uid = Auth.auth().currentUser?.uid, membersIDs.contains(uid) {
            chatLogController?.observeTypingIndicator()
            chatLogController?.configureTitleViewWithOnlineStatus()
        }
        
        chatLogController?.messagesFetcher.collectionDelegate = chatLogController
        guard let destination = chatLogController else { return }
        
        if #available(iOS 11.0, *) {
        } else {
            self.chatLogController?.startCollectionViewAtBottom()
        }
        
        navigationController?.pushViewController(destination, animated: true)
        chatLogController = nil
        messagesFetcher?.delegate = nil
        messagesFetcher = nil
    }
}
