//
//  LibraryViewController.swift
//  Plot
//
//  Created by Cory McHattie on 9/27/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase
import GoogleSignIn

let discoverTitleString = "Discover"
let addTitleString = "Add"

protocol UpdateDiscover: AnyObject {
    func itemCreated(title: String)
}

class LibraryViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, ObjectDetailShowing {
    let networkController: NetworkController
    
    private let kCompositionalHeader = "CompositionalHeader"
    private let kLibraryCell = "LibraryCell"
    private let kSubLibraryCell = "SubLibraryCell"
    
    var favAct = [String: [String]]()
    
    var participants = [String : [User]]()
    var titleString = addTitleString
    var sections: [SectionType] = [.time, .health, .finances]
    var groups = [SectionType: [AnyHashable]]()
    
    var customCustomTypes: [CustomType] = [.goal, .task, .event, .mood, .workout, .mindfulness, .transaction, .financialAccount, .transactionRule]
    var promptCustomTypes: [CustomType] = [.timeInsights, .healthInsights, .financialInsights]
    
    var timeCustomTypesAdd: [CustomType] = [.goal, .task, .event]
    var healthCustomTypesAdd: [CustomType] = [.workout, .mood, .mindfulness]
    var financeCustomTypesAdd: [CustomType] = [.transaction, .financialAccount, .transactionRule]
    
    var timeCustomTypesPrompt: [CustomType] = [.timeInsights, .timeRecs, .timePlan]
    var healthCustomTypesPrompt: [CustomType] = [.healthInsights, .healthRecs, .healthPlan]
    var financeCustomTypesPrompt: [CustomType] = [.financialInsights, .financialRecs, .financialPlan, .transactionsInsights, .budgetPlan]
    
    var timeCustomTypesAll: [CustomType] = [.goal, .task, .event, .timeInsights, .timeRecs, .timePlan]
    var healthCustomTypesAll: [CustomType] = [.mood, .workout, .mindfulness, .healthInsights, .healthRecs, .healthPlan]
    var financeCustomTypesAll: [CustomType] = [.transaction, .financialAccount, .transactionRule, .financialInsights, .financialRecs, .financialPlan, .transactionsInsights, .budgetPlan]
    
    var templateTypes: [CustomType] = [.healthTemplate, .mealTemplate, .workTemplate, .schoolTemplate, .socialTemplate, .leisureTemplate, .familyTemplate, .personalTemplate, .todoTemplate, .financesTemplate]
    var templatesDict = [ActivityCategory: [Template]]()
    var templates = [Template]()
    var filteredTemplates = [Template]()
    
    
    var intColor: Int = 0
    
    var umbrellaActivity: Activity!
            
    let navigationItemActivityIndicator = NavigationItemActivityIndicator()
    
    let viewPlaceholder = ViewPlaceholder()
    
    var timer: Timer?
    
    weak var updateDiscoverDelegate : UpdateDiscover?
    
