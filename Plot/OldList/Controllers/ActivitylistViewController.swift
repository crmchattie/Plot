//
//  ActivitylistViewController.swift
//  Plot
//
//  Created by Cory McHattie on 7/15/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import SplitRow
import Firebase
import CodableFirebase

protocol UpdateActivitylistDelegate: AnyObject {
    func updateActivitylist(activitylist: Activitylist)
}

class ActivitylistViewController: FormViewController {
    
    weak var delegate : UpdateActivitylistDelegate?
    
    var activitylist: Activitylist!
    
    var users = [User]()
    var filteredUsers = [User]()
    var selectedFalconUsers = [User]()
    
    var activities = [Activity]()
    var conversations = [Conversation]()
    
    var activity: Activity!
    
    fileprivate var active: Bool = false
    fileprivate var movingBackwards: Bool = true
    var connectedToAct = true
    var comingFromLists = false
    
    fileprivate var activityName: String = ""
    
    var chatLogController: ChatLogController? = nil
    var messagesFetcher: MessagesFetcher? = nil
    
    init() {
        super.init(style: .insetGrouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.isHidden = false
        navigationItem.largeTitleDisplayMode = .never
        
        
        
        configureTableView()
        
        if activitylist != nil {
            active = true
            resetBadgeForSelf()
        } else {
            if let currentUserID = Auth.auth().currentUser?.uid {
                let ID = Database.database().reference().child(userActivitylistsEntity).child(currentUserID).childByAutoId().key ?? ""
                activitylist = Activitylist(dictionary: ["ID": ID as AnyObject])
                activitylist.name = "ActivityListName"
                activitylist.createdDate = Date()
            }
        }
        setupRightBarButton()
        
        initializeForm()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.movingBackwards && !comingFromLists {
            delegate?.updateActivitylist(activitylist: activitylist)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard tableView.isEditing else { return }
        tableView.endEditing(true)
        tableView.reloadData()
    }
    
    fileprivate func configureTableView() {
        tableView.allowsMultipleSelectionDuringEditing = false
        view.backgroundColor = .systemGroupedBackground
        tableView.indicatorStyle = .default
        tableView.backgroundColor = view.backgroundColor
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        tableView.separatorStyle = .none
        definesPresentationContext = true
        navigationItem.title = "Activity List"
        navigationOptions = .Disabled
    }
    
    func setupRightBarButton() {
        if !comingFromLists || !active || self.selectedFalconUsers.count == 0 {
            let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(close))
            navigationItem.rightBarButtonItem = plusBarButton
        } else {
            let dotsImage = UIImage(named: "dots")
            if #available(iOS 11.0, *) {
                let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))
                let dotsBarButton = UIButton(type: .system)
                dotsBarButton.setImage(dotsImage, for: .normal)
                dotsBarButton.addTarget(self, action: #selector(goToExtras), for: .touchUpInside)
                navigationItem.rightBarButtonItems = [plusBarButton, UIBarButtonItem(customView: dotsBarButton)]
            } else {
                let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(close))
                let dotsBarButton = UIBarButtonItem(image: dotsImage, style: .plain, target: self, action: #selector(goToExtras))
                navigationItem.rightBarButtonItems = [plusBarButton, dotsBarButton]
            }
        }
    }
    
    @objc fileprivate func close() {
        movingBackwards = false
        if !comingFromLists {
            if let activity = activity {
                activitylist.activityID = activity.activityID
            }
            self.showActivityIndicator()
            let createActivitylist = ActivitylistActions(activitylist: activitylist, active: active, selectedFalconUsers: selectedFalconUsers)
            createActivitylist.createNewActivitylist()
            self.hideActivityIndicator()
            delegate?.updateActivitylist(activitylist: activitylist)
            self.navigationController?.popViewController(animated: true)
            
        }
        
    }
    
    @objc func goToExtras() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if connectedToAct {
            if activitylist.conversationID == nil {
                alert.addAction(UIAlertAction(title: "Connect Activity List/Activity to a Chat", style: .default, handler: { (_) in
                    print("User click Approve button")
                    self.goToChat()
                    
                }))
            } else {
                alert.addAction(UIAlertAction(title: "Go to Chat", style: .default, handler: { (_) in
                    print("User click Approve button")
                    self.goToChat()
                    
                    
                }))
            }
        } else if activitylist.conversationID == nil {
            alert.addAction(UIAlertAction(title: "Connect Activity List to a Chat", style: .default, handler: { (_) in
                print("User click Approve button")
                self.goToChat()
                
            }))
        } else {
            alert.addAction(UIAlertAction(title: "Go to Chat", style: .default, handler: { (_) in
                print("User click Approve button")
                self.goToChat()
                
                
            }))
        }
        
        
        //        alert.addAction(UIAlertAction(title: "Share Activitylist", style: .default, handler: { (_) in
        //            print("User click Edit button")
        //            self.share()
        //        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
        print("shareButtonTapped")
        
    }
    
    @objc func goToChat() {
        if let conversationID = activitylist.conversationID {
            if let convo = conversations.first(where: {$0.chatID == conversationID}) {
                self.chatLogController = ChatLogController(collectionViewLayout: AutoSizingCollectionViewFlowLayout())
                self.messagesFetcher = MessagesFetcher()
                self.messagesFetcher?.delegate = self
                self.messagesFetcher?.loadMessagesData(for: convo)
            }
        } else {
            let destination = ChooseChatTableViewController()
            let navController = UINavigationController(rootViewController: destination)
            destination.delegate = self
            destination.activitylist = activitylist
            destination.conversations = conversations
            destination.pinnedConversations = conversations
            destination.filteredConversations = conversations
            destination.filteredPinnedConversations = conversations
            present(navController, animated: true, completion: nil)
        }
    }
    
    func share() {
        //        if let activity = activity, let name = activity.name {
        //            let imageName = "activityLarge"
        //            if let image = UIImage(named: imageName) {
        //                let data = compressImage(image: image)
        //                let aO = ["activityName": "\(name)",
        //                            "activityID": activityID,
        //                            "activityImageURL": "\(imageName)",
        //                            "object": data] as [String: AnyObject]
        //                let activityObject = ActivityObject(dictionary: aO)
        //
        //                let alert = UIAlertController(title: "Share Activity", message: nil, preferredStyle: .actionSheet)
        //
        //                alert.addAction(UIAlertAction(title: "Inside of Plot", style: .default, handler: { (_) in
        //                    print("User click Approve button")
        //                    let destination = ChooseChatTableViewController()
        //                    let navController = UINavigationController(rootViewController: destination)
        //                    destination.activityObject = activityObject
        //                    destination.users = self.users
        //                    destination.filteredUsers = self.filteredUsers
        //                    destination.conversations = self.conversations
        //                    destination.filteredConversations = self.conversations
        //                    destination.filteredPinnedConversations = self.conversations
        //                    self.present(navController, animated: true, completion: nil)
        //
        //                }))
        //
        //                alert.addAction(UIAlertAction(title: "Outside of Plot", style: .default, handler: { (_) in
        //                    print("User click Edit button")
        //                        // Fallback on earlier versions
        //                    let shareText = "Hey! Download Plot on the App Store so I can share an activity with you."
        //                    guard let url = URL(string: "https://apps.apple.com/us/app/plot-scheduling-app/id1473764067?ls=1")
        //                        else { return }
        //                    let shareContent: [Any] = [shareText, url]
        //                    let activityController = UIActivityViewController(activityItems: shareContent,
        //                                                                      applicationActivities: nil)
        //                    self.present(activityController, animated: true, completion: nil)
        //                    activityController.completionWithItemsHandler = { (activityType: UIActivity.ActivityType?, completed:
        //                    Bool, arrayReturnedItems: [Any]?, error: Error?) in
        //                        if completed {
        //                            print("share completed")
        //                            return
        //                        } else {
        //                            print("cancel")
        //                        }
        //                        if let shareError = error {
        //                            print("error while sharing: \(shareError.localizedDescription)")
        //                        }
        //                    }
        //
        //                }))
        //
        //
        //                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
        //                    print("User click Dismiss button")
        //                }))
        //
        //                self.present(alert, animated: true, completion: {
        //                    print("completion block")
        //                })
        //                print("shareButtonTapped")
        //            }
        //
        //
        //        }
        
    }
    
    func initializeForm() {
        form +++
            Section()
            
            <<< TextRow("Name") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textField?.textColor = .label
                $0.placeholderColor = .secondaryLabel
                $0.placeholder = $0.tag
                if active, let activitylist = activitylist {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    $0.value = activitylist.name
                } else {
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
//                    //$0.cell.textField.becomeFirstResponder()
                }
            }.onChange() { [unowned self] row in
                if let rowValue = row.value {
                    self.activitylist.name = rowValue
                }
                if row.value == nil {
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                } else {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textField?.textColor = .label
                row.placeholderColor = .secondaryLabel
        }
        
        if !connectedToAct {
            form.last!
            <<< LabelRow("Participants") { row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.textLabel?.textColor = .label
                row.cell.detailTextLabel?.textColor = .secondaryLabel
                row.cell.accessoryType = .disclosureIndicator
                row.cell.textLabel?.textAlignment = .left
                row.cell.selectionStyle = .default
                row.title = row.tag
                row.value = String(selectedFalconUsers.count)
            }.onCellSelection({ _, row in
                self.openParticipantsInviter()
            }).cellUpdate { cell, row in
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.textColor = .secondaryLabel
                cell.textLabel?.textAlignment = .left
            }
        }
        
        form +++
            MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                               header: "Activity List",
                               footer: "Add an activity to list") {
                                $0.tag = "activitylistfields"
                                $0.addButtonProvider = { section in
                                    return ButtonRow(){
                                        $0.cell.backgroundColor = .secondarySystemGroupedBackground
                                        $0.title = "Add New Activity"
                                    }.cellUpdate { cell, row in
                                        cell.backgroundColor = .secondarySystemGroupedBackground
                                        cell.textLabel?.textAlignment = .left
                                        
                                    }
                                }
                                $0.multivaluedRowToInsertAt = { index in
                                    self.activityName = ""
                                    self.openActivity()
                                    return LabelRow("label"){ row in
                                        
                                    }
                                    
                                }
                                
        }
        
        if let items = self.activitylist.items {
            for (key, value) in items {
                var mvs = (form.sectionBy(tag: "activitylistfields") as! MultivaluedSection)
                mvs.insert(SplitRow<ButtonRow, CheckRow>() { splitRow in
                    splitRow.rowLeftPercentage = 0.75
                    splitRow.rowLeft = ButtonRow(){ row in
                        row.cell.backgroundColor = .secondarySystemGroupedBackground
                        row.cell.textLabel?.textAlignment = .left
                        row.cell.textLabel?.textColor = .label
                        row.cell.textLabel?.numberOfLines = 0
                        row.title = key
                        }.onCellSelection({ _, _ in
                            self.activityName = key
                            self.openActivity()
                    }).cellUpdate { cell, row in
                        cell.backgroundColor = .secondarySystemGroupedBackground
                        cell.textLabel?.textColor = .label
                        cell.textLabel?.textAlignment = .left
                        cell.textLabel?.numberOfLines = 0
                    }
                    splitRow.rowRight = CheckRow() {
                        $0.cell.backgroundColor = .secondarySystemGroupedBackground
                        $0.cell.tintColor = FalconPalette.defaultBlue
                        $0.value = value
                        $0.cell.accessoryType = .checkmark
                        $0.cell.tintAdjustmentMode = .dimmed
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = .secondarySystemGroupedBackground
                        cell.tintColor = FalconPalette.defaultBlue
                        cell.accessoryType = .checkmark
                        if row.value == false {
                            cell.tintAdjustmentMode = .dimmed
                        } else {
                            cell.tintAdjustmentMode = .automatic
                        }
                    }.onCellSelection({ (cell, row) in
                        self.activitylist.items![key] = row.value
                    })
                }.cellUpdate { cell, row in
                    cell.backgroundColor = .secondarySystemGroupedBackground
                } , at: mvs.count - 1)
            }
        }
    }
    
    fileprivate func openActivity() {
        if activityName != "", let IDTypeDictionary = activitylist.IDTypeDictionary {
            let name = activityName
            if let IDType = IDTypeDictionary[name] {
                for (_, _) in IDType {
                    
                }
            }
        } else {
            let destination = ActivityTypeViewController()
            destination.activeList = true
            self.hideActivityIndicator()
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    override func rowsHaveBeenRemoved(_ rows: [BaseRow], at indexes: [IndexPath]) {
        super.rowsHaveBeenRemoved(rows, at: indexes)
        
        DispatchQueue.main.async { [weak self] in
            if let row = rows[0] as? SplitRow<ButtonRow, CheckRow>, row.rowLeft?.title != nil, let title = row.rowLeft?.title, self!.activitylist.items != nil, let IDTypeDictionary = self!.activitylist.IDTypeDictionary {
                self!.activitylist.items![title] = nil
                if IDTypeDictionary[title] != nil {
                    self!.activitylist.IDTypeDictionary![title] = nil
                }
            }
        }
    }
    
    @objc fileprivate func openParticipantsInviter() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWithClose(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
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
        destination.ownerID = activitylist.admin
        destination.users = uniqueUsers
        destination.filteredUsers = uniqueUsers
        if !selectedFalconUsers.isEmpty {
            destination.priorSelectedUsers = selectedFalconUsers
        }
        destination.delegate = self
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    func showActivityIndicator() {
        if let tabController = self.tabBarController {
            self.showSpinner(onView: tabController.view)
        }
        self.navigationController?.view.isUserInteractionEnabled = false
    }
    
    func hideActivityIndicator() {
        self.navigationController?.view.isUserInteractionEnabled = true
        self.removeSpinner()
    }
    
    func getSelectedFalconUsers(forActivitylist activitylist: Activitylist, completion: @escaping ([User])->()) {
        guard let participantsIDs = activitylist.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        var selectedFalconUsers = [User]()
        let group = DispatchGroup()
        for id in participantsIDs {
            // Only if the current user is created this activity
            if activitylist.admin == currentUserID && id == currentUserID {
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
    
    fileprivate func resetBadgeForSelf() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        let badgeRef = Database.database().reference().child(userActivitylistsEntity).child(currentUserID).child(activitylist.ID!).child("badge")
        badgeRef.runTransactionBlock({ (mutableData) -> TransactionResult in
            var value = mutableData.value as? Int
            value = 0
            mutableData.value = value!
            return TransactionResult.success(withValue: mutableData)
        })
    }
}

extension ActivitylistViewController: UpdateInvitees {
    func updateInvitees(selectedFalconUsers: [User]) {
        if let inviteesRow: LabelRow = form.rowBy(tag: "Participants") {
            self.selectedFalconUsers = selectedFalconUsers
            inviteesRow.value = String(selectedFalconUsers.count)
            inviteesRow.updateCell()
            
            if active {
                showActivityIndicator()
                let createActivitylist = ActivitylistActions(activitylist: activitylist, active: active, selectedFalconUsers: selectedFalconUsers)
                createActivitylist.updateActivitylistParticipants()
                hideActivityIndicator()
                
            }
            
        }
    }
}

extension ActivitylistViewController: ChooseActivityDelegate {
    func chosenActivity(mergeActivity: Activity) {
        if connectedToAct {
            if let currentUserID = Auth.auth().currentUser?.uid {
                let newActivitylistID = Database.database().reference().child(userActivitylistsEntity).child(currentUserID).childByAutoId().key ?? ""
                
                let groupActivityReference = Database.database().reference().child(activitiesEntity).child(mergeActivity.activityID!).child(messageMetaDataFirebaseFolder)
                if mergeActivity.activitylistIDs != nil {
                    var activitylistIDs = mergeActivity.activitylistIDs!
                    activitylistIDs.append(newActivitylistID)
                    groupActivityReference.updateChildValues(["activitylistIDs": activitylistIDs as AnyObject])
                } else {
                    groupActivityReference.updateChildValues(["activitylistIDs": [newActivitylistID] as AnyObject])
                }
                
                let newActivitylist = self.activitylist.copy() as! Activitylist
                newActivitylist.ID = newActivitylistID
                newActivitylist.admin = mergeActivity.admin
                newActivitylist.participantsIDs = mergeActivity.participantsIDs
                newActivitylist.conversationID = mergeActivity.conversationID
                newActivitylist.activityID = mergeActivity.activityID
                
                self.getSelectedFalconUsers(forActivitylist: activitylist) { (participants) in
                    self.showActivityIndicator()
                    let createActivitylist = ActivitylistActions(activitylist: self.activitylist, active: self.active, selectedFalconUsers: participants)
                    createActivitylist.createNewActivitylist()
                    self.hideActivityIndicator()
                    self.addedToActAlert()
                    self.dismiss(animated: true, completion: nil)
                }
            }
        } else {
            let groupActivityReference = Database.database().reference().child(activitiesEntity).child(mergeActivity.activityID!).child(messageMetaDataFirebaseFolder)
            if mergeActivity.activitylistIDs != nil {
                var activitylistIDs = mergeActivity.activitylistIDs!
                activitylistIDs.append(activitylist.ID!)
                groupActivityReference.updateChildValues(["activitylistIDs": activitylistIDs as AnyObject])
            } else {
                groupActivityReference.updateChildValues(["activitylistIDs": [activitylist.ID!] as AnyObject])
            }
            //remove participants and admin when adding
            activitylist.participantsIDs = mergeActivity.participantsIDs
            activitylist.admin = mergeActivity.admin
            activitylist.activityID = mergeActivity.activityID
            activitylist.conversationID = mergeActivity.conversationID
            
            self.getSelectedFalconUsers(forActivitylist: activitylist) { (participants) in
                self.showActivityIndicator()
                let createActivitylist = ActivitylistActions(activitylist: self.activitylist, active: self.active, selectedFalconUsers: participants)
                createActivitylist.createNewActivitylist()
                self.hideActivityIndicator()
                self.addedToActAlert()
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}

extension ActivitylistViewController: ChooseChatDelegate {
    func chosenChat(chatID: String, activityID: String?, grocerylistID: String?, checklistID: String?, packinglistID: String?, activitylistID: String?) {
        if let activitylistID = activitylistID {
            let updatedConversationID = ["conversationID": chatID as AnyObject]
            Database.database().reference().child(activitylistsEntity).child(activitylistID).updateChildValues(updatedConversationID)
            if let conversation = conversations.first(where: {$0.chatID == chatID}) {
                if conversation.activitylists != nil {
                    var activitylists = conversation.activitylists!
                    activitylists.append(activitylistID)
                    let updatedActivitylists = [activitylistsEntity: activitylists as AnyObject]
                    Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivitylists)
                } else {
                    let updatedActivitylists = [activitylistsEntity: [activitylistID] as AnyObject]
                    Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivitylists)
                }
                if let activityID = activityID {
                    Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder).updateChildValues(updatedConversationID)
                    if conversation.activities != nil {
                        var activities = conversation.activities!
                        activities.append(activityID)
                        let updatedActivities = [activitiesEntity: activities as AnyObject]
                        Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
                    } else {
                        let updatedActivities = [activitiesEntity: [activityID] as AnyObject]
                        Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
                    }
                    Database.database().reference().child(activitiesEntity).child(activityID).updateChildValues(updatedConversationID)
                }
                self.connectedToChatAlert()
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}

extension ActivitylistViewController: MessagesDelegate {
    
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
        
        self.chatLogController?.startCollectionViewAtBottom()
        
        
        // If we're presenting a modal sheet
        if let presentedViewController = presentedViewController as? UINavigationController {
            presentedViewController.pushViewController(destination, animated: true)
        } else {
            navigationController?.pushViewController(destination, animated: true)
        }
        
        chatLogController = nil
        messagesFetcher?.delegate = nil
        messagesFetcher = nil
    }
}
