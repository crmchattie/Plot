//
//  SubLibraryViewController.swift
//  Plot
//
//  Created by Cory McHattie on 9/27/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase
import GoogleSignIn

class SubLibraryViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, ObjectDetailShowing {
    var participants = [String : [User]]()
        
    private let kCompositionalHeader = "CompositionalHeader"
    private let kSubLibraryCell = "SubLibraryCell"
    
    var favAct = [String: [String]]()
    
    var sections: [SectionType] = []
    var groups = [SectionType: [AnyHashable]]()
    var templates = [Template]()
    var filteredTemplates = [Template]()
    var intColor: Int = 0
    
    var umbrellaActivity: Activity!
    
    var activityType: String!
    
    var networkController = NetworkController()
    
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
    
    weak var updateDiscoverDelegate : UpdateDiscover?
    
    init() {
        
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
        
        super.init(collectionViewLayout: layout)
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.layoutIfNeeded()
        navigationItem.largeTitleDisplayMode = .always
                
        tabBarController?.tabBar.barTintColor = .systemGroupedBackground
        tabBarController?.tabBar.barStyle = .default
        
        extendedLayoutIncludesOpaqueBars = true
        definesPresentationContext = false
        edgesForExtendedLayout = UIRectEdge.top
        view.backgroundColor = .systemGroupedBackground
        
        collectionView.indicatorStyle = .default
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.register(SubLibraryCell.self, forCellWithReuseIdentifier: kSubLibraryCell)
                        
        filteredTemplates = templates.sorted(by: { $0.name < $1.name })
        setupData()
        setupSearchController()
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchFavAct()
    }
    
    @IBAction func done(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    lazy var diffableDataSource: UICollectionViewDiffableDataSource<SectionType, AnyHashable> = .init(collectionView: self.collectionView) { (collectionView, indexPath, object) -> UICollectionViewCell? in
        let snapshot = self.diffableDataSource.snapshot()
        if let object = object as? Template, let section = snapshot.sectionIdentifier(containingItem: object) {
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
        if let template = object as? Template {
            switch template.object {
            case .event:
                showEventDetailPresent(event: nil, updateDiscoverDelegate: self, delegate: nil, task: nil, transaction: nil, workout: nil, mindfulness: nil, template: template, users: nil, container: nil, startDateTime: nil, endDateTime: nil)
            case .task:
                showTaskDetailPresent(task: nil, updateDiscoverDelegate: self, delegate: nil, event: nil, transaction: nil, workout: nil, mindfulness: nil, template: template, users: nil, container: nil, list: nil)
            case .workout:
                showWorkoutDetailPresent(workout: nil, updateDiscoverDelegate: self, delegate: nil, template: template, users: nil, container: nil, movingBackwards: nil)
            case .mindfulness:
                showMindfulnessDetailPresent(mindfulness: nil, updateDiscoverDelegate: self, delegate: nil, template: template, users: nil, container: nil, movingBackwards: nil)
            case .subtask:
                print("subtask")
            case .schedule:
                print("schedule")
            }
        }
    }
    
    private func setupData() {
        var snapshot = self.diffableDataSource.snapshot()
        snapshot.deleteAllItems()
        self.diffableDataSource.apply(snapshot)
                                
        for section in sections {
            if let object = groups[section] {
                snapshot.appendSections([section])
                snapshot.appendItems(object, toSection: section)
                self.diffableDataSource.apply(snapshot)
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

extension SubLibraryViewController: CompositionalHeaderDelegate {
    func viewTapped(labelText: String) {
        
    }
}

extension SubLibraryViewController: EndedWebViewDelegate {
    func updateMXMembers() {
        networkController.financeService.regrabFinances {}
    }
}

extension SubLibraryViewController: GIDSignInDelegate {
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

extension SubLibraryViewController: UpdateDiscover {
    func itemCreated(title: String) {
        self.navigationItem.searchController?.isActive = false
        self.dismiss(animated: true)
        self.updateDiscoverDelegate?.itemCreated(title: title)
    }
}

extension SubLibraryViewController: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {}
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.resignFirstResponder()
        timer?.invalidate()
        filteredTemplates = templates
        groups[.templates] = filteredTemplates
        self.viewPlaceholder.remove(from: self.collectionView, priority: .medium)
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
        groups[.templates] = filteredTemplates
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { (_) in
            if self.filteredTemplates.count == 0 {
                self.viewPlaceholder.add(for: self.collectionView, title: .emptySearchTemplate, subtitle: .empty, priority: .medium, position: .fill)
            } else {
                self.viewPlaceholder.remove(from: self.collectionView, priority: .medium)
            }
            self.setupData()
        })
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.keyboardAppearance = .default
        return true
    }
    
}

extension SubLibraryViewController { /* hiding keyboard */
    
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
        groups[.templates] = filteredTemplates
        
        timer?.invalidate()
        if self.filteredTemplates.count == 0 {
            self.viewPlaceholder.add(for: self.collectionView, title: .emptySearchTemplate, subtitle: .empty, priority: .medium, position: .fill)
        } else {
            self.viewPlaceholder.remove(from: self.collectionView, priority: .medium)
        }
        
        setupData()
        
        if #available(iOS 11.0, *) {
            searchController?.searchBar.endEditing(true)
        } else {
            self.searchBar.endEditing(true)
        }
    }
}
