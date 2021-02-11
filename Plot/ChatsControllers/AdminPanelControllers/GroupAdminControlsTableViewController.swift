//
//  GroupAdminControlsTableViewController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/19/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import SDWebImage
import Firebase
import CodableFirebase

class GroupAdminControlsTableViewController: UITableViewController {
    
    fileprivate let membersCellID = "membersCellID"
    fileprivate let adminControlsCellID = "adminControlsCellID"
    fileprivate let activityCellID = "activityCellID"
    fileprivate let listCellID = "listCellID"
    
    let groupProfileTableHeaderContainer = GroupProfileTableHeaderContainer()
    let avatarOpener = AvatarOpener()
    
    var chatReference: DatabaseReference!
    var activityReference: DatabaseReference!
    var chatHandle: DatabaseHandle!
    var membersAddingReference: DatabaseReference!
    var membersAddingHandle: DatabaseHandle!
    var membersRemovingHandle: DatabaseHandle!
    var activitiesAddingReference: DatabaseReference!
    var activitiesAddingHandle: DatabaseHandle!
    var activitiesRemovingHandle: DatabaseHandle!
    
    let informationMessageSender = InformationMessageSender()
    
    var members = [User]()
    var users = [User]()
    var filteredUsers = [User]()
    var activities = [Activity]()
    var checklists = [Checklist]()
    var grocerylists = [Grocerylist]()
    var packinglists = [Packinglist]()
    var activitylists = [Activitylist]()
    var sections = [String]()
    var conversation: Conversation!
    let fullAdminControlls = ["Add members", "Change admin", "Remove admin", "Leave the group"]
    let partialAdminControlls = ["Add members", "Enforce admin", "Leave the group"]
    let defaultAdminControlls = ["Add members", "Leave the group"]
    let lessAdminControlls = ["Leave the group"]
    
    var adminControls = [String]()
    
    var chatID = String() {
        didSet {
            setupActivities()
            observeConversationDataChanges()
            observeMembersChanges()
        }
    }
    
    var isCurrentUserAdministrator = false
    
    var conversationAdminID = String() {
        didSet {
            if (conversationAdminID == Auth.auth().currentUser?.uid && conversationAdminNeeded) || !conversationAdminNeeded {
                tableView.allowsMultipleSelectionDuringEditing = false
                navigationItem.rightBarButtonItem = editButtonItem
            }
            manageControlsAppearance()
        }
    }
    
    func setAdminControls() {
        if conversationAdminNeeded {
            if isCurrentUserAdministrator {
                adminControls = fullAdminControlls
            } else {
                adminControls = lessAdminControlls
            }
        } else {
            if isCurrentUserAdministrator {
                adminControls = partialAdminControlls
            } else {
                adminControls = defaultAdminControlls
            }
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    var groupAvatarURL = String() {
        didSet {
            groupProfileTableHeaderContainer.profileImageView.showActivityIndicator()
            groupProfileTableHeaderContainer.profileImageView.sd_setImage(with: URL(string:groupAvatarURL), placeholderImage: nil, options: [.continueInBackground, .scaleDownLargeImages], completed: { (image, error, cacheType, url) in
                self.groupProfileTableHeaderContainer.profileImageView.hideActivityIndicator()
            })
        }
    }
    
    var currentName = String()
    
    var conversationAdminNeeded = Bool() {
        didSet {
            if (conversationAdminID == Auth.auth().currentUser?.uid && conversationAdminNeeded) || !conversationAdminNeeded {
                tableView.allowsMultipleSelectionDuringEditing = false
                navigationItem.rightBarButtonItem = editButtonItem
            }
            manageControlsAppearance()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupActivities()
        setupLists()
        setupMainView()
        setupTableView()
        setupColorsAccordingToTheme()
        setupContainerView()
        handleReloadTable()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if self.navigationController?.visibleViewController is AddGroupMembersController ||
            self.navigationController?.visibleViewController is ChangeGroupAdminController ||
            self.navigationController?.visibleViewController is LeaveGroupAndChangeAdminController {
            return
        }
        removeObservers()
    }
    
    func removeObservers() {
        print("removing observers")
        if chatReference != nil {
            chatReference.removeObserver(withHandle: chatHandle)
            chatReference = nil
            chatHandle = nil
        }
        
        if membersAddingReference != nil && membersAddingHandle != nil {
            membersAddingReference.removeObserver(withHandle: membersAddingHandle)
        }
        
        if membersAddingReference != nil && membersRemovingHandle != nil {
            membersAddingReference.removeObserver(withHandle: membersRemovingHandle)
        }
        
    }
    
    deinit {
        print("\nadmin deinit\n")
    }
    
    fileprivate func setupMainView() {
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
            navigationController?.navigationBar.prefersLargeTitles = false
        }
        navigationItem.title = "Group Info"
        extendedLayoutIncludesOpaqueBars = true
        definesPresentationContext = true
        edgesForExtendedLayout = [UIRectEdge.top, UIRectEdge.bottom]
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    }
    
    fileprivate func setupTableView() {
        tableView = UITableView(frame: tableView.frame, style: .insetGrouped)
        tableView.sectionIndexBackgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.register(FalconUsersTableViewCell.self, forCellReuseIdentifier: membersCellID)
        tableView.register(GroupAdminControlsTableViewCell.self, forCellReuseIdentifier: adminControlsCellID)
        tableView.register(ChatActivitiesTableViewCell.self, forCellReuseIdentifier: activityCellID)
        tableView.register(ChatListTableViewCell.self, forCellReuseIdentifier: listCellID)
        tableView.allowsSelection = true
        tableView.separatorStyle = .none
    }
    
    fileprivate func setupContainerView() {
        
        groupProfileTableHeaderContainer.name.delegate = self
        groupProfileTableHeaderContainer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 150)
        groupProfileTableHeaderContainer.name.addTarget(self, action: #selector(nameDidBeginEditing), for: .editingDidBegin)
        groupProfileTableHeaderContainer.name.addTarget(self, action: #selector(nameEditingChanged), for: .editingChanged)
        tableView.tableHeaderView = groupProfileTableHeaderContainer
        self.groupProfileTableHeaderContainer.profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.openUserProfilePicture)))
    }
    
