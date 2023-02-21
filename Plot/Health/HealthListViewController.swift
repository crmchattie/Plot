//
//  HealthListViewController.swift
//  Plot
//
//  Created by Cory McHattie on 9/12/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

class HealthListViewController: UIViewController, ObjectDetailShowing {
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
    
    var workouts: [Workout] {
        return networkController.healthService.workouts
    }
    var mindfulness: [Mindfulness] {
        return networkController.healthService.mindfulnesses
    }
    
    var healthMetricSections = [HealthMetricCategory]()
    var healthMetrics = [HealthMetricCategory: [AnyHashable]]()
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
            
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
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
        
        if filteredHealthMetrics[.workoutsList] != nil {
            filters = [.search, .workoutCategory]
        } else if filteredHealthMetrics[.mindfulnessList] != nil {
            filters = [.search]
        }
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    private func configureView() {
        extendedLayoutIncludesOpaqueBars = true
        let newItemBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newItem))
        let filterBarButton = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(filter))
        
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
        collectionView.indicatorStyle = .default
        collectionView.backgroundColor = view.backgroundColor
        
    }
    
    @objc fileprivate func newItem() {
        if filteredHealthMetricSections.contains(.workoutsList) {
            self.showWorkoutDetailPresent(workout: nil, updateDiscoverDelegate: nil, delegate: nil, template: nil, users: nil, container: nil, movingBackwards: nil)
        } else if filteredHealthMetricSections.contains(.mindfulnessList) {
            self.showMindfulnessDetailPresent(mindfulness: nil, updateDiscoverDelegate: nil, delegate: nil, template: nil, users: nil, container: nil, movingBackwards: nil)
        } else if filteredHealthMetricSections.contains(.moodList) {
            self.showMoodDetailPresent(mood: nil, updateDiscoverDelegate: nil, delegate: nil, template: nil, users: nil, container: nil, movingBackwards: nil)
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
            showWorkoutDetailPresent(workout: workout, updateDiscoverDelegate: nil, delegate: nil, template: nil, users: nil, container: nil, movingBackwards: nil)
        } else if let mindfulness = metric as? Mindfulness {
            showMindfulnessDetailPresent(mindfulness: mindfulness, updateDiscoverDelegate: nil, delegate: nil, template: nil, users: nil, container: nil, movingBackwards: nil)
        } else if let mood = metric as? Mood {
            showMoodDetailPresent(mood: mood, updateDiscoverDelegate: nil, delegate: nil, template: nil, users: nil, container: nil, movingBackwards: nil)
        }
    }
}

extension HealthListViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
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
    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        var height: CGFloat = 0
//        let dummyCell = collectionView.dequeueReusableCell(withReuseIdentifier: healthMetricCellID, for: indexPath) as! HealthMetricCollectionCell
//        let key = filteredHealthMetricSections[indexPath.section]
//        if let metrics = filteredHealthMetrics[key] {
//            let metric = metrics[indexPath.row]
//            dummyCell.configure(metric)
//            dummyCell.layoutIfNeeded()
//            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width - 30, height: 1000))
//            height = estimatedSize.height
//        }
//        return CGSize(width: self.collectionView.frame.size.width - 30, height: height)
//    }
    
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
        filteredHealthMetricSections = []
        filteredHealthMetrics = [:]
        
        if filterDictionary.isEmpty {
            setupData()
        } else {
            if filteredHealthMetrics[.workoutsList] != nil {
                var filteredWorkouts = workouts
                if let value = filterDictionary["search"] {
                    let searchText = value[0]
                    filteredWorkouts = filteredWorkouts.filter({ (workout) -> Bool in
                        return workout.name.lowercased().contains(searchText.lowercased())
                    })
                }
                if let filteredWorkoutCategories = filterDictionary["workoutCategory"] {
                    filteredWorkouts = filteredWorkouts.filter { (workout) -> Bool in
                        return filteredWorkoutCategories.contains(workout.type ?? "")
                    }
                }
                if !filteredWorkouts.isEmpty {
                    filteredHealthMetricSections.append(.workoutsList)
                    filteredHealthMetrics[.workoutsList] = filteredWorkouts
                }
            } else if filteredHealthMetrics[.mindfulnessList] != nil {
                var filteredMindfulness = mindfulness
                if let value = filterDictionary["search"] {
                    let searchText = value[0]
                    filteredMindfulness = filteredMindfulness.filter({ (mindfulness) -> Bool in
                        return mindfulness.name.lowercased().contains(searchText.lowercased())
                    })
                }
                if !filteredMindfulness.isEmpty {
                    filteredHealthMetricSections.append(.mindfulnessList)
                    filteredHealthMetrics[.mindfulnessList] = filteredMindfulness
                }
            }
        }
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
        
}
