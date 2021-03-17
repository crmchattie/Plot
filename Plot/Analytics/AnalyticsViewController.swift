//
//  AnalyticsViewController.swift
//  Plot
//
//  Created by Botond Magyarosi on 11/03/2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import UIKit

class AnalyticsViewController: UITableViewController {
    
    private var viewModel: AnalyticsViewModel!

    init(viewModel: AnalyticsViewModel) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Analytics"
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(StackedBarChartCell.self)
        
        viewModel.fetchActivities { result in
            self.tableView.reloadData()
        }
    }
    
    private func openDetail(forSection section: Int) {
        guard viewModel.items.count > section else { return }
        switch viewModel.items[section] {
        case is ActivityStackedBarChartViewModel:
            let viewModel = AnalyticsDetailViewModel(chartViewModel: self.viewModel.items[section],
                                                     networkController: self.viewModel.networkController)
            let controller = AnalyticsDetailViewController(viewModel: viewModel)
            navigationController?.pushViewController(controller, animated: true)
        case is HealthStackedBarChartViewModel:
            #warning("Open detail.")
            let controller = UIViewController()
            navigationController?.pushViewController(controller, animated: true)
        case is FinancesStackedBarChartViewModel:
            #warning("Open detail.")
            let controller = UIViewController()
            navigationController?.pushViewController(controller, animated: true)
        default:
            break
        }
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension AnalyticsViewController {

    override func numberOfSections(in tableView: UITableView) -> Int { viewModel.items.count }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 2 }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(ofType: StackedBarChartCell.self, for: indexPath)
            cell.configure(with: viewModel.items[indexPath.section])
            return cell
        } else {
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.backgroundColor = .tertiarySystemBackground
            cell.textLabel?.text = "See all activities"
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        viewModel.items[section].sectionTitle.capitalized
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 1 {
            openDetail(forSection: indexPath.section)
        }
    }
}