    lazy var searchBar : UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Search"
        searchBar.barStyle = .default
        searchBar.sizeToFit()
        return searchBar
    }()
    var searchController: UISearchController?
    
    init(networkController: NetworkController) {
        self.networkController = networkController
        
        let layout = UICollectionViewCompositionalLayout { (sectionNumber, _) -> NSCollectionLayoutSection? in
//            if sectionNumber == 0 {
//                return LibraryViewController.topSection()
//            } else if sectionNumber == 1 {
//                return LibraryViewController.secondSection()
//            } else {
//                // second section
            return LibraryViewController.standardSection()
//            }
        }
        
        super.init(collectionViewLayout: layout)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func topSection() -> NSCollectionLayoutSection {
        
        let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
        item.contentInsets.trailing = 8
        
        let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(0.45), heightDimension: .absolute(114)), subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPaging
        section.contentInsets.top = 16
        section.contentInsets.bottom = 16
        section.contentInsets.leading = 16
        section.contentInsets.trailing = 8
        
        let kind = UICollectionView.elementKindSectionHeader
        section.boundarySupplementaryItems = [
            .init(layoutSize: .init(widthDimension: .fractionalWidth(0.92), heightDimension: .absolute(25)), elementKind: kind, alignment: .topLeading)
        ]
        
        return section
    }
    
    static func secondSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalHeight(1)))
        item.contentInsets = .init(top: 8, leading: 0, bottom: 8, trailing: 8)
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(130)), subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .none
        section.contentInsets.top = 16
        section.contentInsets.leading = 16
        section.contentInsets.trailing = 8
        
        let kind = UICollectionView.elementKindSectionHeader
        section.boundarySupplementaryItems = [
            .init(layoutSize: .init(widthDimension: .fractionalWidth(0.92), heightDimension: .absolute(25)), elementKind: kind, alignment: .topLeading)
        ]
        
        return section
    }
    
    static func standardSection() -> NSCollectionLayoutSection {
        let heightDimension = NSCollectionLayoutDimension.estimated(500)

        let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: heightDimension))

        let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: heightDimension), subitems: [item])
        group.contentInsets.trailing = 16

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .none
        section.contentInsets.leading = 16

        let kind = UICollectionView.elementKindSectionHeader
        section.boundarySupplementaryItems = [
            .init(layoutSize: .init(widthDimension: .fractionalWidth(0.92), heightDimension: .absolute(70)), elementKind: kind, alignment: .topLeading)
        ]

        return section
    }
    
    func updateLayoutToInitial() {
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
        let layout = UICollectionViewCompositionalLayout { (sectionNumber, _) -> NSCollectionLayoutSection? in
//            if sectionNumber == 0 {
//                return LibraryViewController.topSection()
//            } else if sectionNumber == 1 {
//                return LibraryViewController.secondSection()
//            } else {
//                // second section
            return LibraryViewController.standardSection()
//            }
        }
        collectionView.setCollectionViewLayout(layout, animated: true)
    }
    
    func updateLayoutToSearch() {
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
        let layout = UICollectionViewCompositionalLayout { (sectionNumber, _) -> NSCollectionLayoutSection? in
            let heightDimension = NSCollectionLayoutDimension.estimated(500)
            
            let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: heightDimension))
            
            let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: heightDimension), subitems: [item])
            group.contentInsets.trailing = 16
            
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .none
            section.contentInsets.leading = 16
            
            return section
        }
        collectionView.setCollectionViewLayout(layout, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = titleString
        navigationController?.navigationBar.layoutIfNeeded()        
        navigationItem.largeTitleDisplayMode = .always
                
        extendedLayoutIncludesOpaqueBars = true
        definesPresentationContext = true
        edgesForExtendedLayout = UIRectEdge.top
        view.backgroundColor = .systemGroupedBackground
        
        if navigationItem.leftBarButtonItem != nil  {
            navigationItem.leftBarButtonItem?.action = #selector(cancel)
        }
        
        if navigationItem.rightBarButtonItem != nil  {
            navigationItem.rightBarButtonItem?.action = #selector(cancel)
        }
        
        collectionView.indicatorStyle = .default
        collectionView.backgroundColor = .systemGroupedBackground
        
        collectionView.register(CompositionalHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: kCompositionalHeader)
        collectionView.register(LibraryCell.self, forCellWithReuseIdentifier: kLibraryCell)
        collectionView.register(SubLibraryCell.self, forCellWithReuseIdentifier: kSubLibraryCell)
        
        setupData()

//        fetchTemplates()
//        setupSearchController()
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        fetchFavAct()
//    }
    
    fileprivate func setupSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController?.searchResultsUpdater = self
        searchController?.obscuresBackgroundDuringPresentation = false
        searchController?.searchBar.delegate = self
        searchController?.definesPresentationContext = true
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    @IBAction func done(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func fetchTemplates() {
        var refHandle = DatabaseHandle()
        let reference = Database.database().reference().child(templateEntity)
        reference.keepSynced(true)
        refHandle = reference.observe(.value, with: { (snapshot) in
            reference.removeObserver(withHandle: refHandle)
            if snapshot.exists(), let snapshotValue = snapshot.value as? NSArray {
                for value in snapshotValue {
                    if let template = try? FirebaseDecoder().decode(Template.self, from: value), let category = template.category {
                        self.templatesDict[category, default: []].append(template)
                        self.templates.append(template)
                    }
                }
            }
            if !self.templates.isEmpty {
                self.templates = self.templates.sorted(by: { $0.name < $1.name })
                self.filteredTemplates = self.templates
                self.groups[.templates] = self.templateTypes
                self.groups[.allTemplates] = self.filteredTemplates
            }
            self.setupData()
        })
    }
    
    private func setupData() {
        var snapshot = self.diffableDataSource.snapshot()
        snapshot.deleteAllItems()
        self.diffableDataSource.apply(snapshot)
                        
        diffableDataSource.supplementaryViewProvider = .some({ (collectionView, kind, indexPath) -> UICollectionReusableView? in
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.kCompositionalHeader, for: indexPath) as! CompositionalHeader
            header.delegate = self
            let snapshot = self.diffableDataSource.snapshot()
            if let object = self.diffableDataSource.itemIdentifier(for: indexPath), let section = snapshot.sectionIdentifier(containingItem: object) {
                header.titleLabel.text = section.name
                header.subTitleLabel.isHidden = true
            }
            
            return header
        })
        
        if titleString == discoverTitleString {
            for section in sections {
                if section == .summaryPrompt {
                    self.groups[section] = promptCustomTypes
                    snapshot.appendSections([section])
                    snapshot.appendItems(promptCustomTypes, toSection: section)
                    self.diffableDataSource.apply(snapshot)
                } else if section == .time {
                    self.groups[section] = timeCustomTypesPrompt
                    snapshot.appendSections([section])
                    snapshot.appendItems(timeCustomTypesPrompt, toSection: section)
                    self.diffableDataSource.apply(snapshot)
                } else if section == .health {
                    self.groups[section] = healthCustomTypesPrompt
                    snapshot.appendSections([section])
                    snapshot.appendItems(healthCustomTypesPrompt, toSection: section)
                    self.diffableDataSource.apply(snapshot)
                } else if section == .finances {
                    self.groups[section] = financeCustomTypesPrompt
                    snapshot.appendSections([section])
                    snapshot.appendItems(financeCustomTypesPrompt, toSection: section)
                    self.diffableDataSource.apply(snapshot)
                }
            }
        } else if titleString == addTitleString {
            for section in sections {
                if section == .custom {
                    self.groups[section] = customCustomTypes
                    snapshot.appendSections([section])
                    snapshot.appendItems(customCustomTypes, toSection: section)
                    self.diffableDataSource.apply(snapshot)
                } else if section == .time {
                    self.groups[section] = timeCustomTypesAdd
                    snapshot.appendSections([section])
                    snapshot.appendItems(timeCustomTypesAdd, toSection: section)
                    self.diffableDataSource.apply(snapshot)
                } else if section == .health {
                    self.groups[section] = healthCustomTypesAdd
                    snapshot.appendSections([section])
                    snapshot.appendItems(healthCustomTypesAdd, toSection: section)
                    self.diffableDataSource.apply(snapshot)
                } else if section == .finances {
                    self.groups[section] = financeCustomTypesAdd
                    snapshot.appendSections([section])
                    snapshot.appendItems(financeCustomTypesAdd, toSection: section)
                    self.diffableDataSource.apply(snapshot)
                }
            }
        }
    }
    
    lazy var diffableDataSource: UICollectionViewDiffableDataSource<SectionType, AnyHashable> = .init(collectionView: self.collectionView) { (collectionView, indexPath, object) -> UICollectionViewCell? in
        let snapshot = self.diffableDataSource.snapshot()
        if let object = object as? CustomType, let section = snapshot.sectionIdentifier(containingItem: object) {
            let totalItems = (self.groups[section]?.count ?? 1) - 1
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kSubLibraryCell, for: indexPath) as! SubLibraryCell
            if self.timeCustomTypesAll.contains(object) {
                cell.intColor = 5
            } else if self.healthCustomTypesAll.contains(object) {
                cell.intColor = 0
            } else if self.financeCustomTypesAll.contains(object) {
                cell.intColor = 3
            }
            if indexPath.item == 0 {
                cell.firstPosition = true
            }
            if indexPath.item == totalItems {
                cell.lastPosition = true
            }
            cell.customType = object
            return cell
        } else if let object = object as? Template, let section = snapshot.sectionIdentifier(containingItem: object) {
            let totalItems = (self.groups[section]?.count ?? 1) - 1
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kSubLibraryCell, for: indexPath) as! SubLibraryCell
            cell.intColor = (indexPath.item % 9)
            if indexPath.item == 0 {
                cell.firstPosition = true
            }
            if indexPath.item == totalItems {
                cell.lastPosition = true
            }
            cell.template = object
            return cell
        }
        return nil
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let object = diffableDataSource.itemIdentifier(for: indexPath)
        if let customType = object as? CustomType {
            switch customType {
            case .event:
                showEventDetailPresent(event: nil, updateDiscoverDelegate: self, delegate: nil, task: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, startDateTime: nil, endDateTime: nil)
            case .task:
                showTaskDetailPresent(task: nil, updateDiscoverDelegate: self, delegate: nil, event: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, list: nil, startDateTime: nil, endDateTime: nil)
            case .goal:
                showGoalDetailPresent(task: nil, updateDiscoverDelegate: self, delegate: nil, event: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, list: nil, startDateTime: nil, endDateTime: nil)
            case .calendar:
                showCalendarDetailPresent(calendar: nil, updateDiscoverDelegate: self)
            case .lists:
                showListDetailPresent(list: nil, updateDiscoverDelegate: self)
            case .meal:
                print("meal")
            case .workout:
                showWorkoutDetailPresent(workout: nil, updateDiscoverDelegate: self, delegate: nil, template: nil, users: nil, container: nil, movingBackwards: nil)
            case .mindfulness:
                showMindfulnessDetailPresent(mindfulness: nil, updateDiscoverDelegate: self, delegate: nil, template: nil, users: nil, container: nil, movingBackwards: nil)
            case .mood:
                showMoodDetailPresent(mood: nil, updateDiscoverDelegate: self, delegate: nil, template: nil, users: nil, container: nil, movingBackwards: nil)
            case .sleep:
                print("sleep")
            case .work:
                print("work")
            case .transaction:
                showTransactionDetailPresent(transaction: nil, updateDiscoverDelegate: self, delegate: nil, users: nil, container: nil, movingBackwards: nil)
            case .investment:
                showHoldingDetailPresent(holding: nil, updateDiscoverDelegate: self)
            case .financialAccount:
                self.newAccount()
            case .transactionRule:
                showTransactionRuleDetailPresent(transactionRule: nil, transaction: nil, updateDiscoverDelegate: self)
            default:
                if customType.categoryText == promptString {
                    openPrompt(prompt: customType.subcategoryText, promptDescription: customType.name)
                } else {
                    let destination = SubLibraryViewController()
                    destination.networkController = networkController
                    destination.sections = [.templates]
                    if let cat = ActivityCategory(rawValue: customType.name), let templates = templatesDict[cat] {
                        destination.title = cat.rawValue
                        destination.templates = templates
                        destination.groups = [.templates: templates]
                        destination.updateDiscoverDelegate = self
                        destination.hidesBottomBarWhenPushed = true
                        self.navigationController?.pushViewController(destination, animated: true)
                    }
                }
            }
        } else if let template = object as? Template {
            switch template.object {
            case .event:
                showEventDetailPresent(event: nil, updateDiscoverDelegate: self, delegate: nil, task: nil, transaction: nil, workout: nil, mindfulness: nil, template: template, users: nil, container: nil, startDateTime: nil, endDateTime: nil)
            case .task:
                showTaskDetailPresent(task: nil, updateDiscoverDelegate: self, delegate: nil, event: nil, transaction: nil, workout: nil, mindfulness: nil, template: template, users: nil, container: nil, list: nil, startDateTime: nil, endDateTime: nil)
            case .goal:
                showGoalDetailPresent(task: nil, updateDiscoverDelegate: self, delegate: nil, event: nil, transaction: nil, workout: nil, mindfulness: nil, template: template, users: nil, container: nil, list: nil, startDateTime: nil, endDateTime: nil)
            case .workout:
                showWorkoutDetailPresent(workout: nil, updateDiscoverDelegate: self, delegate: nil, template: template, users: nil, container: nil, movingBackwards: nil)
            case .mindfulness:
                showMindfulnessDetailPresent(mindfulness: nil, updateDiscoverDelegate: self, delegate: nil, template: template, users: nil, container: nil, movingBackwards: nil)
            case .subtask:
                print("subtask")
            case .schedule:
                print("schedule")
            case .mood:
                print("mood")
            case .transaction:
                print("transaction")
            case .account:
                print("account")
            }
        }
    }
    
    @objc func newAccount() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Connect To Account", style: .default, handler: { (_) in
            self.openMXConnect(current_member_guid: nil, delegate: self)
        }))
        
        alert.addAction(UIAlertAction(title: "Manually Add Account", style: .default, handler: { (_) in
            self.showAccountDetailPresent(account: nil, updateDiscoverDelegate: self)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
    
    func fetchFavAct() {
        
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
    
}

extension LibraryViewController: CompositionalHeaderDelegate {
    func viewTapped(labelText: String) {
        
    }
}

extension LibraryViewController: EndedWebViewDelegate {
    func updateMXMembers() {
        networkController.financeService.regrabFinances {}
    }
}

extension LibraryViewController: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if (error == nil) {
            let grantedScopes = user?.grantedScopes as? [String]
            if let grantedScopes = grantedScopes {
                if grantedScopes.contains(googleEmailScope) && grantedScopes.contains(googleTaskScope) {
                    self.networkController.activityService.updatePrimaryCalendar(value: CalendarSourceOptions.google.name)
                    self.networkController.activityService.updatePrimaryList(value: ListSourceOptions.google.name)
                } else if grantedScopes.contains(googleEmailScope) {
                    self.networkController.activityService.updatePrimaryCalendar(value: CalendarSourceOptions.google.name)
                } else if grantedScopes.contains(googleTaskScope) {
                    self.networkController.activityService.updatePrimaryList(value: ListSourceOptions.google.name)
                }
            }
        } else {
          print("\(error.localizedDescription)")
        }
    }
}

extension LibraryViewController: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {}
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.resignFirstResponder()
        timer?.invalidate()
        filteredTemplates = templates
        self.viewPlaceholder.remove(from: self.collectionView, priority: .medium)
        
        groups[.allTemplates] = filteredTemplates
        updateLayoutToInitial()
        sections = [.custom, .templates, .allTemplates]
        setupData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredTemplates = searchText.isEmpty ? templates :
            templates.filter({ (template) -> Bool in
                if template.name.lowercased().contains(searchText.lowercased()) || template.object.rawValue.lowercased().contains(searchText.lowercased()) {
                    return true
                }
                return false
        })
        
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { (_) in
            if self.filteredTemplates.count == 0 {
                self.viewPlaceholder.add(for: self.collectionView, title: .emptySearchTemplate, subtitle: .empty, priority: .medium, position: .fill)
            } else {
                self.viewPlaceholder.remove(from: self.collectionView, priority: .medium)
            }

            self.groups[.allTemplates] = self.filteredTemplates
            self.updateLayoutToSearch()
            self.sections = [.allTemplates]
            self.setupData()
        })
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.keyboardAppearance = .default
        return true
    }
    
}

