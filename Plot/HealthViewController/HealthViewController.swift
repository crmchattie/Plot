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
                tableView.reloadData()
            }
        }
    }
    
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return tableView
    }()
    
    let spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        return spinner
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        view.addSubview(spinner)
        
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
        
        tableView.indicatorStyle = theme.scrollBarStyle
        tableView.sectionIndexBackgroundColor = theme.generalBackgroundColor
        tableView.backgroundColor = theme.generalBackgroundColor
        tableView.reloadData()
    }
    
    private func configureView() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(HealthMetricCell.self, forCellReuseIdentifier: healthMetricCellID)
        tableView.allowsMultipleSelectionDuringEditing = false
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.backgroundColor = view.backgroundColor
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 105
    }
}

extension HealthViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return healthMetrics.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: healthMetricCellID, for: indexPath) as! HealthMetricCell
        cell.backgroundColor = tableView.backgroundColor
        let metric = healthMetrics[indexPath.row]
        cell.configure(metric)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let metric = healthMetrics[indexPath.row]
        let healthDetailViewController = HealthDetailViewController()
        healthDetailViewController.healthMetric = metric
        healthDetailViewController.title = metric.type.name
        navigationController?.pushViewController(healthDetailViewController, animated: true)
    }
}
