//
//  ActivitySubTypeViewController.swift
//  Plot
//
//  Created by Cory McHattie on 1/20/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase

class ActivitySubTypeViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    weak var delegate : UpdateActivityDelegate?
    
    let kCompositionalHeader = "CompositionalHeader"
    let kActivityTypeCell = "ActivityTypeCell"
    let kActivityHeaderCell = "ActivityHeaderCell"
    
    let searchController = UISearchController(searchResultsController: nil)
    
    var umbrellaActivity: Activity!
    var schedule: Bool = false
    
    var users = [User]()
    var filteredUsers = [User]()
    var selectedFalconUsers = [User]()
    var activities = [Activity]()
    var conversations = [Conversation]()
    var listList = [ListContainer]()
    var favAct = [String: [String]]()
    var conversation: Conversation?
    
    let viewPlaceholder = ViewPlaceholder()
        
    var timer: Timer?
    
    var showGroups = true
    
    var activity: Activity!
    var activeList: Bool = false
    var listType: String?
    
    var activityType: String!
    
    var startDateTime: Date?
    var endDateTime: Date?
    
    var lat: Double?
    var lon: Double?
        
    fileprivate var reference: DatabaseReference!
    
    var movingBackwards: Bool = true

    
    init() {
        let layout = ActivitySubTypeViewController.initialLayout()
        super.init(collectionViewLayout: layout)
    }
    
    static func initialLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionNumber, _) -> NSCollectionLayoutSection? in
            let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1/3)))
            item.contentInsets = .init(top: 0, leading: 0, bottom: 8, trailing: 16)
            
            let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(0.92), heightDimension: .absolute(360)), subitems: [item])
             
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .groupPaging
            section.contentInsets.leading = 16
            section.contentInsets.trailing = 16
            
            let kind = UICollectionView.elementKindSectionHeader
            section.boundarySupplementaryItems = [
                .init(layoutSize: .init(widthDimension: .fractionalWidth(0.92), heightDimension: .absolute(30)), elementKind: kind, alignment: .topLeading)
            ]
            return section
        }
        return layout
    }
    
    static func searchLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionNumber, _) -> NSCollectionLayoutSection? in
            let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
            item.contentInsets = .init(top: 0, leading: 16, bottom: 16, trailing: 16)
            
            let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(120)), subitems: [item])
             
            let section = NSCollectionLayoutSection(group: group)
            
            return section
        }
        return layout
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
                        
        navigationItem.largeTitleDisplayMode = .never
        
        
        view.addSubview(activityIndicatorView)
        activityIndicatorView.centerInSuperview()
        
        extendedLayoutIncludesOpaqueBars = true
        definesPresentationContext = true
        edgesForExtendedLayout = UIRectEdge.top
        view.backgroundColor = .systemGroupedBackground
        collectionView.indicatorStyle = .default
        collectionView.backgroundColor = .systemGroupedBackground
        
        collectionView.register(CompositionalHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: kCompositionalHeader)
        collectionView.register(ActivityHeaderCell.self, forCellWithReuseIdentifier: kActivityHeaderCell)
        collectionView.register(ActivityTypeCell.self, forCellWithReuseIdentifier: kActivityTypeCell)
                
        setupSearchBar()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("view appearing")
        fetchFavAct()
    }
    
    
    fileprivate func setupSearchBar() {
        definesPresentationContext = true
        navigationItem.searchController = self.searchController
        navigationItem.searchController?.obscuresBackgroundDuringPresentation = false
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    func fetchFavAct() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        self.reference = Database.database().reference().child(userFavActivitiesEntity).child(currentUserID)
        self.reference.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists(), let favoriteActivitiesSnapshot = snapshot.value as? [String: [String]] {
                if !NSDictionary(dictionary: self.favAct).isEqual(to: favoriteActivitiesSnapshot) {
                    print("favAct")
                    self.favAct = favoriteActivitiesSnapshot
                    self.collectionView.reloadData()
                }
            } else {
                if !self.favAct.isEmpty {
                    self.favAct = [String: [String]]()
                    self.collectionView.reloadData()
                    print("snapshot does not exist")
                }
           }
          })
        { (error) in
            print(error.localizedDescription)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
    
    func getSelectedFalconUsers(forActivity activity: Activity, completion: @escaping ([User])->()) {
        guard let participantsIDs = activity.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        var selectedFalconUsers = [User]()
        let group = DispatchGroup()
        for id in participantsIDs {
            // Only if the current user is created this activity
            if activity.admin == currentUserID && id == currentUserID {
                continue
            }
            
            group.enter()
            let participantReference = Database.database().reference().child("users").child(id)
            participantReference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), var dictionary = snapshot.value as? [String: AnyObject] {
                    dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                    let user = User(dictionary: dictionary)
                    selectedFalconUsers.append(user)
                }
                group.leave()
            })
        }
        
        group.notify(queue: .main) {
            completion(selectedFalconUsers)
        }
    }
    
    
}

extension ActivitySubTypeViewController: UpdateActivityDelegate {
    func updateActivity(activity: Activity) {
        delegate?.updateActivity(activity: activity)
    }
}
