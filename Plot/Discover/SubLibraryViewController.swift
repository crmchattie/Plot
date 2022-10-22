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

class SubLibraryViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
        
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
        
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        navigationItem.rightBarButtonItem = doneBarButton
        
        filteredTemplates = templates
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
                print(totalItems)
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
                let destination = EventViewController(networkController: networkController)
                destination.updateDiscoverDelegate = self
                destination.template = template
                self.navigationController?.pushViewController(destination, animated: true)
            case .task:
                let destination = TaskViewController(networkController: networkController)
                destination.updateDiscoverDelegate = self
                destination.template = template
                self.navigationController?.pushViewController(destination, animated: true)
            case .workout:
                let destination = WorkoutViewController(networkController: self.networkController)
                destination.updateDiscoverDelegate = self
                destination.template = template
                self.navigationController?.pushViewController(destination, animated: true)
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
            filteredTemplates = filteredTemplates.sorted(by: { $0.name < $1.name })
            snapshot.appendSections([section])
            snapshot.appendItems(filteredTemplates, toSection: section)
            self.diffableDataSource.apply(snapshot)
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
    func itemCreated() {
        self.dismiss(animated: true)
        self.updateDiscoverDelegate?.itemCreated()
    }
}

extension SubLibraryViewController: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {}
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.resignFirstResponder()
        timer?.invalidate()
        filteredTemplates = templates
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
