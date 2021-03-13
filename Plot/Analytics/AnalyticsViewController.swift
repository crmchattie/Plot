//
//  AnalyticsViewController.swift
//  Plot
//
//  Created by Botond Magyarosi on 11/03/2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import UIKit

class AnalyticsViewController: UITableViewController {

    init() {
        if #available(iOS 13.0, *) {
            super.init(style: .grouped)
        } else {
            super.init(nibName: nil, bundle: nil)
        }
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
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension AnalyticsViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        2
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(ofType: StackedBarChartCell.self, for: indexPath)
            return cell
        } else {
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.backgroundColor = .secondarySystemBackground
            cell.textLabel?.text = "See all activities"
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "ACTIVITIES"
    }
}