    fileprivate func setupColorsAccordingToTheme() {
        groupProfileTableHeaderContainer.name.textColor = ThemeManager.currentTheme().generalTitleColor
        groupProfileTableHeaderContainer.name.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
    }
    
    fileprivate func manageControlsAppearance() {
        if conversationAdminID == Auth.auth().currentUser!.uid {
            groupProfileTableHeaderContainer.addPhotoLabel.isHidden = false
            groupProfileTableHeaderContainer.addPhotoLabel.text = groupProfileTableHeaderContainer.addPhotoLabelAdminText
            groupProfileTableHeaderContainer.name.isUserInteractionEnabled = true
            isCurrentUserAdministrator = true
        } else if conversationAdminNeeded == false && conversationAdminID != Auth.auth().currentUser!.uid {
            groupProfileTableHeaderContainer.addPhotoLabel.isHidden = false
            groupProfileTableHeaderContainer.addPhotoLabel.text = groupProfileTableHeaderContainer.addPhotoLabelAdminText
            groupProfileTableHeaderContainer.name.isUserInteractionEnabled = true
            isCurrentUserAdministrator = false
        } else {
            groupProfileTableHeaderContainer.addPhotoLabel.isHidden = false
            groupProfileTableHeaderContainer.addPhotoLabel.text = groupProfileTableHeaderContainer.addPhotoLabelRegularText
            groupProfileTableHeaderContainer.name.isUserInteractionEnabled = false
            isCurrentUserAdministrator = false
        }
        setAdminControls()
    }
    
