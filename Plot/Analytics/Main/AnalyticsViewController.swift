//
//  AnalyticsViewController.swift
//  Plot
//
//  Created by Botond Magyarosi on 11/03/2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import UIKit

class AnalyticsViewController: UITableViewController {
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.sizeToFit()
        return activityIndicator
    }()
    
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
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .top
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(StackedBarChartCell.self)
        
        view.addSubview(activityIndicator)
        activityIndicator.center = view.center
        activityIndicator.autoresizingMask = [.flexibleTopMargin,
                                              .flexibleBottomMargin,
                                              .flexibleLeftMargin,
                                              .flexibleRightMargin]
        activityIndicator.startAnimating()
        viewModel.fetchActivities { result in
            self.activityIndicator.removeFromSuperview()
            self.tableView.reloadData()
        }
    }
    
    private func openDetail(forSection section: Int) {
        guard viewModel.items.count > section else { return }
        let viewModel = AnalyticsDetailViewModel(chartViewModel: self.viewModel.items[section],
                                                 networkController: self.viewModel.networkController)
        let controller = AnalyticsDetailViewController(viewModel: viewModel)
        controller.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(controller, animated: true)
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
            cell.contentView.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            cell.backgroundColor = .tertiarySystemBackground
            cell.textLabel?.text = "See all activities"
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        indexPath.row > 0 ? indexPath : nil
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        viewModel.items[section].sectionTitle.capitalized
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        openDetail(forSection: indexPath.section)
    }
}
