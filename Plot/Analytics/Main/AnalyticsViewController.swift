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
    
    var viewModel: AnalyticsViewModel? {
        didSet { loadData() }
    }
    
    init() {
        super.init(style: .insetGrouped)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let viewPlaceholder = ViewPlaceholder()
    
    let headerCellID = "headerCellID"
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Analytics"
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .top
        
//        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(AnalyticsBarChartCell.self)
        tableView.register(AnalyticsLineChartCell.self)
        tableView.register(AnalyticsHorizontalBarChartCell.self)
        tableView.register(TableViewHeader.self,
                           forHeaderFooterViewReuseIdentifier: headerCellID)
        
        
    }
    
    private func loadData() {
        view.addSubview(activityIndicator)
        activityIndicator.center = view.center
        activityIndicator.autoresizingMask = [.flexibleTopMargin,
                                              .flexibleBottomMargin,
                                              .flexibleLeftMargin,
                                              .flexibleRightMargin]
        activityIndicator.startAnimating()
        viewModel?.loadData {
            self.activityIndicator.removeFromSuperview()
            self.tableView.reloadData()
        }
    }
    
    private func openDetail(for indexPath: IndexPath) {
        guard let viewModel = viewModel else { return }
        let controller = AnalyticsDetailViewController(viewModel: viewModel.makeDetailViewModel(for: indexPath))
        controller.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(controller, animated: true)
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension AnalyticsViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if viewModel?.sections.count ?? 0 == 0 {
            viewPlaceholder.add(for: tableView, title: .emptyAnalytics, subtitle: .emptyAnalytics, priority: .medium, position: .top)
        } else {
            viewPlaceholder.remove(from: tableView, priority: .medium)
        }
        return viewModel?.sections.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel!.sections[section].items.count * 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row % 2 == 0 {
            let cellViewModel = viewModel!.sections[indexPath.section].items[indexPath.row / 2]
            switch cellViewModel.chartType {
            case .line:
                let cell = tableView.dequeueReusableCell(ofType: AnalyticsLineChartCell.self, for: indexPath)
                cell.chartView.isUserInteractionEnabled = false
                cell.configure(with: cellViewModel)
                return cell
            case .verticalBar:
                let cell = tableView.dequeueReusableCell(ofType: AnalyticsBarChartCell.self, for: indexPath)
                cell.chartView.isUserInteractionEnabled = false
                cell.configure(with: cellViewModel)
                return cell
            case .horizontalBar:
                let cell = tableView.dequeueReusableCell(ofType: AnalyticsHorizontalBarChartCell.self, for: indexPath)
                cell.chartView.isUserInteractionEnabled = false
                cell.configure(with: cellViewModel)
                return cell
            }
        } else {
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textLabel?.text = "See detail"
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }
    
//    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
//        indexPath.row > 0 ? indexPath : nil
//    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier:
                                                                headerCellID) as? TableViewHeader ?? TableViewHeader()
        header.titleLabel.text = viewModel!.sections[section].title.capitalized
        header.subTitleLabel.isHidden = true
        return header

    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        openDetail(for: indexPath)
    }
}
