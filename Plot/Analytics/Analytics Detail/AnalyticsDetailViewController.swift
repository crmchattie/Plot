//
//  AnalyticsDetailViewController.swift
//  Plot
//
//  Created by Botond Magyarosi on 16.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import UIKit

class AnalyticsDetailViewController: UIViewController {
    
    private let viewModel: AnalyticsDetailViewModel!
    
    private let rangeControlView: UISegmentedControl = {
        let control = UISegmentedControl(items: ActivityFilterOption.allCases.map { $0.rawValue} )
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        control.addTarget(self, action: #selector(rangeChanged), for: .touchUpInside)
        return control
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(StackedBarChartCell.self)
        tableView.register(ActivityCell.self)
        return tableView
    }()

    // MARK: - Lifecycle

    init(viewModel: AnalyticsDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = "Analytics detail"
        
        let rangeContainer = UIView()
        rangeContainer.translatesAutoresizingMaskIntoConstraints = false
        rangeContainer.addSubview(rangeControlView)
        
        NSLayoutConstraint.activate([
            rangeControlView.leadingAnchor.constraint(equalTo: rangeContainer.leadingAnchor, constant: 8),
            rangeControlView.topAnchor.constraint(equalTo: rangeContainer.topAnchor, constant: 16),
            rangeControlView.trailingAnchor.constraint(equalTo: rangeContainer.trailingAnchor, constant: -8),
            rangeControlView.bottomAnchor.constraint(equalTo: rangeContainer.bottomAnchor, constant: -16)
        ])
        
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.tableHeaderView = rangeContainer
        
        tableView.tableHeaderView?.layoutIfNeeded()
        tableView.tableHeaderView?.frame.size.width = self.view.bounds.width
        tableView.tableHeaderView = self.tableView.tableHeaderView
        
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            rangeContainer.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func rangeChanged(_ sender: UISegmentedControl) {
        viewModel.filter = ActivityFilterOption.allCases[sender.selectedSegmentIndex]
    }
}

// MARK: UITableViewDataSource & UITableViewDelegate

extension AnalyticsDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int { 2 }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : viewModel.activities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(ofType: StackedBarChartCell.self, for: indexPath)
            cell.configure(with: viewModel.chartViewModel)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(ofType: ActivityCell.self, for: indexPath)
            cell.configureCell(for: indexPath, activity: viewModel.activities[indexPath.row], withInvitation: nil)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
}
