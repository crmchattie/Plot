//
//  HealthViewController.swift
//  Plot
//
//  Created by Cory McHattie on 8/21/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class HealthViewController: UIViewController, ObjectDetailShowing {
    var participants = [String : [User]]()
    
    var networkController: NetworkController
    
    init(networkController: NetworkController) {
        self.networkController = networkController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let healhKitManager = HealthKitManager()
    
    var healthMetricSections: [HealthMetricCategory] {
        return networkController.healthService.healthMetricSections
    }
    var healthMetrics: [HealthMetricCategory: [HealthMetric]] {
        return networkController.healthService.healthMetrics
    }
    var workouts: [Workout] {
        return networkController.healthService.workouts
    }
    var mindfulness: [Mindfulness] {
        return networkController.healthService.mindfulnesses
    }
    var filteredHealthMetricSections = [HealthMetricCategory]()
    var filteredHealthMetrics = [HealthMetricCategory: [AnyHashable]]()
    
    var filters: [filter] = []
    var filterDictionary = [String: [String]]()
    
    let viewPlaceholder = ViewPlaceholder()
    
    let collectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.itemSize = UICollectionViewFlowLayout.automaticSize
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    let refreshControl = UIRefreshControl()
            
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        title = "Health"
        
        collectionView.dataSource = self
        collectionView.delegate = self
             
        setupData()
        configureView()
        addObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .healthUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .workoutsUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .mindfulnessUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .moodsUpdated, object: nil)
    }
    
    @objc fileprivate func setupData() {
        filteredHealthMetricSections = healthMetricSections
        filteredHealthMetrics = healthMetrics
//        if healthMetricSections.contains(.workouts) {
//            filteredHealthMetricSections.append(.workoutsList)
//            filteredHealthMetrics[.workoutsList] = workouts
//            filters = [.search, .workoutCategory]
//        }
//        if let generalMetrics = healthMetrics[.general], generalMetrics.contains(where: {$0.type == HealthMetricType.mindfulness }) {
//            filteredHealthMetricSections.append(.mindfulnessList)
//            filteredHealthMetrics[.mindfulnessList] = mindfulness
//            if filters.isEmpty {
//                filters = [.search]
//            }
//        }
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    private func configureView() {
        extendedLayoutIncludesOpaqueBars = true
        let newItemBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newItem))
        let filterBarButton = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(filter))
        
        refreshControl.addTarget(self, action: #selector(refreshControlAction(_:)), for: UIControl.Event.valueChanged)
        collectionView.refreshControl = refreshControl
        
        if !filters.isEmpty {
            navigationItem.rightBarButtonItems = [newItemBarButton, filterBarButton]
        } else {
            navigationItem.rightBarButtonItems = [newItemBarButton]
        }
        
        view.backgroundColor = .systemGroupedBackground
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            collectionView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
            collectionView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
        ])
        
        collectionView.register(HealthMetricCollectionCell.self, forCellWithReuseIdentifier: healthMetricCellID)
        collectionView.register(SectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: healthMetricSectionHeaderID)
        collectionView.indicatorStyle = .default
        collectionView.backgroundColor = view.backgroundColor
        
    }
    
    @objc fileprivate func newItem() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

