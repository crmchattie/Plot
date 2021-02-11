//
//  GroupProfileTableViewController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/13/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage

class GroupProfileTableViewController: UITableViewController {
  
  fileprivate var selectedFlaconUsersCellID = "selectedFalconUsersCellID"
  fileprivate let adminControlsCellID = "adminControlsCellID"
  var selectedFlaconUsers = [User]()
  let groupProfileTableHeaderContainer = GroupProfileTableHeaderContainer()
  let avatarOpener = AvatarOpener()
  let chatCreatingGroup = DispatchGroup()
  let informationMessageSender = InformationMessageSender()
  var conversationAdminNeeded = false
    
  var activityObject: ActivityObject?

  
  override func viewDidLoad() {
    super.viewDidLoad()
      
    setupMainView()
    setupTableView()
    configureContainerView()
    configureColorsAccordingToTheme()
  }
  
  fileprivate func setupMainView() {
    if #available(iOS 11.0, *) {
      navigationItem.largeTitleDisplayMode = .never
      navigationController?.navigationBar.prefersLargeTitles = false
    }
    navigationItem.title = "New Group"
    extendedLayoutIncludesOpaqueBars = true
    definesPresentationContext = true
    edgesForExtendedLayout = [UIRectEdge.top, UIRectEdge.bottom]
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Create", style: .done, target: self, action: #selector(createGroupChat))
    navigationItem.rightBarButtonItem?.isEnabled = false
  }
  
  fileprivate func setupTableView() {
    tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
    tableView.sectionIndexBackgroundColor = view.backgroundColor
    tableView.backgroundColor = view.backgroundColor
    tableView.register(GroupAdminControlsTableViewCell.self, forCellReuseIdentifier: adminControlsCellID)
    tableView.register(FalconUsersTableViewCell.self, forCellReuseIdentifier: selectedFlaconUsersCellID)
    tableView.separatorStyle = .none
    tableView.allowsSelection = true
  }
  
  fileprivate func configureContainerView() {
    groupProfileTableHeaderContainer.profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openUserProfilePicture)))
    groupProfileTableHeaderContainer.name.delegate = self
    groupProfileTableHeaderContainer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 170)
    tableView.tableHeaderView = groupProfileTableHeaderContainer
    groupProfileTableHeaderContainer.name.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    
  }
  
  fileprivate func configureColorsAccordingToTheme() {
    groupProfileTableHeaderContainer.profileImageView.layer.borderColor = ThemeManager.currentTheme().inputTextViewColor.cgColor
    groupProfileTableHeaderContainer.userData.layer.borderColor = ThemeManager.currentTheme().inputTextViewColor.cgColor
    groupProfileTableHeaderContainer.name.textColor = ThemeManager.currentTheme().generalTitleColor
    groupProfileTableHeaderContainer.name.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
  }
    
    func checkIfGroupExists() {
        
    }
  
  @objc fileprivate func openUserProfilePicture() {
    guard currentReachabilityStatus != .notReachable else {
      basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
      return
    }
    avatarOpener.delegate = self 
    avatarOpener.handleAvatarOpening(avatarView: groupProfileTableHeaderContainer.profileImageView, at: self,
                                     isEditButtonEnabled: true, title: .group)
  }
  
  @objc func textFieldDidChange(_ textField: UITextField) {
    if textField.text?.count == 0 {
      navigationItem.rightBarButtonItem?.isEnabled = false
    } else {
      navigationItem.rightBarButtonItem?.isEnabled = true
    }
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return ""
        }
        return "\(selectedFlaconUsers.count) members"
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if section == 0 {
            return 20
        }
        return 20
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let height: CGFloat = 40
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
            return 1
        }
        return selectedFlaconUsers.count
    }

  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 60
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.section == 0 {
        let cell = tableView.dequeueReusableCell(withIdentifier: adminControlsCellID,
                                                 for: indexPath) as? GroupAdminControlsTableViewCell ?? GroupAdminControlsTableViewCell()
        
        
        if conversationAdminNeeded == false {
            cell.title.text = "Add Admin"
        } else {
            cell.title.text = "Remove Admin"
        }
        
        cell.title.textColor = FalconPalette.defaultBlue
        
        return cell
        
    } else {
        let cell = tableView.dequeueReusableCell(withIdentifier: selectedFlaconUsersCellID, for: indexPath) as? FalconUsersTableViewCell ?? FalconUsersTableViewCell()
        let user = selectedFlaconUsers[indexPath.row]
        cell.configureCell(for: user)
        
        return cell
    }
  }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            updateAdminNeeded()
        }
    }
    
    func updateAdminNeeded() {
        conversationAdminNeeded = !conversationAdminNeeded
        print(conversationAdminNeeded)
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}

extension GroupProfileTableViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
}

extension GroupProfileTableViewController {

