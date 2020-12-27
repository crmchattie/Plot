//
//  MasterActivityController.swift
//  Plot
//
//  Created by Cory McHattie on 4/21/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Contacts
import Firebase
import LBTATools

fileprivate let activitiesControllerCell = "ActivitiesControllerCell"
fileprivate let healthControllerCell = "HealthControllerCell"
fileprivate let financeControllerCell = "FinanceControllerCell"
fileprivate let headerContainerCell = "HeaderCellDelegate"


enum Mode {
    case small, fullscreen
}

protocol ManageAppearanceHome: class {
    func manageAppearanceHome(_ homeController: MasterActivityContainerController, didFinishLoadingWith state: Bool )
}

class MasterActivityContainerController: UIViewController {
    var networkController = NetworkController() {
        didSet {
            scrollToFirstActivityWithDate({ (activities) in
                self.sortedActivities = activities
                self.collectionView.reloadData()
            })
        }
    }


    let collectionView:UICollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout.init())
    let layout:UICollectionViewFlowLayout = UICollectionViewFlowLayout.init()
        
    let navigationItemActivityIndicator = NavigationItemActivityIndicator()
        
    weak var delegate: ManageAppearanceHome?
        
    var viewControllers = [UIViewController]()
    
    lazy var activitiesVC: ActivityViewController = {
        let vc = ActivityViewController(networkController: networkController)
        return vc
    }()
    
    lazy var financeVC: FinanceViewController = {
        let vc = FinanceViewController(networkController: networkController)
        return vc
    }()
    
    lazy var healthVC: HealthViewController = {
        let vc = HealthViewController(networkController: networkController)
        return vc
    }()
    
    var sections: [SectionType] = [.calendar, .health, .finances]
    
    var sortedActivities = [Activity]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setNavBar()
        addObservers()
        delegate?.manageAppearanceHome(self, didFinishLoadingWith: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        managePresense()
    }

    func setupViews() {
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for:.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layoutIfNeeded()
        navigationController?.navigationBar.barStyle = ThemeManager.currentTheme().barStyle
        navigationController?.navigationBar.barTintColor = ThemeManager.currentTheme().barBackgroundColor
        let textAttributes = [NSAttributedString.Key.foregroundColor: ThemeManager.currentTheme().generalTitleColor]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationController?.navigationBar.largeTitleTextAttributes = textAttributes
        navigationController?.navigationBar.backgroundColor = ThemeManager.currentTheme().barBackgroundColor
        
        tabBarController?.tabBar.barTintColor = ThemeManager.currentTheme().barBackgroundColor
        tabBarController?.tabBar.barStyle = ThemeManager.currentTheme().barStyle
        
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        collectionView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        collectionView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        layout.scrollDirection = UICollectionView.ScrollDirection.vertical
        collectionView.setCollectionViewLayout(layout, animated: true)
        collectionView.dataSource = self
        collectionView.delegate = self
        
        view.addSubview(collectionView)
        collectionView.fillSuperview()
        
        collectionView.register(ActivitiesControllerCell.self, forCellWithReuseIdentifier: activitiesControllerCell)
        collectionView.register(HealthControllerCell.self, forCellWithReuseIdentifier: healthControllerCell)
        collectionView.register(FinanceControllerCell.self, forCellWithReuseIdentifier: financeControllerCell)
        collectionView.register(HeaderContainerCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerContainerCell)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
    }
    
    @objc fileprivate func changeTheme() {
        let theme = ThemeManager.currentTheme()
        view.backgroundColor = theme.generalBackgroundColor
        
        navigationController?.navigationBar.barStyle = theme.barStyle
        navigationController?.navigationBar.barTintColor = theme.barBackgroundColor
        let textAttributes = [NSAttributedString.Key.foregroundColor: theme.generalTitleColor]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationController?.navigationBar.largeTitleTextAttributes = textAttributes
        navigationController?.navigationBar.backgroundColor = theme.barBackgroundColor
        
        tabBarController?.tabBar.barTintColor = theme.barBackgroundColor
        tabBarController?.tabBar.barStyle = theme.barStyle
        
        collectionView.indicatorStyle = theme.scrollBarStyle
        collectionView.backgroundColor = theme.generalBackgroundColor
        collectionView.reloadData()
        
    }
    
    func setNavBar() {
        let newItemBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newItem))
        navigationItem.leftBarButtonItems = nil
        navigationItem.rightBarButtonItem = newItemBarButton
        
    }
    
    func configureTabBarBadge() {
//        guard let tabItems = tabBarController?.tabBar.items as NSArray? else { return }
//        guard let tabItem = tabItems[Tabs.home.rawValue] as? UITabBarItem else { return }
//        guard !listList.isEmpty, !activities.isEmpty, !conversations.isEmpty, let uid = Auth.auth().currentUser?.uid else { return }
//        var badge = 0
//        
//        for activity in activities {
//            guard let activityBadge = activity.badge else { continue }
//            badge += activityBadge
//        }
//        
//        for conversation in conversations {
//            guard let lastMessage = conversation.lastMessage, let conversationBadge = conversation.badge, lastMessage.fromId != uid  else { continue }
//            badge += conversationBadge
//        }
//        
//        for list in listList {
//            badge += list.badge
//        }
//        
//        guard badge > 0 else {
//            tabItem.badgeValue = nil
//            setApplicationBadge()
//            return
//        }
//        tabItem.badgeValue = badge.toString()
//        setApplicationBadge()
    }
    
    func setApplicationBadge() {
        guard let tabItems = tabBarController?.tabBar.items as NSArray? else { return }
        var badge = 0
        
        for tab in 0...tabItems.count - 1 {
            guard let tabItem = tabItems[tab] as? UITabBarItem else { return }
            if let tabBadge = tabItem.badgeValue?.toInt() {
                badge += tabBadge
            }
        }
        UIApplication.shared.applicationIconBadgeNumber = badge
        if let uid = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference().child("users").child(uid)
            ref.updateChildValues(["badge": badge])
        }
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
    
    func scrollToFirstActivityWithDate(_ completion: @escaping ([Activity]) -> Void) {
        let allActivities = networkController.activityService.activities
        var activities = [Activity]()
        let currentDate = Date()
        var index = 0
        var activityFound = false
        for activity in allActivities {
            if let startInterval = activity.startDateTime?.doubleValue, let endInterval = activity.endDateTime?.doubleValue {
                let startDate = Date(timeIntervalSince1970: startInterval)
                let endDate = Date(timeIntervalSince1970: endInterval)
                if currentDate < startDate || currentDate < endDate {
                    activityFound = true
                    break
                }
                index += 1
                
            }
        }
                        
        if activityFound {
            let numberOfActivities = networkController.activityService.activities.count
            if index < numberOfActivities {
                print("scrollToFirstActivityWithDate \(index)")
                activities.append(allActivities[index])
                for i in 0...1 {
                    activities.append(allActivities[index + i + 1])
                }
                
                completion(activities)
            }
        } else {
            let numberOfRows = networkController.activityService.activities.count
            if numberOfRows > 2 {
                activities.append(allActivities[numberOfRows - 3])
                activities.append(allActivities[numberOfRows - 2])
                activities.append(allActivities[numberOfRows - 1])
                completion(activities)
            } else {
                completion(allActivities)
            }
        }
    }
    
    func goToVC(section: SectionType) {
        if section == .calendar {
            let backEnabledNavigationController = BackEnabledNavigationController(rootViewController: activitiesVC)
            backEnabledNavigationController.modalPresentationStyle = .fullScreen
            present(backEnabledNavigationController, animated: true)
        } else if section == .health {
            let backEnabledNavigationController = BackEnabledNavigationController(rootViewController: healthVC)
            backEnabledNavigationController.modalPresentationStyle = .fullScreen
            present(backEnabledNavigationController, animated: true)
        } else {
            let backEnabledNavigationController = BackEnabledNavigationController(rootViewController: financeVC)
            backEnabledNavigationController.modalPresentationStyle = .fullScreen
            present(backEnabledNavigationController, animated: true)
        }
    }
}

