//
//  ChecklistViewController.swift
//  Plot
//
//  Created by Cory McHattie on 4/30/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import SplitRow
import Firebase

protocol UpdateChecklistDelegate: AnyObject {
    func updateChecklist(checklist: Checklist)
}

class ChecklistViewController: FormViewController {
          
    weak var delegate : UpdateChecklistDelegate?
        
    var checklist: Checklist!
    
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
                
        if checklist != nil {
            active = true
            resetBadgeForSelf()
        } else {
            if let currentUserID = Auth.auth().currentUser?.uid {
                let ID = Database.database().reference().child(userChecklistsEntity).child(currentUserID).childByAutoId().key ?? ""
                checklist = Checklist(dictionary: ["ID": ID as AnyObject])
                checklist.name = "CheckListName"
                checklist.createdDate = Date()
            }
        }
        setupRightBarButton()

        initializeForm()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if movingBackwards && !comingFromLists {
            updateLists()
            delegate?.updateChecklist(checklist: checklist)
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }
  
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard tableView.isEditing else { return }
        tableView.endEditing(true)
        tableView.reloadData()
    }

    fileprivate func configureTableView() {
        tableView.allowsMultipleSelectionDuringEditing = false
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.backgroundColor = view.backgroundColor
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        tableView.separatorStyle = .none
        definesPresentationContext = true
        navigationItem.title = "Checklist"
    }
    
    func setupRightBarButton() {
        if active {
            let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))
            navigationItem.rightBarButtonItem = plusBarButton
        } else {
            let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(close))
            navigationItem.rightBarButtonItem = plusBarButton
        }
        if navigationItem.leftBarButtonItem != nil {
            navigationItem.leftBarButtonItem?.action = #selector(cancel)
        }
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc fileprivate func close() {
        movingBackwards = false
        updateLists()
        if !comingFromLists {
            if let activity = activity {
                checklist.activityID = activity.activityID
            }
            self.showActivityIndicator()
            let createChecklist = ChecklistActions(checklist: checklist, active: active, selectedFalconUsers: selectedFalconUsers)
            createChecklist.createNewChecklist()
            self.hideActivityIndicator()
            delegate?.updateChecklist(checklist: checklist)
            if navigationItem.leftBarButtonItem != nil {
                self.dismiss(animated: true, completion: nil)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
            return
        }
        
    }
    
    @objc func goToExtras() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if connectedToAct {
            if checklist.conversationID == nil {
                alert.addAction(UIAlertAction(title: "Connect Checklist/Activity to a Chat", style: .default, handler: { (_) in
                    print("User click Approve button")
                    self.goToChat()

                }))
            } else {
                alert.addAction(UIAlertAction(title: "Go to Chat", style: .default, handler: { (_) in
                    print("User click Approve button")
                    self.goToChat()

                    
                }))
            }
        } else if checklist.conversationID == nil {
            alert.addAction(UIAlertAction(title: "Connect Checklist to a Chat", style: .default, handler: { (_) in
                print("User click Approve button")
                self.goToChat()

            }))
        } else {
            alert.addAction(UIAlertAction(title: "Go to Chat", style: .default, handler: { (_) in
                print("User click Approve button")
                self.goToChat()

                
            }))
        }
        
        
//        alert.addAction(UIAlertAction(title: "Share Checklist", style: .default, handler: { (_) in
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
        if let conversationID = checklist.conversationID {
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
            destination.checklist = checklist
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
            $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
            $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
            $0.placeholder = $0.tag
            if active, let checklist = checklist {
                $0.value = checklist.name
                self.navigationItem.rightBarButtonItem?.isEnabled = true
            } else {
                $0.cell.textField.becomeFirstResponder()
                self.navigationItem.rightBarButtonItem?.isEnabled = false
            }
            }.onChange() { [unowned self] row in
                if let rowValue = row.value {
                    self.checklist.name = rowValue
                }
                if row.value == nil {
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                } else {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
        }
        
        if !connectedToAct {
            form.last!
            <<< LabelRow("Participants") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.cell.textLabel?.textAlignment = .left
                row.cell.selectionStyle = .default
                row.title = row.tag
                if checklist.admin == nil || checklist.admin == Auth.auth().currentUser?.uid {
                    row.value = String(self.selectedFalconUsers.count + 1)
                } else {
                    row.value = String(self.selectedFalconUsers.count)
                }
            }.onCellSelection({ _, row in
                self.openParticipantsInviter()
            }).cellUpdate { cell, row in
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                cell.textLabel?.textAlignment = .left
            }
        }
        
        form +++
        MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
            header: "Checklist",
            footer: "Add a checklist item") {
            $0.tag = "checklistfields"
            $0.addButtonProvider = { section in
                return ButtonRow(){
                    $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    $0.title = "Add New Item"
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                        cell.textLabel?.textAlignment = .left
                        
                }
            }
            $0.multivaluedRowToInsertAt = { index in
                return SplitRow<TextRow, CheckRow>(){
                    $0.rowLeftPercentage = 0.75
                    $0.rowLeft = TextRow(){
                        $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                        $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                        $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                        $0.placeholder = "Item"
                        }.cellUpdate { cell, row in
                            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                            cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                            row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                    }
                    
                    $0.rowRight = CheckRow() {
                        $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                        $0.cell.tintColor = FalconPalette.defaultBlue
                        $0.value = false
                        $0.cell.accessoryType = .checkmark
                        $0.cell.tintAdjustmentMode = .dimmed
                        }.cellUpdate { cell, row in
                            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                            cell.tintColor = FalconPalette.defaultBlue
                            cell.accessoryType = .checkmark
                            if row.value == false {
                                cell.tintAdjustmentMode = .dimmed
                            } else {
                                cell.tintAdjustmentMode = .automatic
                            }
                    }
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    }.onChange() { _ in
                        self.updateLists()
                }
                
            }
            
        }
        
        if let items = self.checklist.items {
            let sortedItems = items.sorted { item1, item2 in
                if item1.value == item2.value {
                    return item1.key < item2.key
                }
                return item1.value && !item2.value
            }
            for item in sortedItems {
                var mvs = (form.sectionBy(tag: "checklistfields") as! MultivaluedSection)
                mvs.insert(SplitRow<TextRow, CheckRow>() {
                    $0.rowLeftPercentage = 0.75
                    $0.rowLeft = TextRow(){
                        $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                        $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                        $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                        $0.value = item.key
                        }.cellUpdate { cell, row in
                            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                            cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                            row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                    }
                    $0.rowRight = CheckRow() {
                        $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                        $0.cell.tintColor = FalconPalette.defaultBlue
                        $0.value = item.value
                        $0.cell.accessoryType = .checkmark
                        $0.cell.tintAdjustmentMode = .dimmed
                        }.cellUpdate { cell, row in
                            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                            cell.tintColor = FalconPalette.defaultBlue
                            if row.value == false {
                                cell.accessoryType = .checkmark
                                cell.tintAdjustmentMode = .dimmed
                            } else {
                                cell.tintAdjustmentMode = .automatic
                            }
                    }
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    }.onChange() { _ in
                        self.updateLists()
                } , at: mvs.count - 1)
            }
        }
    }
    
    fileprivate func updateLists() {
            if let mvs = (form.values()["checklistfields"] as? [Any?])?.compactMap({ $0 }) {
                if !mvs.isEmpty {
                    var checklistDict = [String : Bool]()
                    for element in mvs {
                        if let value = element as? SplitRowValue<Swift.String, Swift.Bool>, let text = value.left, let state = value.right {
                            let newText = text.removeCharacters()
                            checklistDict[newText] = state
                        }
                    }
                    self.checklist.items = checklistDict
                } else {
                    self.checklist.items = nil
                }
            }
    }
    
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
        destination.ownerID = checklist.admin
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
    
    func getSelectedFalconUsers(forChecklist checklist: Checklist, completion: @escaping ([User])->()) {
        guard let participantsIDs = checklist.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        var selectedFalconUsers = [User]()
        let group = DispatchGroup()
        for id in participantsIDs {
            // Only if the current user is created this activity
            if checklist.admin == currentUserID && id == currentUserID {
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
        let badgeRef = Database.database().reference().child(userChecklistsEntity).child(currentUserID).child(checklist.ID!).child("badge")
        badgeRef.runTransactionBlock({ (mutableData) -> TransactionResult in
            var value = mutableData.value as? Int
            value = 0
            mutableData.value = value!
            return TransactionResult.success(withValue: mutableData)
        })
    }
}

extension ChecklistViewController: UpdateInvitees {
    func updateInvitees(selectedFalconUsers: [User]) {
        if let inviteesRow: LabelRow = form.rowBy(tag: "Participants") {
            self.selectedFalconUsers = selectedFalconUsers
            if checklist.admin == nil || checklist.admin == Auth.auth().currentUser?.uid {
                inviteesRow.value = String(self.selectedFalconUsers.count + 1)
            } else {
                inviteesRow.value = String(self.selectedFalconUsers.count)
            }
            inviteesRow.updateCell()
            
            if active {
                showActivityIndicator()
                let createChecklist = ChecklistActions(checklist: checklist, active: active, selectedFalconUsers: selectedFalconUsers)
                createChecklist.updateChecklistParticipants()
                hideActivityIndicator()

            }
            
        }
    }
}

extension ChecklistViewController: ChooseActivityDelegate {
    func chosenActivity(mergeActivity: Activity) {
        if connectedToAct {
            if let currentUserID = Auth.auth().currentUser?.uid {
                let newChecklistID = Database.database().reference().child(userChecklistsEntity).child(currentUserID).childByAutoId().key ?? ""
                
                let groupActivityReference = Database.database().reference().child(activitiesEntity).child(mergeActivity.activityID!).child(messageMetaDataFirebaseFolder)
                if mergeActivity.checklistIDs != nil {
                    var checklistIDs = mergeActivity.checklistIDs!
                    checklistIDs.append(newChecklistID)
                    groupActivityReference.updateChildValues(["checklistIDs": checklistIDs as AnyObject])
                } else {
                    groupActivityReference.updateChildValues(["checklistIDs": [newChecklistID] as AnyObject])
                }
                
                let newChecklist = self.checklist.copy() as! Checklist
                newChecklist.ID = newChecklistID
                newChecklist.admin = mergeActivity.admin
                newChecklist.participantsIDs = mergeActivity.participantsIDs
                newChecklist.conversationID = mergeActivity.conversationID
                newChecklist.activityID = mergeActivity.activityID
                                
                self.getSelectedFalconUsers(forChecklist: checklist) { (participants) in
                    self.showActivityIndicator()
                    let createChecklist = ChecklistActions(checklist: self.checklist, active: self.active, selectedFalconUsers: participants)
                    createChecklist.createNewChecklist()
                    self.hideActivityIndicator()
                    self.addedToActAlert()
                    self.dismiss(animated: true, completion: nil)
                }
            }
        } else {
            let groupActivityReference = Database.database().reference().child(activitiesEntity).child(mergeActivity.activityID!).child(messageMetaDataFirebaseFolder)
            if mergeActivity.checklistIDs != nil {
                var checklistIDs = mergeActivity.checklistIDs!
                checklistIDs.append(checklist.ID!)
                groupActivityReference.updateChildValues(["checklistIDs": checklistIDs as AnyObject])
            } else {
                groupActivityReference.updateChildValues(["checklistIDs": [checklist.ID!] as AnyObject])
            }
            //remove participants and admin when adding
            checklist.participantsIDs = mergeActivity.participantsIDs
            checklist.admin = mergeActivity.admin
            checklist.activityID = mergeActivity.activityID
            checklist.conversationID = mergeActivity.conversationID
            
            self.getSelectedFalconUsers(forChecklist: checklist) { (participants) in
                self.showActivityIndicator()
                let createChecklist = ChecklistActions(checklist: self.checklist, active: self.active, selectedFalconUsers: participants)
                createChecklist.createNewChecklist()
                self.hideActivityIndicator()
                self.addedToActAlert()
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}

extension ChecklistViewController: ChooseChatDelegate {
    func chosenChat(chatID: String, activityID: String?, grocerylistID: String?, checklistID: String?, packinglistID: String?, activitylistID: String?) {
        if let checklistID = checklistID {
            let updatedConversationID = ["conversationID": chatID as AnyObject]
            Database.database().reference().child(checklistsEntity).child(checklistID).updateChildValues(updatedConversationID)

            if let conversation = conversations.first(where: {$0.chatID == chatID}) {
                if conversation.checklists != nil {
                    var checklists = conversation.checklists!
                    checklists.append(checklistID)
                    let updatedChecklists = [checklistsEntity: checklists as AnyObject]
                    Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedChecklists)
                } else {
                    let updatedChecklists = [checklistsEntity: [checklistID] as AnyObject]
                    Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedChecklists)
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

extension ChecklistViewController: MessagesDelegate {
    
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