  @objc func createGroupChat() {
    guard currentReachabilityStatus != .notReachable, let chatName = groupProfileTableHeaderContainer.name.text, let currentUserID = Auth.auth().currentUser?.uid else {
      basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
      return
    }
    
    let membersIDs = fetchMembersIDs()
    let chatImage = groupProfileTableHeaderContainer.profileImageView.image
    let chatID = Database.database().reference().child("user-messages").child(currentUserID).childByAutoId().key ?? ""
    let groupChatsReference = Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder)
    let childValues: [String: AnyObject] = ["chatID": chatID as AnyObject, "chatName": chatName as AnyObject, "chatParticipantsIDs": membersIDs.1 as AnyObject, "admin": currentUserID as AnyObject, "adminNeeded": conversationAdminNeeded as AnyObject, "isGroupChat": true as AnyObject]
  
    chatCreatingGroup.enter()
    chatCreatingGroup.enter()
    chatCreatingGroup.enter()
    createGroupNode(reference: groupChatsReference, childValues: childValues, noImagesToUpload: chatImage == nil)
    uploadAvatar(chatImage: chatImage, reference: groupChatsReference)
    connectMembersToGroup(memberIDs: membersIDs.0, chatID: chatID)
    
    chatCreatingGroup.notify(queue: DispatchQueue.main, execute: {
        self.hideActivityIndicator()
        print("Chat creating finished...")
        self.informationMessageSender.sendInformatoinMessage(chatID: chatID, membersIDs: membersIDs.0, text: "New group has been created")
        if let activityObject = self.activityObject {
            let conversation = Conversation(dictionary: childValues)
            let messageSender = MessageSender(conversation, text: activityObject.activityName, media: nil, activity: activityObject)
            messageSender.sendMessage()
            self.messageSentAlert()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                self.removeMessageAlert()
                self.dismiss(animated: true, completion: nil)
            })
            return
      }
      self.navigationController?.backToViewController(viewController: ChatsTableViewController.self)
    })
  }
  
  func fetchMembersIDs() -> ([String], [String:AnyObject]) {
    var membersIDs = [String]()
    var membersIDsDictionary = [String:AnyObject]()
    
    guard let currentUserID = Auth.auth().currentUser?.uid else { return (membersIDs, membersIDsDictionary) }
    
    membersIDsDictionary.updateValue(currentUserID as AnyObject, forKey: currentUserID)
    membersIDs.append(currentUserID)
    
    for selectedUser in selectedFlaconUsers {
      guard let id = selectedUser.id else { continue }
      membersIDsDictionary.updateValue(id as AnyObject, forKey: id)
      membersIDs.append(id)
    }
  
    return (membersIDs, membersIDsDictionary)
  }
  
  func showActivityIndicator() {
//    ARSLineProgress.show()
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
//    ARSLineProgress.showSuccess()
  }
  
  func uploadAvatar(chatImage: UIImage?, reference: DatabaseReference) {
    guard let image = chatImage else { self.chatCreatingGroup.leave(); return }
    let thumbnailImage = createImageThumbnail(image)
    var images = [(image: UIImage, quality: CGFloat, key: String)]()
    let compressedImageData = compressImage(image: image)
    let compressedImage = UIImage(data: compressedImageData)
    images.append((image: compressedImage!, quality: 0.5, key: "chatOriginalPhotoURL"))
    images.append((image: thumbnailImage, quality: 1, key: "chatThumbnailPhotoURL"))
    let photoUpdatingGroup = DispatchGroup()
    for _ in images { photoUpdatingGroup.enter() }

    photoUpdatingGroup.notify(queue: DispatchQueue.main, execute: {
      self.chatCreatingGroup.leave()
    })
    
    for imageElement in images {
      uploadAvatarForUserToFirebaseStorageUsingImage(imageElement.image, quality: imageElement.quality) { (url) in
        reference.updateChildValues([imageElement.key: url], withCompletionBlock: { (_, _) in
          photoUpdatingGroup.leave()
        })
      }
    }
  }
  
  func connectMembersToGroup(memberIDs: [String], chatID: String) {
    let connectingMembersGroup = DispatchGroup()
    for _ in memberIDs {
      connectingMembersGroup.enter()
    }
    connectingMembersGroup.notify(queue: DispatchQueue.main, execute: {
      self.chatCreatingGroup.leave()
    })
    for memberID in memberIDs {
      let userReference = Database.database().reference().child("user-messages").child(memberID).child(chatID).child(messageMetaDataFirebaseFolder)
      let values:[String : Any] = ["isGroupChat": true]
      userReference.updateChildValues(values, withCompletionBlock: { (error, reference) in
        connectingMembersGroup.leave()
      })
    }
  }
  
  func createGroupNode(reference: DatabaseReference, childValues: [String: Any], noImagesToUpload: Bool) {
    showActivityIndicator()
    let nodeCreationGroup = DispatchGroup()
    nodeCreationGroup.enter()
    nodeCreationGroup.notify(queue: DispatchQueue.main, execute: {
        Analytics.logEvent("new_chat", parameters: [:])
      self.chatCreatingGroup.leave()
    })
    reference.updateChildValues(childValues) { (error, reference) in
      nodeCreationGroup.leave()
    }
  }
}