extension MasterActivityContainerController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = sections[indexPath.section]
        if section == .calendar {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: activitiesControllerCell, for: indexPath) as! ActivitiesControllerCell
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.activities = sortedActivities
            cell.invitations = networkController.activityService.invitations
            cell.delegate = self
            return cell
        } else if section == .health {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: healthControllerCell, for: indexPath) as! HealthControllerCell
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.healthMetricSections = networkController.healthService.healthMetricSections
            cell.healthMetrics = networkController.healthService.healthMetrics
            cell.delegate = self
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: financeControllerCell, for: indexPath) as! FinanceControllerCell
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.members = networkController.financeService.members
            cell.institutionDict = networkController.financeService.institutionDict
            cell.accounts = networkController.financeService.accounts
            cell.transactions = networkController.financeService.transactions
            cell.delegate = self
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 500
        let section = sections[indexPath.section]
        if section == .calendar {
            let dummyCell = collectionView.dequeueReusableCell(withReuseIdentifier: activitiesControllerCell, for: indexPath) as! ActivitiesControllerCell
            dummyCell.activities = sortedActivities
            dummyCell.invitations = networkController.activityService.invitations
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: view.frame.width, height: 500))
            height = estimatedSize.height
        } else if section == .health {
            let dummyCell = collectionView.dequeueReusableCell(withReuseIdentifier: healthControllerCell, for: indexPath) as! HealthControllerCell
            dummyCell.healthMetricSections = networkController.healthService.healthMetricSections
            dummyCell.healthMetrics = networkController.healthService.healthMetrics
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: view.frame.width, height: 500))
            height = estimatedSize.height
        } else {
            let dummyCell = collectionView.dequeueReusableCell(withReuseIdentifier: financeControllerCell, for: indexPath) as! FinanceControllerCell
            dummyCell.members = networkController.financeService.members
            dummyCell.institutionDict = networkController.financeService.institutionDict
            dummyCell.accounts = networkController.financeService.accounts
            dummyCell.transactions = networkController.financeService.transactions
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: view.frame.width, height: 500))
            height = estimatedSize.height
        }
        return CGSize(width: self.collectionView.frame.size.width - 40, height: height)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 15, left: 0, bottom: 15, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 30)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerContainerCell, for: indexPath) as! HeaderContainerCell
            let section = sections[indexPath.section]
            sectionHeader.titleLabel.text = section.name
            sectionHeader.sectionType = section
            sectionHeader.delegate = self
            return sectionHeader
        } else { //No footer in this case but can add option for that
            return UICollectionReusableView()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        goToVC(section: section)
    }
}

