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
    var networkController = NetworkController()
    let phoneNumberKit = PhoneNumberKit()
    let userProfileContainerView = UserProfileContainerView()
    let avatarOpener = AvatarOpener()
    let userProfileDataDatabaseUpdater = UserProfileDataDatabaseUpdater()
    
    let accountSettingsCellId = "userProfileCell"
    
    var firstSection = [( icon: UIImage(named: "CalendarAccounts") , title: "Calendar Info" ),
                        ( icon: UIImage(named: "FinancialAccounts") , title: "Financial Info" ),
//                        ( icon: UIImage(named: "Notification") , title: "Notifications and Sounds" ),
                        ( icon: UIImage(named: "Privacy") , title: "Privacy and Security" ),
//                        ( icon: UIImage(named: "ChangeNumber") , title: "Change Number"),
                        ( icon: UIImage(named: "DataStorage") , title: "Data and Storage")]
    
    var secondSection = [( icon: UIImage(named: "Logout") , title: "Log Out")]
    
    let cancelBarButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelBarButtonPressed))
    let doneBarButton = UIBarButtonItem(title: "Done", style: .done, target: self, action:  #selector(doneBarButtonPressed))
    var currentName = String()
    var currentBio = String()
    let navigationItemActivityIndicator = NavigationItemActivityIndicator()
    let nightMode = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Settings"
        
//        view.backgroundColor = .tertiarySystemBackground
        
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        tableView = UITableView(frame: tableView.frame, style: .insetGrouped)
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for:.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layoutIfNeeded()
        
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
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(emailVerified), name: .emailVerified, object: nil)
    }
    
    fileprivate func configureTableView() {
        tableView.sectionHeaderHeight = 0
        tableView.separatorStyle = .none
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.tableHeaderView = userProfileContainerView
        tableView.register(AccountSettingsTableViewCell.self, forCellReuseIdentifier: accountSettingsCellId)
//        tableView.backgroundColor = .secondarySystemBackground
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
        userProfileContainerView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        userProfileContainerView.bio.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        userProfileContainerView.userData.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        userProfileContainerView.email.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        userProfileContainerView.name.textColor = ThemeManager.currentTheme().generalTitleColor
        userProfileContainerView.phone.textColor = ThemeManager.currentTheme().generalTitleColor
        userProfileContainerView.bio.textColor = ThemeManager.currentTheme().generalTitleColor
        userProfileContainerView.email.textColor = ThemeManager.currentTheme().generalTitleColor
        userProfileContainerView.bio.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
        userProfileContainerView.name.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
    }
//
//    func configureNavigationBar() {
//        nightMode.setImage(UIImage(named: "defaultTheme"), for: .normal)
//        nightMode.setImage(UIImage(named: "darkTheme"), for: .selected)
//        nightMode.imageView?.contentMode = .scaleAspectFit
//        nightMode.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
//        nightMode.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
//        nightMode.addTarget(self, action: #selector(rightBarButtonDidTap(sender:)), for: .touchUpInside)
//        nightMode.isSelected = Bool(ThemeManager.currentTheme().rawValue)
//        let rightBarButton = UIBarButtonItem(customView: nightMode)
//        navigationItem.setRightBarButton(rightBarButton, animated: false)
//    }

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

    @objc fileprivate func changeTheme() {
        nightMode.isSelected = Bool(ThemeManager.currentTheme().rawValue)
        
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.backgroundColor = view.backgroundColor
        
        navigationController?.navigationBar.barStyle = ThemeManager.currentTheme().barStyle
        navigationController?.navigationBar.barTintColor = ThemeManager.currentTheme().barBackgroundColor
        let textAttributes = [NSAttributedString.Key.foregroundColor: ThemeManager.currentTheme().generalTitleColor]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationController?.navigationBar.largeTitleTextAttributes = textAttributes
        navigationController?.navigationBar.backgroundColor = ThemeManager.currentTheme().barBackgroundColor
        
        tabBarController?.tabBar.barTintColor = ThemeManager.currentTheme().barBackgroundColor
        tabBarController?.tabBar.barStyle = ThemeManager.currentTheme().barStyle
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        
        userProfileContainerView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        userProfileContainerView.bio.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        userProfileContainerView.userData.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        userProfileContainerView.email.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        userProfileContainerView.profileImageView.layer.borderColor = ThemeManager.currentTheme().inputTextViewColor.cgColor
        userProfileContainerView.userData.layer.borderColor = ThemeManager.currentTheme().inputTextViewColor.cgColor
        userProfileContainerView.name.textColor = ThemeManager.currentTheme().generalTitleColor
        userProfileContainerView.phone.textColor = ThemeManager.currentTheme().generalTitleColor
        userProfileContainerView.bio.layer.borderColor = ThemeManager.currentTheme().inputTextViewColor.cgColor
        userProfileContainerView.bio.textColor = ThemeManager.currentTheme().generalTitleColor
        userProfileContainerView.email.textColor = ThemeManager.currentTheme().generalTitleColor
        userProfileContainerView.bio.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
        userProfileContainerView.name.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
        tableView.reloadData()
    }
    
    fileprivate func managePresense() {
        if currentReachabilityStatus == .notReachable {
            navigationItemActivityIndicator.showActivityIndicator(for: navigationItem, with: .connecting,
                                                                  activityPriority: .high,
                                                                  color: ThemeManager.currentTheme().generalTitleColor)
        }
        
        let connectedReference = Database.database().reference(withPath: ".info/connected")
        connectedReference.observe(.value, with: { (snapshot) in
            
            if self.currentReachabilityStatus != .notReachable {
                self.navigationItemActivityIndicator.hideActivityIndicator(for: self.navigationItem, activityPriority: .crazy)
            } else {
                self.navigationItemActivityIndicator.showActivityIndicator(for: self.navigationItem, with: .noInternet, activityPriority: .crazy, color: ThemeManager.currentTheme().generalTitleColor)
            }
        })
    }
    
    @objc fileprivate func openUserProfilePicture() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        avatarOpener.delegate = self
        avatarOpener.handleAvatarOpening(avatarView: userProfileContainerView.profileImageView, at: self, isEditButtonEnabled: true, title: .user)
        cancelBarButtonPressed()
    }
    
    @objc fileprivate func rightBarButtonDidTap(sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            let theme = Theme.Dark
            ThemeManager.applyTheme(theme: theme)
        } else {
            let theme = Theme.Default
            ThemeManager.applyTheme(theme: theme)
        }
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
        AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
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
        AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
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
            basicErrorAlertWith(title: "Error signing out", message: noInternetError, controller: self)
            return
            
        }

        #warning("Not sure if still used.")
        Database.database().reference(withPath: ".info/connected").removeAllObservers()

        let onlineStatusReference = Database.database().reference().child("users").child(uid).child("OnlineStatus")
        onlineStatusReference.setValue(ServerValue.timestamp())

        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            basicErrorAlertWith(title: "Error signing out", message: signOutError.localizedDescription, controller: self)
            return
        }

        AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
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
            cell.accessoryType = .none
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let destination = CalendarInfoViewController()
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
            logoutButtonTapped()
        }        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            return firstSection.count
        }
        if section == 1 {
            return secondSection.count
        } else {
            return 0
        }
    }
}