    func setupActivities() {
        if conversation?.activities != nil {
            sections.append("Activities")
            for activityID in conversation!.activities! {
                let activityDataReference = Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder)
                activityDataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    guard var dictionary = snapshot.value as? [String: AnyObject] else { return }
                    
                    dictionary.updateValue(activityID as AnyObject, forKey: "id")
                    
                    if let membersIDs = dictionary["participantsIDs"] as? [String:AnyObject] {
                        dictionary.updateValue(Array(membersIDs.values) as AnyObject, forKey: "participantsIDs")
                    }
                    
                    let activity = Activity(dictionary: dictionary)
                    
                    self.activities.append(activity)
                    
                    self.tableView.reloadData()
                    
                })
            }
        }
    }
    
    func setupLists() {
        if conversation?.checklists != nil {
            sections.append("Checklists")
            for checklistID in conversation!.checklists! {
                let checklistDataReference = Database.database().reference().child(checklistsEntity).child(checklistID)
                checklistDataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), let checklistSnapshotValue = snapshot.value {
                        if let checklist = try? FirebaseDecoder().decode(Checklist.self, from: checklistSnapshotValue) {
                            self.checklists.append(checklist)
                            self.tableView.reloadData()
                        }
                    }
                })
            }
        }
        if conversation?.grocerylists != nil {
            sections.append("Grocery Lists")
            for grocerylistID in conversation!.grocerylists! {
                let grocerylistDataReference = Database.database().reference().child(grocerylistsEntity).child(grocerylistID)
                grocerylistDataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), let grocerylistSnapshotValue = snapshot.value {
                        if let grocerylist = try? FirebaseDecoder().decode(Grocerylist.self, from: grocerylistSnapshotValue) {
                            self.grocerylists.append(grocerylist)
                            self.tableView.reloadData()
                        }
                    }
                })
            }
        }
        if conversation?.activitylists != nil {
            sections.append("Activity Lists")
            for checklistID in conversation!.activitylists! {
                let activitylistDataReference = Database.database().reference().child(activitylistsEntity).child(checklistID)
                activitylistDataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), let activitylistSnapshotValue = snapshot.value {
                        if let activitylist = try? FirebaseDecoder().decode(Activitylist.self, from: activitylistSnapshotValue) {
                            self.activitylists.append(activitylist)
                            self.tableView.reloadData()
                        }
                    }
                })
            }
        }
        if conversation?.packinglists != nil {
            sections.append("Packing Lists")
            for packinglistID in conversation!.packinglists! {
                let packinglistDataReference = Database.database().reference().child(packinglistsEntity).child(packinglistID)
                packinglistDataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), let packinglistSnapshotValue = snapshot.value {
                        if let packinglist = try? FirebaseDecoder().decode(Packinglist.self, from: packinglistSnapshotValue) {
                            self.packinglists.append(packinglist)
                            self.tableView.reloadData()
                        }
                    }
                    
                    
                })
            }
        }
    }
    
    fileprivate func observeConversationDataChanges() {
        
        chatReference = Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder)
        chatHandle = chatReference.observe( .value) { (snapshot) in
            guard let conversationDictionary = snapshot.value as? [String: AnyObject] else { return }
            let conversation = Conversation(dictionary: conversationDictionary)
            
            if let url = conversation.chatPhotoURL {
                self.groupAvatarURL = url
            }
            
            if let name = conversation.chatName {
                self.groupProfileTableHeaderContainer.name.text = name
                self.currentName = name
            }
            
            if let admin = conversation.admin {
                self.conversationAdminID = admin
            }
            
            if let adminNeeded = conversation.adminNeeded {
                self.conversationAdminNeeded = adminNeeded
            }
        }
    }
    
    func observeMembersChanges() {
        
        membersAddingReference = Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder).child("chatParticipantsIDs")
        
        membersAddingHandle = membersAddingReference.observe(.childAdded) { (snapshot) in
            guard let id = snapshot.value as? String else { return }
            
            let newMemberReference = Database.database().reference().child("users").child(id)
            
            newMemberReference.observeSingleEvent(of: .value, with: { (snapshot) in
                
                guard var dictionary = snapshot.value as? [String: AnyObject] else { return }
                dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                
                let user = User(dictionary: dictionary)
                
                if let userIndex = self.members.firstIndex(where: { (member) -> Bool in
                                                            return member.id == snapshot.key }) {
                    self.tableView.beginUpdates()
                    self.members[userIndex] = user
                    self.tableView.reloadRows(at: [IndexPath(row:userIndex,section: 1)], with: .none)
                } else {
                    self.tableView.beginUpdates()
                    self.members.append(user)
                    self.tableView.headerView(forSection: 1)?.textLabel?.text = "\(self.members.count) MEMBERS"
                    var index = 0
                    if self.members.count-1 >= 0 { index = self.members.count - 1 }
                    self.tableView.insertRows(at: [IndexPath(row: index, section: 1)], with: .fade)
                }
                self.tableView.endUpdates()
                self.updateGroupName()
            })
        }
        
        membersRemovingHandle = membersAddingReference.observe(.childRemoved) { (snapshot) in
            guard let id = snapshot.value as? String else { return }
            
            guard let memberIndex = self.members.firstIndex(where: { (member) -> Bool in
                return member.id == id
            }) else { return }
            
            self.tableView.beginUpdates()
            self.members.remove(at: memberIndex)
            self.tableView.deleteRows(at: [IndexPath(row:memberIndex, section: 1)], with: .left)
            self.tableView.headerView(forSection: 1)?.textLabel?.text = "\(self.members.count) MEMBERS"
            self.tableView.endUpdates()
            if !self.isCurrentUserMemberOfCurrentGroup() {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func updateGroupName() {
        if members.count > 2 && (groupProfileTableHeaderContainer.name.text!.count == 0 || groupProfileTableHeaderContainer.name.text!.trimmingCharacters(in: .whitespaces).isEmpty) {
            groupProfileTableHeaderContainer.name.attributedPlaceholder = NSAttributedString(string:"Update Group Name", attributes:[NSAttributedString.Key.foregroundColor: ThemeManager.currentTheme().generalSubtitleColor])
            groupProfileTableHeaderContainer.name.becomeFirstResponder()
        }
    }
    
    func isCurrentUserMemberOfCurrentGroup() -> Bool {
        let membersIDs = members.map({ $0.id ?? "" })
        guard let uid = Auth.auth().currentUser?.uid, membersIDs.contains(uid) else { return false }
        return true
    }
    
    @objc fileprivate func openUserProfilePicture() {
        if !isCurrentUserAdministrator && groupProfileTableHeaderContainer.profileImageView.image == nil && conversationAdminNeeded { return }
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        avatarOpener.delegate = self
        avatarOpener.handleAvatarOpening(avatarView: groupProfileTableHeaderContainer.profileImageView, at: self,
                                         isEditButtonEnabled: isCurrentUserAdministrator || !conversationAdminNeeded, title: .group)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count + 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            if adminControls.count == 0 {
                return ""
            }
            return ""
        } else if section == 1 {
            return "\(members.count) MEMBERS"
        } else {
            return sections[section - 2].capitalized
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let height: CGFloat = 60
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: height))
        footerView.backgroundColor = UIColor.clear
        return footerView
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = ThemeManager.currentTheme().generalBackgroundColor
        if let headerTitle = view as? UITableViewHeaderFooterView {
            headerTitle.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            headerTitle.textLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
            headerTitle.textLabel?.adjustsFontForContentSizeCategory = true
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return adminControls.count
        } else if section == 1 {
            return members.count
        } else if sections[section - 2] == "Activities" {
            return activities.count
        } else if sections[section - 2] == "Checklists" {
            return checklists.count
        } else if sections[section - 2] == "Grocery Lists" {
            return grocerylists.count
        } else if sections[section - 2] == "Activity Lists" {
            return activitylists.count
        } else if sections[section - 2] == "Packing Lists" {
            return packinglists.count
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 1, members[indexPath.row].id != conversationAdminID, members[indexPath.row].id != Auth.auth().currentUser!.uid {
            return true
        } else if indexPath.section >= 2 {
            return true
        } else {
            return false
        }
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        guard isCurrentUserAdministrator || !conversationAdminNeeded else { return .none }
        return .delete
    }
    
    override  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if indexPath.section == 1 && editingStyle == .delete {
            let membersIDs = self.members.map { $0.id ?? "" }
            let text = "User \(self.members[indexPath.row].name ?? "") removed from the group"
            informationMessageSender.sendInformatoinMessage(chatID: chatID, membersIDs: membersIDs, text: text )
            let memberID = members[indexPath.row].id ?? ""
            let reference = Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder).child("chatParticipantsIDs").child(memberID)
            reference.removeValue()
        } else if sections[indexPath.section - 2] == "Activities" {
            let membersIDs = self.members.map { $0.id ?? "" }
            if let activityID = self.activities[indexPath.row].activityID {
                var activityIDs = [String]()
                let newActivityName = self.activities[indexPath.row].name?.trimmingCharacters(in: .whitespaces) ?? ""
                let text = "The \(newActivityName) activity was disconnected to this chat"
                informationMessageSender.sendInformatoinMessage(chatID: chatID, membersIDs: membersIDs, text: text)
                let activityReference = Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder).child("conversationID")
                activityReference.removeValue()
                let chatReference = Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder).child("activities")
                chatReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    for child in snapshot.children {
                        let snap = child as! DataSnapshot
                        let key = snap.key
                        let value = snap.value as! String
                        if activityID == value {
                            chatReference.child(key).removeValue()
                        } else {
                            activityIDs.append(value)
                        }
                    }
                    let updatedActivities = ["activities": activityIDs as AnyObject]
                    Database.database().reference().child("groupChats").child(self.chatID).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
                })
                
                guard let activityIndex = self.activities.firstIndex(where: { (activity) -> Bool in
                    return activity.activityID == activityID
                }) else { return }
                
                if tableView.numberOfRows(inSection: indexPath.section) == 1 {
                    self.tableView.beginUpdates()
                    self.activities.remove(at: activityIndex)
                    self.sections.removeAll(where: {$0 == "Activities"})
                    let indexSet = IndexSet(arrayLiteral: indexPath.section)
                    self.tableView.deleteSections(indexSet, with: .left)
                    self.tableView.endUpdates()
                } else {
                    self.tableView.beginUpdates()
                    self.activities.remove(at: activityIndex)
                    self.tableView.deleteRows(at: [IndexPath(row:activityIndex, section: 2)], with: .left)
                    self.tableView.endUpdates()
                }
            }
        } else if sections[indexPath.section - 2] == "Checklists" {
            let membersIDs = self.members.map { $0.id ?? "" }
            if let checklistID = self.checklists[indexPath.row].ID {
                var checklistIDs = [String]()
                let newChecklistName = self.checklists[indexPath.row].name?.trimmingCharacters(in: .whitespaces) ?? ""
                let text = "The \(newChecklistName) checklist was disconnected to this chat"
                informationMessageSender.sendInformatoinMessage(chatID: chatID, membersIDs: membersIDs, text: text)
                let checklistReference = Database.database().reference().child(checklistsEntity).child(checklistID).child("conversationID")
                checklistReference.removeValue()
                let chatReference = Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder).child("checklists")
                chatReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    for child in snapshot.children {
                        let snap = child as! DataSnapshot
                        let key = snap.key
                        let value = snap.value as! String
                        if checklistID == value {
                            chatReference.child(key).removeValue()
                        } else {
                            checklistIDs.append(value)
                        }
                    }
                    let updatedActivities = ["checklists": checklistIDs as AnyObject]
                    Database.database().reference().child("groupChats").child(self.chatID).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
                })
                
                guard let checklistIndex = self.checklists.firstIndex(where: { (checklist) -> Bool in
                    return checklist.ID == checklistID
                }) else { return }
                
                if tableView.numberOfRows(inSection: indexPath.section) == 1 {
                    self.tableView.beginUpdates()
                    self.checklists.remove(at: checklistIndex)
                    self.sections.removeAll(where: {$0 == "Checklists"})
                    let indexSet = IndexSet(arrayLiteral: indexPath.section)
                    self.tableView.deleteSections(indexSet, with: .left)
                    self.tableView.endUpdates()
                } else {
                    self.tableView.beginUpdates()
                    self.checklists.remove(at: checklistIndex)
                    self.tableView.deleteRows(at: [IndexPath(row:checklistIndex, section: 2)], with: .left)
                    self.tableView.endUpdates()
                }
            }
        } else if sections[indexPath.section - 2] == "Grocery Lists" {
            let membersIDs = self.members.map { $0.id ?? "" }
            if let grocerylistID = self.grocerylists[indexPath.row].ID {
                var grocerylistIDs = [String]()
                let newGrocerylistName = self.grocerylists[indexPath.row].name?.trimmingCharacters(in: .whitespaces) ?? ""
                let text = "The \(newGrocerylistName) grocery list was disconnected to this chat"
                informationMessageSender.sendInformatoinMessage(chatID: chatID, membersIDs: membersIDs, text: text)
                let grocerylistReference = Database.database().reference().child(grocerylistsEntity).child(grocerylistID).child("conversationID")
                grocerylistReference.removeValue()
                let chatReference = Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder).child("grocerylists")
                chatReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    for child in snapshot.children {
                        let snap = child as! DataSnapshot
                        let key = snap.key
                        let value = snap.value as! String
                        if grocerylistID == value {
                            chatReference.child(key).removeValue()
                        } else {
                            grocerylistIDs.append(value)
                        }
                    }
                    let updatedActivities = ["grocerylists": grocerylistIDs as AnyObject]
                    Database.database().reference().child("groupChats").child(self.chatID).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
                })
                
                guard let grocerylistIndex = self.grocerylists.firstIndex(where: { (grocerylist) -> Bool in
                    return grocerylist.ID == grocerylistID
                }) else { return }
                
                if tableView.numberOfRows(inSection: indexPath.section) == 1 {
                    self.tableView.beginUpdates()
                    self.grocerylists.remove(at: grocerylistIndex)
                    self.sections.removeAll(where: {$0 == "Grocery Lists"})
                    let indexSet = IndexSet(arrayLiteral: indexPath.section)
                    self.tableView.deleteSections(indexSet, with: .left)
                    self.tableView.endUpdates()
                } else {
                    self.tableView.beginUpdates()
                    self.grocerylists.remove(at: grocerylistIndex)
                    self.tableView.deleteRows(at: [IndexPath(row:grocerylistIndex, section: 2)], with: .left)
                    self.tableView.endUpdates()
                }
            }
        } else if sections[indexPath.section - 2] == "Activity Lists" {
            let membersIDs = self.members.map { $0.id ?? "" }
            if let activitylistID = self.activitylists[indexPath.row].ID {
                var activitylistIDs = [String]()
                let newActivitylistName = self.activitylists[indexPath.row].name?.trimmingCharacters(in: .whitespaces) ?? ""
                let text = "The \(newActivitylistName) activity list was disconnected to this chat"
                informationMessageSender.sendInformatoinMessage(chatID: chatID, membersIDs: membersIDs, text: text)
                let activitylistReference = Database.database().reference().child(activitylistsEntity).child(activitylistID).child("conversationID")
                activitylistReference.removeValue()
                let chatReference = Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder).child("activitylists")
                chatReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    for child in snapshot.children {
                        let snap = child as! DataSnapshot
                        let key = snap.key
                        let value = snap.value as! String
                        if activitylistID == value {
                            chatReference.child(key).removeValue()
                        } else {
                            activitylistIDs.append(value)
                        }
                    }
                    let updatedActivities = ["activitylists": activitylistIDs as AnyObject]
                    Database.database().reference().child("groupChats").child(self.chatID).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
                })
                
                guard let activitylistIndex = self.activitylists.firstIndex(where: { (activitylist) -> Bool in
                    return activitylist.ID == activitylistID
                }) else { return }
                
                if tableView.numberOfRows(inSection: indexPath.section) == 1 {
                    self.tableView.beginUpdates()
                    self.activitylists.remove(at: activitylistIndex)
                    self.sections.removeAll(where: {$0 == "Activity Lists"})
                    let indexSet = IndexSet(arrayLiteral: indexPath.section)
                    self.tableView.deleteSections(indexSet, with: .left)
                    self.tableView.endUpdates()
                } else {
                    self.tableView.beginUpdates()
                    self.activitylists.remove(at: activitylistIndex)
                    self.tableView.deleteRows(at: [IndexPath(row:activitylistIndex, section: 2)], with: .left)
                    self.tableView.endUpdates()
                }
            }
        } else if sections[indexPath.section - 2] == "Packing Lists" {
            let membersIDs = self.members.map { $0.id ?? "" }
            if let packinglistID = self.packinglists[indexPath.row].ID {
                var packinglistIDs = [String]()
                let newPackinglistName = self.packinglists[indexPath.row].name?.trimmingCharacters(in: .whitespaces) ?? ""
                let text = "The \(newPackinglistName) packing list was disconnected to this chat"
                informationMessageSender.sendInformatoinMessage(chatID: chatID, membersIDs: membersIDs, text: text)
                let packinglistReference = Database.database().reference().child(packinglistsEntity).child(packinglistID).child("conversationID")
                packinglistReference.removeValue()
                let chatReference = Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder).child("packinglists")
                chatReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    for child in snapshot.children {
                        let snap = child as! DataSnapshot
                        let key = snap.key
                        let value = snap.value as! String
                        if packinglistID == value {
                            chatReference.child(key).removeValue()
                        } else {
                            packinglistIDs.append(value)
                        }
                    }
                    let updatedActivities = ["packinglists": packinglistIDs as AnyObject]
                    Database.database().reference().child("groupChats").child(self.chatID).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
                })
                
                guard let packinglistIndex = self.packinglists.firstIndex(where: { (packinglist) -> Bool in
                    return packinglist.ID == packinglistID
                }) else { return }
                
                if tableView.numberOfRows(inSection: indexPath.section) == 1 {
                    self.tableView.beginUpdates()
                    self.packinglists.remove(at: packinglistIndex)
                    self.sections.removeAll(where: {$0 == "Packing Lists"})
                    let indexSet = IndexSet(arrayLiteral: indexPath.section)
                    self.tableView.deleteSections(indexSet, with: .left)
                    self.tableView.endUpdates()
                } else {
                    self.tableView.beginUpdates()
                    self.packinglists.remove(at: packinglistIndex)
                    self.tableView.deleteRows(at: [IndexPath(row:packinglistIndex, section: 2)], with: .left)
                    self.tableView.endUpdates()
                }
            }
        } 
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            if adminControls == lessAdminControlls {
                groupLeaveAlert()
            }
            else if adminControls == defaultAdminControlls {
                if indexPath.row == 0 {
                    addMembers()
                } else {
                    groupLeaveAlert()
                }
            } else if adminControls == partialAdminControlls {
                if indexPath.row == 0 {
                    addMembers()
                } else if indexPath.row == 1 {
                    updateAdminNeeded()
                } else {
                    groupLeaveAlert()
                }
            } else if adminControls == fullAdminControlls {
                if indexPath.row == 0 {
                    addMembers()
                } else if indexPath.row == 1 {
                    self.changeAdministrator(shouldLeaveTheGroup: false)
                } else if indexPath.row == 2 {
                    updateAdminNeeded()
                } else {
                    groupLeaveAlert()
                }
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    fileprivate func groupLeaveAlert() {
        
        let alertAdminTitle = "Your are admin of this group. If you want to leave the group, you must select new admin first."
        let alertDefaultTitle = "Are you sure?"
        let message = conversationAdminID == Auth.auth().currentUser!.uid ? alertAdminTitle : alertDefaultTitle
        let okActionTitle = conversationAdminID == Auth.auth().currentUser!.uid ? "Choose admin" : "Leave"
        let alertController = UIAlertController(title: "Warning", message: message , preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: okActionTitle, style: UIAlertAction.Style.default) {
            UIAlertAction in
            if self.conversationAdminID == Auth.auth().currentUser!.uid {
                self.changeAdministrator(shouldLeaveTheGroup: true)
            } else {
                self.leaveTheGroup()
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func addMembers() {
        let filteredMembers = users.filter { user in
            return !members.contains { member in
                user.id == member.id
            }
        }
        let destination = AddGroupMembersController()
        destination.filteredUsers = filteredMembers
        destination.users = filteredMembers
        destination.chatIDForUsersUpdate = chatID
        
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    func updateAdminNeeded() {
        let adminNeededReference = Database.database().reference().child("groupChats").child(self.chatID).child(messageMetaDataFirebaseFolder)
        adminNeededReference.updateChildValues(["adminNeeded": !conversationAdminNeeded])
    }
    
    func changeAdministrator(shouldLeaveTheGroup: Bool) {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let membersWithNoAdmin = members.filter { (member) -> Bool in
            return member.id ?? "" != uid
        }
        guard let index = members.firstIndex(where: { (user) -> Bool in
            return user.id == uid
        }), let currentUserName = members[index].name else { return }
        
        var destination: SelectNewAdminTableViewController!
        
        if shouldLeaveTheGroup {
            destination = LeaveGroupAndChangeAdminController()
        } else {
            destination = ChangeGroupAdminController()
        }
        destination.adminControlsController = self
        destination.chatID = chatID
        destination.filteredUsers = membersWithNoAdmin
        destination.users = membersWithNoAdmin
        destination.currentUserName = currentUserName
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    func leaveTheGroup() {
        //    ARSLineProgress.ars_showOnView(self.view)
        if let navController = self.navigationController {
            self.showSpinner(onView: navController.view)
        } else {
            self.showSpinner(onView: self.view)
        }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let index = members.firstIndex(where: { (user) -> Bool in
            return user.id == uid
        }) else { return }
        guard let memberName = members[index].name else { return }
        let text = "\(memberName) left the group"
        let reference = Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder).child("chatParticipantsIDs").child(uid)
        reference.removeValue { (_, _) in
            var membersIDs = self.members.map({$0.id ?? ""})
            membersIDs.append(uid)
            self.informationMessageSender.sendInformatoinMessage(chatID: self.chatID, membersIDs: membersIDs, text: text)
            self.removeSpinner()
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: adminControlsCellID,
                                                     for: indexPath) as? GroupAdminControlsTableViewCell ?? GroupAdminControlsTableViewCell()
            cell.selectionStyle = .none
            cell.title.text = adminControls[indexPath.row]
            
            if cell.title.text == adminControls.last {
                cell.title.textColor = FalconPalette.dismissRed
            } else {
                cell.title.textColor = FalconPalette.defaultBlue
            }
            return cell
            
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: membersCellID, for: indexPath) as? FalconUsersTableViewCell ?? FalconUsersTableViewCell()
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.selectionStyle = .none
            if members[indexPath.row].id == conversationAdminID {
                let label = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 20))
                label.text = "admin"
                label.font = UIFont.systemFont(ofSize: 13)
                label.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }
            
            if let name = members[indexPath.row].name {
                cell.title.text = name
            }
            if members[indexPath.row].id == Auth.auth().currentUser?.uid {
                cell.subtitle.textColor = ThemeManager.currentTheme().generalSubtitleColor
                cell.subtitle.text = "You"
            } else {
                if let statusString = members[indexPath.row].onlineStatus as? String {
                    if statusString == statusOnline {
                        cell.subtitle.textColor = FalconPalette.defaultBlue
                        cell.subtitle.text = statusString
                    } else {
                        cell.subtitle.textColor = ThemeManager.currentTheme().generalSubtitleColor
                        let date = Date(timeIntervalSince1970: TimeInterval(statusString)!)
                        let subtitle = "Last seen " + timeAgoSinceDate(date)
                        cell.subtitle.text = subtitle
                    }
                } else if let statusTimeinterval = members[indexPath.row].onlineStatus as? TimeInterval {
                    cell.subtitle.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    let date = Date(timeIntervalSince1970: statusTimeinterval/1000)
                    let subtitle = "Last seen " + timeAgoSinceDate(date)
                    cell.subtitle.text = subtitle
                }
            }
            
            guard let url = members[indexPath.row].thumbnailPhotoURL else { return cell }
            
            cell.icon.sd_setImage(with: URL(string: url), placeholderImage:  UIImage(named: "UserpicIcon"), options: [.scaleDownLargeImages, .continueInBackground, .avoidAutoSetImage], completed: { (image, _, cacheType, _) in
                
                guard image != nil else { return }
                guard cacheType != SDImageCacheType.memory, cacheType != SDImageCacheType.disk else {
                    cell.icon.image = image
                    return
                }
                
                UIView.transition(with: cell.icon,
                                  duration: 0.2,
                                  options: .transitionCrossDissolve,
                                  animations: { cell.icon.image = image },
                                  completion: nil)
            })
            
            return cell
        } else if sections[indexPath.section - 2] == "Activities" {
            let cell = tableView.dequeueReusableCell(withIdentifier: activityCellID, for: indexPath) as? ChatActivitiesTableViewCell ?? ChatActivitiesTableViewCell()
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.selectionStyle = .none
            cell.configureCell(for: activities[indexPath.row])
            return cell
        } else if sections[indexPath.section - 2] == "Checklists" {
            let cell = tableView.dequeueReusableCell(withIdentifier: listCellID, for: indexPath) as? ChatListTableViewCell ?? ChatListTableViewCell()
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.selectionStyle = .none
            cell.configureCell(checklist: checklists[indexPath.row], grocerylist: nil, packinglist: nil, activitylist: nil)
            return cell
        } else if sections[indexPath.section - 2] == "Grocery Lists" {
            let cell = tableView.dequeueReusableCell(withIdentifier: listCellID, for: indexPath) as? ChatListTableViewCell ?? ChatListTableViewCell()
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.selectionStyle = .none
            cell.configureCell(checklist: nil, grocerylist: grocerylists[indexPath.row], packinglist: nil, activitylist: nil)
            return cell
        } else if sections[indexPath.section - 2] == "Activity Lists" {
            let cell = tableView.dequeueReusableCell(withIdentifier: listCellID, for: indexPath) as? ChatListTableViewCell ?? ChatListTableViewCell()
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.selectionStyle = .none
            cell.configureCell(checklist: nil, grocerylist: nil, packinglist: nil, activitylist: activitylists[indexPath.row])
            return cell
        } else if sections[indexPath.section - 2] == "Packing Lists" {
            let cell = tableView.dequeueReusableCell(withIdentifier: listCellID, for: indexPath) as? ChatListTableViewCell ?? ChatListTableViewCell()
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.selectionStyle = .none
            cell.configureCell(checklist: nil, grocerylist: nil, packinglist: packinglists[indexPath.row], activitylist: nil)
            return cell
        } else {
            let cell = UITableViewCell(style: UITableViewCell.CellStyle.default,
                                       reuseIdentifier: "default")
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            return cell
        }
    }
    
    func handleReloadTable() {
        activities.sort { (activity1, activity2) -> Bool in
            return activity1.startDateTime!.int64Value < activity2.startDateTime!.int64Value
        }
        
        tableView.reloadData()
    }
    
}
