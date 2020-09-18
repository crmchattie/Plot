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

class HealthViewController: UIViewController {
    weak var delegate: HomeBaseHealth?
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        configureView()
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
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
        let metric = healthMetrics[indexPath.row]
        cell.textLabel?.text = metric.type.rawValue.capitalized
        cell.detailTextLabel?.text = "\(metric.total) \(metric.unit)"
        return cell
    }
}
