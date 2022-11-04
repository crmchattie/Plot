//
//  AccountSettingsController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/5/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import PhoneNumberKit

class AccountSettingsController: UITableViewController {
    let networkController: NetworkController
    let phoneNumberKit = PhoneNumberKit()
    let userProfileContainerView = UserProfileContainerView()
    let avatarOpener = AvatarOpener()
    let userProfileDataDatabaseUpdater = UserProfileDataDatabaseUpdater()
    
    let accountSettingsCellId = "userProfileCell"
    
    var firstSection = [( icon: UIImage(named: "CalendarAccounts") , title: "Time Info" ),
                        ( icon: UIImage(named: "FinancialAccounts") , title: "Financial Info" ),
//                        ( icon: UIImage(named: "Notification") , title: "Notifications and Sounds" ),
                        ( icon: UIImage(named: "Privacy") , title: "Privacy and Security" ),
//                        ( icon: UIImage(named: "ChangeNumber") , title: "Change Number"),
                        ( icon: UIImage(named: "DataStorage") , title: "Data and Storage")]
    
    var secondSection = [( icon: UIImage(named: "Feedback") , title: "Feedback")]
    var thirdSection = [( icon: UIImage(named: "Logout") , title: "Log Out")]
    
    var cancelBarButton = UIBarButtonItem()
    var updateBarButton = UIBarButtonItem()
    var doneBarButton = UIBarButtonItem()
    var currentName = String()
    var currentBio = String()
    let navigationItemActivityIndicator = NavigationItemActivityIndicator()
    let nightMode = UIButton()
    
    init(networkController: NetworkController) {
        self.networkController = networkController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Settings"
                
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        tableView = UITableView(frame: tableView.frame, style: .insetGrouped)
        
        cancelBarButton = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(cancelBarButtonPressed))
        updateBarButton = UIBarButtonItem(title: "Update", style: .done, target: self, action:  #selector(updateBarButtonPressed))
        doneBarButton = UIBarButtonItem(title: "Done", style: .done, target: self, action:  #selector(doneBarButtonPressed))
        
        navigationItem.rightBarButtonItem = doneBarButton
        
        configureTableView()
        configureContainerView()
        listenChanges()
        addObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        managePresense()
        if userProfileContainerView.phone.text == "" {
            listenChanges()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let headerView = tableView.tableHeaderView {
            let height = tableHeaderHeight()
            var headerFrame = headerView.frame
            if height != headerFrame.size.height {
                headerFrame.size.height = height
                headerView.frame = headerFrame
                tableView.tableHeaderView = headerView
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(clearUserData), name: NSNotification.Name(rawValue: "clearUserData"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(emailVerified), name: .emailVerified, object: nil)
    }
    
    fileprivate func configureTableView() {
        tableView.backgroundColor = .systemGroupedBackground
        tableView.sectionHeaderHeight = 0
        tableView.separatorStyle = .none
        tableView.indicatorStyle = .default
        tableView.tableHeaderView = userProfileContainerView
        tableView.register(AccountSettingsTableViewCell.self, forCellReuseIdentifier: accountSettingsCellId)
    }
    
    fileprivate func configureContainerView() {
        userProfileContainerView.name.addTarget(self, action: #selector(nameDidBeginEditing), for: .editingDidBegin)
        userProfileContainerView.name.addTarget(self, action: #selector(nameEditingChanged), for: .editingChanged)
        userProfileContainerView.phone.addTarget(self, action: #selector(changePhoneNumber), for: .editingDidBegin)
        userProfileContainerView.email.addTarget(self, action: #selector(changeEmail), for: .editingDidBegin)
        userProfileContainerView.profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openUserProfilePicture)))
        userProfileContainerView.bio.delegate = self
        userProfileContainerView.email.delegate = self
        userProfileContainerView.name.delegate = self
        userProfileContainerView.phone.delegate = self
        userProfileContainerView.backgroundColor = .systemGroupedBackground
        userProfileContainerView.bio.backgroundColor = .secondarySystemGroupedBackground
        userProfileContainerView.userData.backgroundColor = .secondarySystemGroupedBackground
//        userProfileContainerView.email.backgroundColor = .secondarySystemGroupedBackground
        userProfileContainerView.name.textColor = .label
        userProfileContainerView.phone.textColor = .label
        userProfileContainerView.bio.textColor = .label
        userProfileContainerView.email.textColor = .label
        userProfileContainerView.bio.keyboardAppearance = .default
        userProfileContainerView.name.keyboardAppearance = .default
    }
    
    @objc func doneBarButtonPressed() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc private func emailVerified(_ notification: Notification) {
        guard let email = notification.object as? String, email.isValidEmail else { return }

        userProfileContainerView.email.text = email

        let userNameReference = Database.database().reference().child("users").child(Auth.auth().currentUser!.uid)
        userNameReference.updateChildValues(["email": email])

        // Dismiss Change email controller if presented
        if (presentedViewController as? UINavigationController)?.viewControllers.first is ChangeEmailController {
            dismiss(animated: true, completion: nil)
        }
    }
    
    fileprivate func managePresense() {
        if currentReachabilityStatus == .notReachable {
            navigationItemActivityIndicator.showActivityIndicator(for: navigationItem, with: .connecting,
                                                                  activityPriority: .high,
                                                                  color: .label)
        }
        
        let connectedReference = Database.database().reference(withPath: ".info/connected")
        connectedReference.observe(.value, with: { (snapshot) in
            
            if self.currentReachabilityStatus != .notReachable {
                self.navigationItemActivityIndicator.hideActivityIndicator(for: self.navigationItem, activityPriority: .crazy)
            } else {
                self.navigationItemActivityIndicator.showActivityIndicator(for: self.navigationItem, with: .noInternet, activityPriority: .crazy, color: .label)
            }
        })
    }
    
    @objc fileprivate func openUserProfilePicture() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWithClose(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        avatarOpener.delegate = self
        avatarOpener.handleAvatarOpening(avatarView: userProfileContainerView.profileImageView, at: self, isEditButtonEnabled: true, title: .user)
        cancelBarButtonPressed()
    }
    
    @objc func clearUserData() {
        userProfileContainerView.name.text = ""
        userProfileContainerView.phone.text = ""
        userProfileContainerView.profileImageView.image = nil
    }
    
    func listenChanges() {
        if let currentUser = Auth.auth().currentUser?.uid {
            Database.database().reference().child("users").child(currentUser).observe(.value, with: { snapshot in
                guard let userInfo = snapshot.value as? [String: Any] else { return }
                
                if let photoUrl = userInfo["photoURL"] as? String {
                    self.userProfileContainerView.profileImageView.sd_setImage(with: URL(string: photoUrl), placeholderImage: nil, options: [.scaleDownLargeImages, .continueInBackground], completed: nil)
                    self.userProfileContainerView.addPhotoLabel.isHidden = true
                }
                if let name = userInfo["name"] as? String {
                    self.userProfileContainerView.name.text = name
                    self.currentName = name
                }
                if let bio = userInfo["bio"] as? String {
                    self.userProfileContainerView.bio.text = bio
                    self.userProfileContainerView.bioPlaceholderLabel.isHidden = !self.userProfileContainerView.bio.text.isEmpty
                    self.currentBio = bio
                }
                self.userProfileContainerView.email.text = userInfo["email"] as? String
                
                if let phoneNumber = userInfo["phoneNumber"] as? String {
                    do {
                        let phoneNumber = try self.phoneNumberKit.parse(phoneNumber)
                        self.userProfileContainerView.phone.text = self.phoneNumberKit.format(phoneNumber, toType: .international)
                    } catch {
                        self.userProfileContainerView.phone.text = phoneNumber
                    }
                }
            })
        }
    }
    
    @objc func changePhoneNumber() {
        cancelBarButtonPressed()
        let controller = ChangePhoneNumberController()
        let destination = UINavigationController(rootViewController: controller)
        destination.navigationBar.shadowImage = UIImage()
        destination.navigationBar.setBackgroundImage(UIImage(), for: .default)
        destination.hidesBottomBarWhenPushed = true
        destination.navigationBar.isTranslucent = false
        present(destination, animated: true, completion: nil)
    }
    
    @objc func changeEmail() {
        cancelBarButtonPressed()
        let controller = ChangeEmailController()
        let destination = UINavigationController(rootViewController: controller)
        destination.navigationBar.shadowImage = UIImage()
        destination.navigationBar.setBackgroundImage(UIImage(), for: .default)
        destination.hidesBottomBarWhenPushed = true
        destination.navigationBar.isTranslucent = false
        present(destination, animated: true, completion: nil)
    }
    
    func logoutButtonTapped () {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWithClose(title: "Error signing out", message: noInternetError, controller: self)
            return
            
        }

//        warning("Not sure if still used.")
        Database.database().reference(withPath: ".info/connected").removeAllObservers()

        let onlineStatusReference = Database.database().reference().child("users").child(uid).child("OnlineStatus")
        onlineStatusReference.setValue(ServerValue.timestamp())

        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            basicErrorAlertWithClose(title: "Error signing out", message: signOutError.localizedDescription, controller: self)
            return
        }

        UIApplication.shared.applicationIconBadgeNumber = 0

        let destination = OnboardingController()

        let newNavigationController = UINavigationController(rootViewController: destination)
        newNavigationController.navigationBar.shadowImage = UIImage()
        newNavigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)

        newNavigationController.modalPresentationStyle = .fullScreen
        newNavigationController.navigationBar.isTranslucent = false
        newNavigationController.modalTransitionStyle = .crossDissolve

        present(newNavigationController, animated: true, completion: {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "clearUserData"), object: nil)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "clearContacts"), object: nil)
            self.tabBarController?.selectedIndex = Tabs.home.rawValue
        })
    }
}

