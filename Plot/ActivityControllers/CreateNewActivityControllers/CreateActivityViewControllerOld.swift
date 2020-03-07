//
//  CreateActivityViewController.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 4/28/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit
import MapKit
import Firebase


class CreateActivityViewControllerOld: UIViewController {
    
    let createActivityView = CreateActivityViewOld()
    
    var users = [User]()
    var filteredUsers = [User]()
    var selectedFalconUsers = [User]()
    let avatarOpener = AvatarOpener()
    var locationAddress: String = ""
    
    typealias CompletionHandler = (_ success: Bool) -> Void
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        view.addSubview(createActivityView)
        
        setupMainView()
        configureContainerView()

//        addObservers()

//        configureColorsAccordingToTheme()
    }

    
    fileprivate func setupMainView() {
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .always
            navigationController?.navigationBar.prefersLargeTitles = true
        }
        navigationItem.title = "New Activity"
        extendedLayoutIncludesOpaqueBars = true
        definesPresentationContext = true
        edgesForExtendedLayout = []
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Create", style: .done, target: self, action: #selector(createNewActivity))
        navigationItem.rightBarButtonItem?.isEnabled = false

    }
    
    fileprivate func configureContainerView() {
        createActivityView.frame = view.bounds
        createActivityView.activityImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openActivityPicture)))
        createActivityView.activityParticipantsView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openParticipantsInviter)))
        createActivityView.activityLocation.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openLocationFinder)))
        
        createActivityView.activityName.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        createActivityView.activityName.delegate = self
        createActivityView.activityType.delegate = self
        createActivityView.activityDescription.delegate = self
    //        createActivityView.activityParticipantsView.delegate = self
        createActivityView.activityLocation.delegate = self
    }
    
//    fileprivate func configureColorsAccordingToTheme() {
//        createActivityView.activityImageView.layer.borderColor = ThemeManager.currentTheme().inputTextViewColor.cgColor
//        createActivityView.activityName.textColor = ThemeManager.currentTheme().generalTitleColor
//        createActivityView.activityDescription.layer.borderColor = ThemeManager.currentTheme().inputTextViewColor.cgColor
//        createActivityView.activityDescription.textColor = ThemeManager.currentTheme().generalTitleColor
//        createActivityView.activityDescription.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
//        createActivityView.activityName.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
//    }
    
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        createActivityView.frame = view.bounds
        createActivityView.layoutIfNeeded()
    }
    
    @objc fileprivate func openActivityPicture() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        avatarOpener.delegate = self
        avatarOpener.handleAvatarOpening(avatarView: createActivityView.activityImageView, at: self,
                                         isEditButtonEnabled: true, title: .activity)
    }
    
    @objc fileprivate func openParticipantsInviter() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        let destination = SelectActivityMembersViewController()
        destination.users = users
        destination.filteredUsers = filteredUsers
        destination.delegate = self
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    @objc fileprivate func openLocationFinder() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        let destination = LocationFinderTableViewController()
        destination.delegate = self
        self.navigationController?.pushViewController(destination, animated: true)

//        present(destination, animated: true, completion: nil)
    }
    
    @objc func createNewActivity () {
//        guard currentReachabilityStatus != .notReachable, let chatName = groupProfileTableHeaderContainer.name.text, let currentUserID = Auth.auth().currentUser?.uid else {
//            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
//            return
//        }
//
//        let membersIDs = fetchMembersIDs()
//        let chatImage = groupProfileTableHeaderContainer.profileImageView.image
//        let chatID = Database.database().reference().child("user-messages").child(currentUserID).childByAutoId().key ?? ""
//        let groupChatsReference = Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder)
//        let childValues: [String: AnyObject] = ["chatID": chatID as AnyObject, "chatName": chatName as AnyObject, "chatParticipantsIDs": membersIDs.1 as AnyObject, "admin": currentUserID as AnyObject,"isGroupChat": true as AnyObject]
//
//        chatCreatingGroup.enter()
//        chatCreatingGroup.enter()
//        chatCreatingGroup.enter()
//        createGroupNode(reference: groupChatsReference, childValues: childValues, noImagesToUpload: chatImage == nil)
//        uploadAvatar(chatImage: chatImage, reference: groupChatsReference)
//        connectMembersToGroup(memberIDs: membersIDs.0, chatID: chatID)
//
//        chatCreatingGroup.notify(queue: DispatchQueue.main, execute: {
//            self.hideActivityIndicator()
//            print("Chat creating finished...")
//            self.informationMessageSender.sendInformatoinMessage(chatID: chatID, membersIDs: membersIDs.0, text: "New group has been created")
//            self.navigationController?.backToViewController(viewController: ChatsTableViewController.self)
//        })
    }
    
    func fetchMembersIDs() -> ([String], [String:AnyObject]) {
        var membersIDs = [String]()
        var membersIDsDictionary = [String:AnyObject]()
        
        guard let currentUserID = Auth.auth().currentUser?.uid else { return (membersIDs, membersIDsDictionary) }
        
        membersIDsDictionary.updateValue(currentUserID as AnyObject, forKey: currentUserID)
        membersIDs.append(currentUserID)
        
        for selectedUser in selectedFalconUsers {
            guard let id = selectedUser.id else { continue }
            membersIDsDictionary.updateValue(id as AnyObject, forKey: id)
            membersIDs.append(id)
        }
        
        return (membersIDs, membersIDsDictionary)
    }
    
