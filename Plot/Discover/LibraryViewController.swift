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
        
    private let kCompositionalHeader = "CompositionalHeader"
    private let kLibraryCell = "LibraryCell"
    
    var favAct = [String: [String]]()
    
    var sections: [SectionType] = [.custom, .templates]
    var groups = [SectionType: [AnyHashable]]()
    var customTypes: [CustomType] = [.event, .task, .calendar, .lists, .workout, .mindfulness, .transaction, .financialAccount, .transactionRule]
    var templateTypes: [CustomType] = [.healthTemplate, .mealTemplate, .workTemplate, .schoolTemplate, .socialTemplate, .leisureTemplate, .familyTemplate, .personalTemplate, .todoTemplate, .financesTemplate]
    var templates = [ActivityCategory: [Template]]()
    
    var intColor: Int = 0
    
    var umbrellaActivity: Activity!
    
    var activityType: String!
    
    var networkController = NetworkController()
    
    let navigationItemActivityIndicator = NavigationItemActivityIndicator()
    
    init() {
        
        let layout = UICollectionViewCompositionalLayout { (sectionNumber, _) -> NSCollectionLayoutSection? in
            
            if sectionNumber == 0 {
                return LibraryViewController.topSection()
            } else {
                // second section
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
                    .init(layoutSize: .init(widthDimension: .fractionalWidth(0.92), heightDimension: .absolute(30)), elementKind: kind, alignment: .topLeading)
                ]
                
                return section
            }
        }
        
        super.init(collectionViewLayout: layout)
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
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        navigationItem.rightBarButtonItem = doneBarButton
        
        groups[.custom] = customTypes
        groups[.templates] = templateTypes
        
        setupData()
        fetchTemplates()
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
        if let object = object as? CustomType {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kLibraryCell, for: indexPath) as! LibraryCell
            cell.intColor = (indexPath.item % 5)
            cell.customType = object
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
                self.navigationController?.pushViewController(destination, animated: true)
            case .task:
                let destination = TaskViewController(networkController: networkController)
                destination.updateDiscoverDelegate = self
                self.navigationController?.pushViewController(destination, animated: true)
            case .calendar:
                let destination = CalendarDetailViewController(networkController: self.networkController)
                destination.updateDiscoverDelegate = self
                self.navigationController?.pushViewController(destination, animated: true)
            case .lists:
                let destination = ListDetailViewController(networkController: self.networkController)
                destination.updateDiscoverDelegate = self
                self.navigationController?.pushViewController(destination, animated: true)
            case .meal:
                let destination = MealViewController(networkController: self.networkController)
                destination.updateDiscoverDelegate = self
                self.navigationController?.pushViewController(destination, animated: true)
            case .workout:
                let destination = WorkoutViewController(networkController: self.networkController)
                destination.updateDiscoverDelegate = self
                self.navigationController?.pushViewController(destination, animated: true)
            case .mindfulness:
                let destination = MindfulnessViewController(networkController: self.networkController)
                destination.updateDiscoverDelegate = self
                self.navigationController?.pushViewController(destination, animated: true)
            case .mood:
                let destination = MoodViewController()
                self.navigationController?.pushViewController(destination, animated: true)
            case .sleep:
                let destination = SchedulerViewController()
                destination.type = customType
                self.navigationController?.pushViewController(destination, animated: true)
            case .work:
                let destination = SchedulerViewController()
                destination.type = customType
                self.navigationController?.pushViewController(destination, animated: true)
            case .transaction:
                let destination = FinanceTransactionViewController(networkController: self.networkController)
                destination.updateDiscoverDelegate = self
                self.navigationController?.pushViewController(destination, animated: true)
            case .investment:
                let destination = FinanceHoldingViewController(networkController: self.networkController)
                destination.updateDiscoverDelegate = self
                self.navigationController?.pushViewController(destination, animated: true)
            case .financialAccount:
                self.newAccount()
            case .transactionRule:
                let destination = FinanceTransactionRuleViewController(networkController: self.networkController)
                destination.updateDiscoverDelegate = self
                self.navigationController?.pushViewController(destination, animated: true)
            case .healthTemplate:
                let destination = SubLibraryViewController()
                destination.networkController = networkController
                destination.sections = [.templates]
                destination.title = ActivityCategory.health.rawValue
                if let templates = templates[.health] {
                    destination.groups = [.templates: templates]
                }
                self.navigationController?.pushViewController(destination, animated: true)
            case .mealTemplate:
                let destination = SubLibraryViewController()
                destination.networkController = networkController
                destination.title = ActivityCategory.meal.rawValue
                destination.sections = [.templates]
                if let templates = templates[.meal] {
                    destination.groups = [.templates: templates]
                }
                self.navigationController?.pushViewController(destination, animated: true)
            case .workTemplate:
                let destination = SubLibraryViewController()
                destination.networkController = networkController
                destination.title = ActivityCategory.work.rawValue
                destination.sections = [.templates]
                if let templates = templates[.work] {
                    destination.groups = [.templates: templates]
                }
                self.navigationController?.pushViewController(destination, animated: true)
            case .schoolTemplate:
                let destination = SubLibraryViewController()
                destination.networkController = networkController
                destination.title = ActivityCategory.school.rawValue
                destination.sections = [.templates]
                if let templates = templates[.school] {
                    destination.groups = [.templates: templates]
                }
                self.navigationController?.pushViewController(destination, animated: true)
            case .socialTemplate:
                let destination = SubLibraryViewController()
                destination.networkController = networkController
                destination.title = ActivityCategory.social.rawValue
                destination.sections = [.templates]
                if let templates = templates[.social] {
                    destination.groups = [.templates: templates]
                }
                self.navigationController?.pushViewController(destination, animated: true)
            case .leisureTemplate:
                let destination = SubLibraryViewController()
                destination.networkController = networkController
                destination.title = ActivityCategory.leisure.rawValue
                destination.sections = [.templates]
                if let templates = templates[.leisure] {
                    destination.groups = [.templates: templates]
                }
                self.navigationController?.pushViewController(destination, animated: true)
            case .familyTemplate:
                let destination = SubLibraryViewController()
                destination.networkController = networkController
                destination.title = ActivityCategory.family.rawValue
                destination.sections = [.templates]
                if let templates = templates[.family] {
                    destination.groups = [.templates: templates]
                }
                self.navigationController?.pushViewController(destination, animated: true)
            case .personalTemplate:
                let destination = SubLibraryViewController()
                destination.networkController = networkController
                destination.title = ActivityCategory.personal.rawValue
                destination.sections = [.templates]
                if let templates = templates[.personal] {
                    destination.groups = [.templates: templates]
                }
                self.navigationController?.pushViewController(destination, animated: true)
            case .todoTemplate:
                let destination = SubLibraryViewController()
                destination.networkController = networkController
                destination.title = ActivityCategory.todo.rawValue
                destination.sections = [.templates]
                if let templates = templates[.todo] {
                    destination.groups = [.templates: templates]
                }
                self.navigationController?.pushViewController(destination, animated: true)
            case .financesTemplate:
                let destination = SubLibraryViewController()
                destination.networkController = networkController
                destination.title = ActivityCategory.finances.rawValue
                destination.sections = [.templates]
                if let templates = templates[.finances] {
                    destination.groups = [.templates: templates]
                }
                self.navigationController?.pushViewController(destination, animated: true)
            default:
                print("default")
            }
        } else {
            print("library else")
        }
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
    
    func fetchTemplates() {
        let reference = Database.database().reference().child(templateEntity)
        reference.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists(), let snapshotValue = snapshot.value as? NSArray {
                for value in snapshotValue {
                    if let template = try? FirebaseDecoder().decode(Template.self, from: value) {
                        self.templates[template.category, default: []].append(template)
                    }
                }
            }
        })
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

extension LibraryViewController: CompositionalHeaderDelegate {
    func viewTapped(labelText: String) {
        
    }
}

extension LibraryViewController: EndedWebViewDelegate {
    func updateMXMembers() {
        networkController.financeService.triggerUpdateMXUser {}
    }
}

extension LibraryViewController: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if (error == nil) {
            self.networkController.activityService.updatePrimaryCalendar(value: CalendarSourceOptions.google.name)
            self.networkController.activityService.updatePrimaryList(value: ListSourceOptions.google.name)
        } else {
          print("\(error.localizedDescription)")
        }
    }
}

extension LibraryViewController: UpdateDiscover {
    func itemCreated() {
        self.dismiss(animated: true)
    }
}
