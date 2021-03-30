//
//  AnalyticsViewController.swift
//  Plot
//
//  Created by Botond Magyarosi on 11/03/2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import UIKit
import SwiftUI

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
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "pencil.circle.fill"),
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(showConfig))
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(AnalyticsBarChartCell.self)
        tableView.register(AnalyticsLineChartCell.self)
        
        view.addSubview(activityIndicator)
        activityIndicator.center = view.center
        activityIndicator.autoresizingMask = [.flexibleTopMargin,
                                              .flexibleBottomMargin,
                                              .flexibleLeftMargin,
                                              .flexibleRightMargin]
        activityIndicator.startAnimating()
        viewModel.loadData {
            self.activityIndicator.removeFromSuperview()
            self.tableView.reloadData()
        }
    }
    
    private func openDetail(for indexPath: IndexPath) {
        let controller = AnalyticsDetailViewController(viewModel: viewModel.makeDetailViewModel(for: indexPath))
        controller.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(controller, animated: true)
    }
    
    @objc private func showConfig() {
        let controller = UIHostingController(rootView: ChooseAnalyticsDataPointsView())
        navigationController?.present(controller, animated: true)
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension AnalyticsViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int { viewModel.sections.count }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.sections[section].items.count * 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row % 2 == 0 {
            let cellViewModel = viewModel.sections[indexPath.section].items[indexPath.row / 2]
            switch cellViewModel.chartType {
            case .continous:
                let cell = tableView.dequeueReusableCell(ofType: AnalyticsLineChartCell.self, for: indexPath)
                cell.configure(with: cellViewModel)
                return cell
            case .values:
                let cell = tableView.dequeueReusableCell(ofType: AnalyticsBarChartCell.self, for: indexPath)
                cell.configure(with: cellViewModel)
                return cell
            }
        } else {
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.backgroundColor = .tertiarySystemBackground
            cell.textLabel?.text = "See detail"
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        indexPath.row > 0 ? indexPath : nil
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        viewModel.sections[section].title.capitalized
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        openDetail(for: indexPath)
    }
}