extension MasterActivityContainerController {
    @objc fileprivate func newItem() {
        tabBarController?.selectedIndex = 0
    }
}

extension MasterActivityContainerController: HeaderContainerCellDelegate {
    func viewTapped(sectionType: SectionType) {
        goToVC(section: sectionType)
    }
}

extension MasterActivityContainerController: ActivitiesControllerCellDelegate {
    func cellTapped(activity: Activity) {
        activitiesVC.loadActivity(activity: activity)
    }
    
    func openMap(forActivity activity: Activity) {
        activitiesVC.openMap(forActivity: activity)
    }
    
    func openChat(forConversation conversationID: String?, activityID: String?) {
        activitiesVC.openChat(forConversation: conversationID, activityID: activityID)
    }
    
    
}

extension MasterActivityContainerController: HealthControllerCellDelegate {
    func cellTapped(metric: HealthMetric) {
        healthVC.openMetric(metric: metric)
    }
}

extension MasterActivityContainerController: FinanceControllerCellDelegate {
    func openTransactionDetails(transactionDetails: TransactionDetails) {
        financeVC.openTransactionDetails(transactionDetails: transactionDetails)
    }
    
    func openAccountDetails(accountDetails: AccountDetails) {
        financeVC.openAccountDetails(accountDetails: accountDetails)
    }
    
    func openMember(member: MXMember) {
        financeVC.openMXConnect(guid: networkController.financeService.mxUser.guid, current_member_guid: member.guid)
    }
    
    
}