extension LibraryViewController { /* hiding keyboard */
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if #available(iOS 11.0, *) {
            searchController?.searchBar.endEditing(true)
        } else {
            self.searchBar.endEditing(true)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        setNeedsStatusBarAppearanceUpdate()
        if let searchText = searchBar.searchTextField.text {
            filteredTemplates = searchText.isEmpty ? templates :
                templates.filter({ (template) -> Bool in
                    if template.name.lowercased().contains(searchText.lowercased()) || template.object.rawValue.lowercased().contains(searchText.lowercased()) {
                        return true
                    }
                    return false
            })
        } else {
            filteredTemplates = templates
        }
        timer?.invalidate()
        
        if self.filteredTemplates.count == 0 {
            self.viewPlaceholder.add(for: collectionView, title: .emptySearchTemplate, subtitle: .empty, priority: .medium, position: .fill)
        } else {
            self.viewPlaceholder.remove(from: collectionView, priority: .medium)
        }
        
        groups[.allTemplates] = filteredTemplates
        updateLayoutToSearch()
        sections = [.allTemplates]
        setupData()
        
        if #available(iOS 11.0, *) {
            searchController?.searchBar.endEditing(true)
        } else {
            self.searchBar.endEditing(true)
        }
    }
}

extension LibraryViewController: UpdateDiscover {
    func itemCreated(title: String) {
//        self.navigationItem.searchController?.isActive = false
//        self.dismiss(animated: true) {
//            self.dismiss(animated: true)
//            self.updateDiscoverDelegate?.itemCreated(title: title)
//        }
        
        self.navigationItem.searchController?.isActive = false
        self.dismiss(animated: true)
        self.tabBarController?.selectedIndex = 1
        basicAlert(title: title, message: nil, controller: self.tabBarController)
    }
}
