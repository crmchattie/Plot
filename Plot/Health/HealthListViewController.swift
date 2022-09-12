//
//  HealthListViewController.swift
//  Plot
//
//  Created by Cory McHattie on 9/12/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

fileprivate let healthMetricCellID = "HealthMetricCellID"
fileprivate let healthMetricSectionHeaderID = "HealthMetricSectionHeaderID"


class HealthListViewController: UIViewController, ObjectDetailShowing {
    var participants = [String : [User]]()
    
    func showActivityIndicator() {
        
    }
    
    func hideActivityIndicator() {
        
    }
    
    var networkController: NetworkController
    
    init(networkController: NetworkController) {
        self.networkController = networkController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let healhKitManager = HealthKitManager()
    
    var workouts: [Workout] {
        return networkController.healthService.workouts
    }
    var mindfulness: [Mindfulness] {
        return networkController.healthService.mindfulnesses
    }
    var filteredHealthMetricSections = [HealthMetricCategory]()
    var filteredHealthMetrics = [HealthMetricCategory: [AnyHashable]]()
    
    var filters: [filter] = [.search, .healthCategory]
    var filterDictionary = [String: [String]]()
    
    let collectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
            
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        collectionView.dataSource = self
        collectionView.delegate = self
             
        configureView()
        addObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .healthUpdated, object: nil)
    }
    
    @objc fileprivate func setupData() {
        if filteredHealthMetricSections.contains(.workoutsList) {
            filteredHealthMetrics[.workoutsList] = workouts
        } else if filteredHealthMetricSections.contains(.mindfulnessList) {
            filteredHealthMetrics[.mindfulnessList] = mindfulness
        }
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    @objc fileprivate func changeTheme() {
        let theme = ThemeManager.currentTheme()
        view.backgroundColor = theme.generalBackgroundColor
        collectionView.indicatorStyle = theme.scrollBarStyle
        collectionView.backgroundColor = theme.generalBackgroundColor
        collectionView.reloadData()
    }
    
    private func configureView() {
        extendedLayoutIncludesOpaqueBars = true
        let newItemBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newItem))
//        let filterBarButton = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(filter))
        navigationItem.rightBarButtonItems = [newItemBarButton]
        
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            collectionView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
            collectionView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
        ])
        
        collectionView.register(HealthMetricCell.self, forCellWithReuseIdentifier: healthMetricCellID)
        collectionView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        collectionView.backgroundColor = view.backgroundColor
        
    }
    
    @objc fileprivate func newItem() {
        if filteredHealthMetricSections.contains(.workoutsList) {
            let destination = WorkoutViewController(networkController: self.networkController)
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        } else if filteredHealthMetricSections.contains(.mindfulnessList) {
            let destination = MindfulnessViewController(networkController: self.networkController)
            destination.hidesBottomBarWhenPushed = true
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }
    
    @objc fileprivate func filter() {
        let destination = FilterViewController(networkController: networkController)
        let navigationViewController = UINavigationController(rootViewController: destination)
        destination.delegate = self
        destination.filters = filters
        destination.filterDictionary = filterDictionary
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    func openMetric(metric: AnyHashable) {
        if let workout = metric as? Workout {
            showWorkoutDetailPush(workout: workout)
        } else if let mindfulness = metric as? Mindfulness {
            showMindfulnessDetailPush(mindfulness: mindfulness)
        }
    }
}

extension HealthListViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return filteredHealthMetricSections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let key = filteredHealthMetricSections[section]
        return filteredHealthMetrics[key]?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: healthMetricCellID, for: indexPath) as! HealthMetricCell
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 0
        let dummyCell = collectionView.dequeueReusableCell(withReuseIdentifier: healthMetricCellID, for: indexPath) as! HealthMetricCell
        let key = filteredHealthMetricSections[indexPath.section]
        if let metrics = filteredHealthMetrics[key] {
            let metric = metrics[indexPath.row]
            dummyCell.configure(metric)
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width - 30, height: 1000))
            height = estimatedSize.height
        }
        return CGSize(width: self.collectionView.frame.size.width - 30, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
    }
}

extension HealthListViewController: UpdateFilter {
    func updateFilter(filterDictionary : [String: [String]]) {
        self.filterDictionary = filterDictionary
        updateCollectionViewWFilters()
    }
    
    func updateCollectionViewWFilters() {
//        filteredHealthMetricSections = healthMetricSections
//        filteredHealthMetrics = healthMetrics
//        let dispatchGroup = DispatchGroup()
//        if let value = filterDictionary["calendarView"], let view = CalendarView(rawValue: value[0].lowercased()), self.calendarView != view {
//            self.calendarView = view
//        }
//        if let value = filterDictionary["search"] {
//            dispatchGroup.enter()
//            self.calendarView = .list
//            let searchText = value[0]
//            filteredPinnedActivities = filteredPinnedActivities.filter({ (activity) -> Bool in
//                    if let name = activity.name {
//                        return name.lowercased().contains(searchText.lowercased())
//                    }
//                    return ("").lowercased().contains(searchText.lowercased())
//                })
//            filteredActivities = filteredActivities.filter({ (activity) -> Bool in
//                    if let name = activity.name {
//                        return name.lowercased().contains(searchText.lowercased())
//                    }
//                    return ("").lowercased().contains(searchText.lowercased())
//                })
//            dispatchGroup.leave()
//        }
//        if let categories = filterDictionary["calendarCategory"] {
//            dispatchGroup.enter()
//            self.calendarView = .list
//            filteredPinnedActivities = filteredPinnedActivities.filter({ (activity) -> Bool in
//                if let category = activity.category {
//                    return categories.contains(category)
//                }
//                return false
//            })
//            filteredActivities = filteredActivities.filter({ (activity) -> Bool in
//                if let category = activity.category {
//                    return categories.contains(category)
//                }
//                return false
//            })
//            dispatchGroup.leave()
//        }
//
//        dispatchGroup.notify(queue: .main) {
//            self.activityView.tableView.reloadData()
//            self.activityView.tableView.layoutIfNeeded()
//            self.handleReloadActivities(animated: false)
//            self.saveCalendarView()
//        }
    }
        
}
