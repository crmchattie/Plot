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

protocol UpdateDiscover: AnyObject {
    func itemCreated()
}

class LibraryViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    let networkController: NetworkController
    
    private let kCompositionalHeader = "CompositionalHeader"
    private let kLibraryCell = "LibraryCell"
    private let kSubLibraryCell = "SubLibraryCell"
    
    var favAct = [String: [String]]()
    
    var sections: [SectionType] = [.custom, .templates, .allTemplates]
    var groups = [SectionType: [AnyHashable]]()
    var customTypes: [CustomType] = [.event, .task, .workout, .mindfulness, .transaction, .financialAccount, .transactionRule]
    var templateTypes: [CustomType] = [.healthTemplate, .mealTemplate, .workTemplate, .schoolTemplate, .socialTemplate, .leisureTemplate, .familyTemplate, .personalTemplate, .todoTemplate, .financesTemplate]
    var templatesDict = [ActivityCategory: [Template]]()
    var templates = [Template]()
    var filteredTemplates = [Template]()
    
    var intColor: Int = 0
    
    var umbrellaActivity: Activity!
    
    var activityType: String!
        
    let navigationItemActivityIndicator = NavigationItemActivityIndicator()
    
    let viewPlaceholder = ViewPlaceholder()
    
    var timer: Timer?
    
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
            
            if sectionNumber == 0 {
                return LibraryViewController.topSection()
            } else if sectionNumber == 1 {
                return LibraryViewController.secondSection()
            } else {
                // second section
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
    
    func updateLayoutToInitial() {
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
        let layout = UICollectionViewCompositionalLayout { (sectionNumber, _) -> NSCollectionLayoutSection? in
            
            if sectionNumber == 0 {
                return LibraryViewController.topSection()
            } else if sectionNumber == 1 {
                return LibraryViewController.secondSection()
            } else {
                // second section
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
        navigationItem.title = "Discover"
        navigationController?.navigationBar.layoutIfNeeded()        
        navigationItem.largeTitleDisplayMode = .always
                
        tabBarController?.tabBar.barTintColor = .systemGroupedBackground
        tabBarController?.tabBar.barStyle = .default
        
        extendedLayoutIncludesOpaqueBars = true
        definesPresentationContext = true
        edgesForExtendedLayout = UIRectEdge.top
        view.backgroundColor = .systemGroupedBackground
        
        collectionView.indicatorStyle = .default
        collectionView.backgroundColor = .systemGroupedBackground
        
        collectionView.register(CompositionalHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: kCompositionalHeader)
        collectionView.register(LibraryCell.self, forCellWithReuseIdentifier: kLibraryCell)
        collectionView.register(SubLibraryCell.self, forCellWithReuseIdentifier: kSubLibraryCell)
                
        groups[.custom] = customTypes
        
        fetchTemplates()
        setupSearchController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchFavAct()
    }
    
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
                    if let template = try? FirebaseDecoder().decode(Template.self, from: value) {
                        self.templatesDict[template.category, default: []].append(template)
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
        guard currentReachabilityStatus != .notReachable else {
            return
        }
        
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
                                
        for section in sections {
            if let object = groups[section] {
                snapshot.appendSections([section])
                snapshot.appendItems(object, toSection: section)
                self.diffableDataSource.apply(snapshot)
            }
        }
    }
    
    lazy var diffableDataSource: UICollectionViewDiffableDataSource<SectionType, AnyHashable> = .init(collectionView: self.collectionView) { (collectionView, indexPath, object) -> UICollectionViewCell? in
        let snapshot = self.diffableDataSource.snapshot()
        if let object = object as? CustomType {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kLibraryCell, for: indexPath) as! LibraryCell
            cell.intColor = (indexPath.item % 5)
            cell.customType = object
            return cell
        } else if let object = object as? Template, let section = snapshot.sectionIdentifier(containingItem: object) {
            let totalItems = (self.groups[section]?.count ?? 1) - 1
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kSubLibraryCell, for: indexPath) as! SubLibraryCell
            cell.intColor = (indexPath.item % 5)
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
                let destination = EventViewController(networkController: networkController)
                destination.updateDiscoverDelegate = self
                destination.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(destination, animated: true)
            case .task:
                let destination = TaskViewController(networkController: networkController)
                destination.updateDiscoverDelegate = self
                destination.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(destination, animated: true)
            case .calendar:
                let destination = CalendarDetailViewController(networkController: self.networkController)
                destination.updateDiscoverDelegate = self
                destination.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(destination, animated: true)
            case .lists:
                let destination = ListDetailViewController(networkController: self.networkController)
                destination.updateDiscoverDelegate = self
                destination.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(destination, animated: true)
            case .meal:
                let destination = MealViewController(networkController: self.networkController)
                destination.updateDiscoverDelegate = self
                destination.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(destination, animated: true)
            case .workout:
                let destination = WorkoutViewController(networkController: self.networkController)
                destination.updateDiscoverDelegate = self
                destination.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(destination, animated: true)
            case .mindfulness:
                let destination = MindfulnessViewController(networkController: self.networkController)
                destination.updateDiscoverDelegate = self
                destination.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(destination, animated: true)
            case .mood:
                let destination = MoodViewController()
                destination.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(destination, animated: true)
            case .sleep:
                let destination = SchedulerViewController()
                destination.type = customType
                destination.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(destination, animated: true)
            case .work:
                let destination = SchedulerViewController()
                destination.type = customType
                destination.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(destination, animated: true)
            case .transaction:
                let destination = FinanceTransactionViewController(networkController: self.networkController)
                destination.updateDiscoverDelegate = self
                destination.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(destination, animated: true)
            case .investment:
                let destination = FinanceHoldingViewController(networkController: self.networkController)
                destination.updateDiscoverDelegate = self
                destination.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(destination, animated: true)
            case .financialAccount:
                self.newAccount()
            case .transactionRule:
                let destination = FinanceTransactionRuleViewController(networkController: self.networkController)
                destination.updateDiscoverDelegate = self
                destination.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(destination, animated: true)
            default:
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
        } else if let template = object as? Template {
            switch template.object {
            case .event:
                let destination = EventViewController(networkController: networkController)
                destination.updateDiscoverDelegate = self
                destination.template = template
                destination.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(destination, animated: true)
            case .task:
                let destination = TaskViewController(networkController: networkController)
                destination.updateDiscoverDelegate = self
                destination.template = template
                destination.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(destination, animated: true)
            case .workout:
                let destination = WorkoutViewController(networkController: self.networkController)
                destination.updateDiscoverDelegate = self
                destination.template = template
                destination.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(destination, animated: true)
            case .mindfulness:
                let destination = MindfulnessViewController(networkController: self.networkController)
                destination.updateDiscoverDelegate = self
                destination.template = template
                destination.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(destination, animated: true)
            case .subtask:
                print("subtask")
            case .schedule:
                print("schedule")
            }
        }
    }
    
    @objc func newAccount() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Connect To Account", style: .default, handler: { (_) in
            self.openMXConnect(current_member_guid: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Manually Add Account", style: .default, handler: { (_) in
            let destination = FinanceAccountViewController(networkController: self.networkController)
            destination.updateDiscoverDelegate = self
            destination.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(destination, animated: true)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
    
    func openMXConnect(current_member_guid: String?) {
        let destination = WebViewController()
        destination.current_member_guid = current_member_guid
        destination.controllerTitle = ""
        destination.delegate = self
        let navigationViewController = UINavigationController(rootViewController: destination)
        navigationViewController.modalPresentationStyle = .fullScreen
        self.present(navigationViewController, animated: true, completion: nil)
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

extension LibraryViewController: UpdateDiscover {
    func itemCreated() {
        self.navigationItem.searchController?.isActive = false
        self.dismiss(animated: true)
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