extension AccountSettingsController {
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: accountSettingsCellId,
                                                 for: indexPath) as? AccountSettingsTableViewCell ?? AccountSettingsTableViewCell()
        cell.accessoryType = .disclosureIndicator
        if indexPath.section == 0 {
            cell.icon.image = firstSection[indexPath.row].icon
            cell.title.text = firstSection[indexPath.row].title
        }
        
        if indexPath.section == 1 {
            cell.icon.image = secondSection[indexPath.row].icon
            cell.title.text = secondSection[indexPath.row].title
        }
        
        if indexPath.section == 2 {
            cell.icon.image = thirdSection[indexPath.row].icon
            cell.title.text = thirdSection[indexPath.row].title
            cell.accessoryType = .none
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let destination = TimeInfoViewController()
                destination.networkController = networkController
                destination.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(destination, animated: true)
            }
            
            if indexPath.row == 1 {
                let destination = FinancialInfoViewController()
                destination.networkController = networkController
                destination.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(destination, animated: true)
            }
            
            if indexPath.row == 2 {
                let destination = PrivacyTableViewController()
                destination.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(destination, animated: true)
            }
            
            if indexPath.row == 3 {
                let destination = StorageTableViewController()
                destination.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(destination, animated: true)
            }
        }
        
        if indexPath.section == 1 {
            let destination = FeedbackViewController()
            destination.hidesBottomBarWhenPushed = true
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
        if indexPath.section == 2 {
            logoutButtonTapped()
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            return firstSection.count
        } else if section == 1 {
            return secondSection.count
        } else if section == 2 {
            return thirdSection.count
        } else {
            return 0
        }
    }
}