//        alert.addAction(UIAlertAction(title: "Meal", style: .default, handler: { (_) in
//            let destination = MealViewController(networkController: self.networkController)
//            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
//            destination.navigationItem.leftBarButtonItem = cancelBarButton
//            let navigationViewController = UINavigationController(rootViewController: destination)
//            self.present(navigationViewController, animated: true, completion: nil)
//        }))
        
        alert.addAction(UIAlertAction(title: "Workout", style: .default, handler: { (_) in
            self.showWorkoutDetailPresent(workout: nil, updateDiscoverDelegate: nil, delegate: nil, template: nil, users: nil, container: nil, movingBackwards: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Mindfulness", style: .default, handler: { (_) in
            self.showMindfulnessDetailPresent(mindfulness: nil, updateDiscoverDelegate: nil, delegate: nil, template: nil, users: nil, container: nil, movingBackwards: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Mood", style: .default, handler: { (_) in
            self.showMoodDetailPresent(mood: nil, updateDiscoverDelegate: nil, delegate: nil, template: nil, users: nil, container: nil, movingBackwards: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
    
    @objc fileprivate func filter() {
        let destination = FilterViewController(networkController: networkController)
        let navigationViewController = UINavigationController(rootViewController: destination)
        destination.delegate = self
        destination.filters = filters
        destination.filterDictionary = filterDictionary
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    @objc func refreshControlAction(_ refreshControl: UIRefreshControl) {
        networkController.healthService.regrabHealth {
            DispatchQueue.main.async {
                self.setupData()
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    func openMetric(metric: AnyHashable) {
        if let healthMetric = metric as? HealthMetric {
            showHealthMetricDetailPush(healthMetric: healthMetric)
        } else if let workout = metric as? Workout {
            showWorkoutDetailPresent(workout: workout, updateDiscoverDelegate: nil, delegate: nil, template: nil, users: nil, container: nil, movingBackwards: nil)
        } else if let mindfulness = metric as? Mindfulness {
            showMindfulnessDetailPresent(mindfulness: mindfulness, updateDiscoverDelegate: nil, delegate: nil, template: nil, users: nil, container: nil, movingBackwards: nil)
        } else if let mood = metric as? Mood {
            showMoodDetailPresent(mood: mood, updateDiscoverDelegate: nil, delegate: nil, template: nil, users: nil, container: nil, movingBackwards: nil)
        }
    }
}

extension HealthViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if filteredHealthMetricSections.count == 0 {
            viewPlaceholder.add(for: collectionView, title: .emptySearch, subtitle: .emptySearch, priority: .medium, position: .fill)
        } else {
            viewPlaceholder.remove(from: collectionView, priority: .medium)
        }
        return filteredHealthMetricSections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let key = filteredHealthMetricSections[section]
        if key == .workoutsList || key == .mindfulnessList {
            if filteredHealthMetrics[key]?.count ?? 0 < 10 {
                return filteredHealthMetrics[key]?.count ?? 0
            }
            return 10
        }
        return filteredHealthMetrics[key]?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: healthMetricCellID, for: indexPath) as! HealthMetricCollectionCell
        let key = filteredHealthMetricSections[indexPath.section]
        if let metrics = filteredHealthMetrics[key] {
            let metric = metrics[indexPath.row]
            cell.configure(metric)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let key = filteredHealthMetricSections[indexPath.section]
        if let metrics = filteredHealthMetrics[key] {
            let metric = metrics[indexPath.row]
            openMetric(metric: metric)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: self.collectionView.frame.size.width, height: 40)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let key = filteredHealthMetricSections[indexPath.section]
            let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: healthMetricSectionHeaderID, for: indexPath) as! SectionHeader
            sectionHeader.backgroundColor = .systemGroupedBackground
            sectionHeader.titleLabel.text = key.name
            sectionHeader.delegate = self
            if (key == .workoutsList || key == .mindfulnessList) && filteredHealthMetrics[key]?.count ?? 0 > 10 {
                sectionHeader.sectionType = key
                sectionHeader.view.isUserInteractionEnabled = true
                sectionHeader.subTitleLabel.isHidden = false
            } else {
                sectionHeader.view.isUserInteractionEnabled = false
                sectionHeader.subTitleLabel.isHidden = true
            }
            return sectionHeader
        } else { //No footer in this case but can add option for that
            return UICollectionReusableView()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
    }
}

extension HealthViewController: SectionHeaderDelegate {
    func viewTapped(sectionType: HealthMetricCategory) {
        let destination = HealthListViewController(networkController: networkController)
        destination.title = sectionType.name
        destination.healthMetricSections = [sectionType]
        if let healthMetrics = filteredHealthMetrics[sectionType] {
            destination.healthMetrics = [sectionType: healthMetrics]
        }
        navigationController?.pushViewController(destination, animated: true)
    }
}

extension HealthViewController: UpdateFilter {
    func updateFilter(filterDictionary : [String: [String]]) {
        self.filterDictionary = filterDictionary
        updateCollectionViewWFilters()
    }
    
    func updateCollectionViewWFilters() {
        filteredHealthMetricSections = []
        filteredHealthMetrics = [:]
        
        if filterDictionary.isEmpty {
            setupData()
        } else {
            var filteredWorkouts = workouts
            var filteredMindfulness = mindfulness
            if let value = filterDictionary["search"] {
                let searchText = value[0]
                filteredWorkouts = filteredWorkouts.filter({ (workout) -> Bool in
                    return workout.name.lowercased().contains(searchText.lowercased())
                })
                filteredMindfulness = filteredMindfulness.filter({ (mindfulness) -> Bool in
                    return mindfulness.name.lowercased().contains(searchText.lowercased())
                })
            }
            if let filteredWorkoutCategories = filterDictionary["workoutCategory"] {
                filteredMindfulness = []
                filteredWorkouts = filteredWorkouts.filter { (workout) -> Bool in
                    return filteredWorkoutCategories.contains(workout.type ?? "")
                }
            }
            if !filteredWorkouts.isEmpty {
                filteredHealthMetricSections.append(.workoutsList)
                filteredHealthMetrics[.workoutsList] = filteredWorkouts
            }
            if !filteredMindfulness.isEmpty {
                filteredHealthMetricSections.append(.mindfulnessList)
                filteredHealthMetrics[.mindfulnessList] = filteredMindfulness
            }
        }
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
}
