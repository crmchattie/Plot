//
//  HealthViewController.swift
//  Plot
//
//  Created by Cory McHattie on 8/21/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

fileprivate let healthMetricCellID = "HealthMetricCellID"

protocol HomeBaseHealth: class {
//    func sendLists(lists: [ListContainer])
}

protocol HealthViewControllerActivitiesDelegate: class {
    func update(_ healthViewController: HealthViewController, _ shouldFetchActivities: Bool)
}

class HealthViewController: UIViewController {
    weak var delegate: HomeBaseHealth?
    
    var hasViewAppeared = false
    let healhKitManager = HealthKitManager()
    var healthMetrics: [HealthMetric] = [] {
        didSet {
            if oldValue != healthMetrics {
                collectionView.reloadData()
            }
        }
    }
    
    let collectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.contentInset.bottom = 20
        return collectionView
    }()
    
    let spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        return spinner
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(collectionView)
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(spinner)
        
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }
        
        configureView()
        addObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !hasViewAppeared {
            hasViewAppeared = true
            
            HealthKitService.authorizeHealthKit { [weak self] authorized in
                guard authorized else {
                    return
                }
                
                DispatchQueue.main.async {
                    self?.spinner.startAnimating()
                }
                
                self?.healhKitManager.loadHealthKitActivities { [weak self] metrics, shouldFetchActivities in
                    DispatchQueue.main.async {
                        self?.healthMetrics = metrics
                        self?.spinner.stopAnimating()
                    }
                }
            }
        }
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
        
        collectionView.indicatorStyle = theme.scrollBarStyle
        collectionView.backgroundColor = theme.generalBackgroundColor
        collectionView.reloadData()
    }
    
    private func configureView() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            collectionView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
            collectionView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        collectionView.register(HealthMetricCell.self, forCellWithReuseIdentifier: healthMetricCellID)
        collectionView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        collectionView.backgroundColor = view.backgroundColor
    }
}

extension HealthViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        healthMetrics.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: healthMetricCellID, for: indexPath) as! HealthMetricCell
        cell.backgroundColor = collectionView.backgroundColor
        let metric = healthMetrics[indexPath.row]
        cell.configure(metric)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let metric = healthMetrics[indexPath.row]
        let healthDetailViewModel = HealthDetailViewModel(healthMetric: metric, healthDetailService: HealthDetailService())
        let healthDetailViewController = HealthDetailViewController(viewModel: healthDetailViewModel)
        navigationController?.pushViewController(healthDetailViewController, animated: true)
    }
}