//    func uploadAvatar(chatImage: UIImage?, reference: DatabaseReference) {
//        guard let image = chatImage else { self.chatCreatingGroup.leave(); return }
//        let thumbnailImage = createImageThumbnail(image)
//        var images = [(image: UIImage, quality: CGFloat, key: String)]()
//        let compressedImageData = compressImage(image: image)
//        let compressedImage = UIImage(data: compressedImageData)
//        images.append((image: compressedImage!, quality: 0.5, key: "chatOriginalPhotoURL"))
//        images.append((image: thumbnailImage, quality: 1, key: "chatThumbnailPhotoURL"))
//        let photoUpdatingGroup = DispatchGroup()
//        for _ in images { photoUpdatingGroup.enter() }
//        
//        photoUpdatingGroup.notify(queue: DispatchQueue.main, execute: {
//            self.chatCreatingGroup.leave()
//        })
//        
//        for imageElement in images {
//            uploadAvatarForUserToFirebaseStorageUsingImage(imageElement.image, quality: imageElement.quality) { (url) in
//                reference.updateChildValues([imageElement.key: url], withCompletionBlock: { (_, _) in
//                    photoUpdatingGroup.leave()
//                })
//            }
//        }
//    }
    
    
}

extension CreateActivityViewControllerOld: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if textField.text?.count == 0 {
            navigationItem.rightBarButtonItem?.isEnabled = false
            navigationItem.title = "New Activity"
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = true
            navigationItem.title = textField.text
        }
    }
}
    

extension CreateActivityViewControllerOld: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
//        createActivityView.activityDescriptionPlaceholderLabel.isHidden = true
        if textView.textColor == FalconPalette.defaultBlue {
            textView.text = nil
            textView.textColor = ThemeManager.currentTheme().generalTitleColor
        }


    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
//        createActivityView.activityDescriptionPlaceholderLabel.isHidden = !textView.text.isEmpty
        if textView.text.isEmpty {
            textView.text = "Description"
            textView.textColor = FalconPalette.defaultBlue
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
    }
    
}

extension CreateActivityViewControllerOld: UpdateLocation {
    
    func updateLocation(locationName: String, locationAddress: String) {
        if locationName != "Location" {
            createActivityView.activityLocation.textColor = ThemeManager.currentTheme().generalTitleColor
            createActivityView.activityLocation.text = locationName
            self.locationAddress = locationAddress
        } else {
            createActivityView.activityLocation.text = "Location"
            createActivityView.activityLocation.textColor = FalconPalette.defaultBlue
        }
        
    }
}

extension CreateActivityViewControllerOld: UpdateInvitees {
    
    func updateInvitees(selectedFalconUsers: [User]) {
        if !selectedFalconUsers.isEmpty {
            var userNames : [String] = []
            createActivityView.addParticipantsLabel.textColor = ThemeManager.currentTheme().generalTitleColor
            for user in selectedFalconUsers {
                userNames.append(user.name ?? "")
            }
            let userNamesString = userNames.joined(separator:", ")
            createActivityView.addParticipantsLabel.text = userNamesString
        }
    }
}

extension CreateActivityViewControllerOld: AvatarOpenerDelegate {
    func avatarOpener(avatarPickerDidPick image: UIImage) {
        createActivityView.activityImageView.image = image
    }
    
    func avatarOpener(didPerformDeletionAction: Bool) {
        createActivityView.activityImageView.image = nil
    }
}

//extension CreateActivityViewController: AvatarOpenerDelegate {
//    func avatarOpener(avatarPickerDidPick image: UIImage) {
//        createActivityView.profileImageView.showActivityIndicator()
//        userProfileDataDatabaseUpdater.deleteCurrentPhoto { (isDeleted) in
//            self.userProfileDataDatabaseUpdater.updateUserProfile(with: image, completion: { (isUpdated) in
//                self.userProfileContainerView.profileImageView.hideActivityIndicator()
//                guard isUpdated else {
//                    basicErrorAlertWith(title: basicErrorTitleForAlert, message: thumbnailUploadError, controller: self)
//                    return
//                }
//                self.userProfileContainerView.profileImageView.image = image
//
//            })
//        }
//    }
//
//    func avatarOpener(didPerformDeletionAction: Bool) {
//        userProfileContainerView.profileImageView.showActivityIndicator()
//        userProfileDataDatabaseUpdater.deleteCurrentPhoto { (isDeleted) in
//            self.userProfileContainerView.profileImageView.hideActivityIndicator()
//            guard isDeleted else {
//                basicErrorAlertWith(title: basicErrorTitleForAlert, message: deletionErrorMessage, controller: self)
//                return
//            }
//            self.userProfileContainerView.profileImageView.image = nil
//        }
//    }
//}
