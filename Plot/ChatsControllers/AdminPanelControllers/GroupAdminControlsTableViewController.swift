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
import ARSLineProgress

class GroupAdminControlsTableViewController: UITableViewController {
  
  fileprivate let membersCellID = "membersCellID"
  fileprivate let adminControlsCellID = "adminControlsCellID"
  fileprivate let activityCellID = "activityCellID"
  
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
  var activities = [Activity]()
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
      navigationItem.largeTitleDisplayMode = .always
      navigationController?.navigationBar.prefersLargeTitles = true
    }
    navigationItem.title = "Group Info"
    extendedLayoutIncludesOpaqueBars = true
    definesPresentationContext = true
    edgesForExtendedLayout = [UIRectEdge.top, UIRectEdge.bottom]
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
  }
  
  fileprivate func setupTableView() {
    tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
    tableView.sectionIndexBackgroundColor = view.backgroundColor
    tableView.backgroundColor = view.backgroundColor
    tableView.register(FalconUsersTableViewCell.self, forCellReuseIdentifier: membersCellID)
    tableView.register(GroupAdminControlsTableViewCell.self, forCellReuseIdentifier: adminControlsCellID)
    tableView.register(ChatActivitiesTableViewCell.self, forCellReuseIdentifier: activityCellID)
    tableView.separatorStyle = .none
    tableView.allowsSelection = true
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
    groupProfileTableHeaderContainer.profileImageView.layer.borderColor = ThemeManager.currentTheme().inputTextViewColor.cgColor
    groupProfileTableHeaderContainer.userData.layer.borderColor = ThemeManager.currentTheme().inputTextViewColor.cgColor
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
          
          self.tableView.headerView(forSection: 1)?.textLabel?.text = "\(self.members.count) members"
          self.tableView.headerView(forSection: 1)?.textLabel?.sizeToFit()
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
      self.tableView.headerView(forSection: 1)?.textLabel?.text = "\(self.members.count) members"
      self.tableView.headerView(forSection: 1)?.textLabel?.sizeToFit()
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
    if !activities.isEmpty {
        return 3
    } else {
        return 2
    }
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    if section == 0 {
      if adminControls.count == 0 {
        return ""
      }
      return ""
    } else if section == 1 {
    return "\(members.count) members"
    } else {
        if !activities.isEmpty {
            return "Activities"
        } else {
            return ""
        }
    }
  }

  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    
//    if section == 0 {
//      return 20
//    }
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
//      headerTitle.textLabel?.font = UIFont.systemFont(ofSize: 14)
        headerTitle.textLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        headerTitle.textLabel?.adjustsFontForContentSizeCategory = true
    }
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
        return adminControls.count
    } else if section == 1 {
        return members.count
    } else {
        return activities.count
    }
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 60
  }
  
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    if indexPath.section == 1, members[indexPath.row].id != conversationAdminID, members[indexPath.row].id != Auth.auth().currentUser!.uid {
        return true
    } else if indexPath.section == 2 {
        return true
    }
    else {
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
        } else if indexPath.section == 2 {
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
                
                if tableView.numberOfRows(inSection: 2) == 1 {
                    self.tableView.beginUpdates()
                    self.activities.remove(at: activityIndex)
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
    } else if indexPath.section == 2 {
//        var activity: Activity!
//
//        activity = activities[indexPath.row]
//                
//        let destination = CreateActivityViewController()
//        destination.hidesBottomBarWhenPushed = true
//        destination.activity = activity
//        destination.conversation = conversation
//        destination.users = members
//        destination.filteredUsers = members
//
//        navigationController?.pushViewController(destination, animated: true)
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
    let filteredMembers = globalUsers.filter { user in
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
//      ARSLineProgress.hide()
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
      cell.selectionStyle = .none
      if members[indexPath.row].id == conversationAdminID {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 20))
        label.text = "admin"
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
				cell.accessoryType = UITableViewCell.AccessoryType.none
        cell.accessoryView = label
        cell.accessoryView?.backgroundColor = UIColor.clear
      } else {
        cell.accessoryView = nil
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
    } else {
        let cell = tableView.dequeueReusableCell(withIdentifier: activityCellID, for: indexPath) as? ChatActivitiesTableViewCell ?? ChatActivitiesTableViewCell()
        cell.selectionStyle = .default
        
        cell.configureCell(for: activities[indexPath.row])
        
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
