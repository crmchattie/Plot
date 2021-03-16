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
    
    
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(StackedBarChartCell.self)
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
        
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        
        let control = UISegmentedControl(items: ["Weekly", "Monthly", "Yearly"])
        control.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(control)
        
//        tableView.tableHeaderView = control
        
        NSLayoutConstraint.activate([
            control.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            control.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            control.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            control.bottomAnchor.constraint(equalTo: tableView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: UITableViewDataSource & UITableViewDelegate

extension AnalyticsDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(ofType: StackedBarChartCell.self, for: indexPath)
            cell.configure(with: viewModel.chartViewModel)
            return cell
        } else {
            return UITableViewCell()
        }
    }
}
