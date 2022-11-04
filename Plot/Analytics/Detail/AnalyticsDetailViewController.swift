//
//  AnalyticsDetailViewController.swift
//  Plot
//
//  Created by Botond Magyarosi on 16.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import UIKit
import Combine
import Firebase

class AnalyticsDetailViewController: UIViewController, ObjectDetailShowing {
    
    var networkController: NetworkController { viewModel.networkController }
    
    private let viewModel: AnalyticsDetailViewModel!
    private var cancellables = Set<AnyCancellable>()
    
    // activities
    var participants: [String : [User]] = [:]
    // transaction
    var users = [User]()
    var filteredUsers = [User]()
    
    private let rangeControlView: UISegmentedControl = {
        let control = UISegmentedControl(items: DateRangeType.allCases.map { $0.filterTitle } )
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(AnalyticsBarChartCell.self)
        tableView.register(AnalyticsLineChartCell.self)
        tableView.register(TaskCell.self)
        tableView.register(EventCell.self)
        tableView.register(FinanceTableViewCell.self)
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
        
        navigationItem.title = viewModel.title
        
        rangeControlView.addTarget(self, action: #selector(rangeChanged), for: .valueChanged)
        
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
        tableView.dataSource = self
        tableView.tableHeaderView = rangeContainer
        tableView.separatorStyle = .none
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
        
        initBindings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        rangeChanged(rangeControlView)
    }
    
    func showActivityIndicator() {
        if let tabController = self.tabBarController {
            self.showSpinner(onView: tabController.view)
        }
        self.navigationController?.view.isUserInteractionEnabled = false
    }
    
    func hideActivityIndicator() {
        self.navigationController?.view.isUserInteractionEnabled = true
        self.removeSpinner()
    }
    
    private func initBindings() {
        viewModel.entries
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] _ in
                self.tableView.reloadData()
            }
            .store(in: &cancellables)
        
        viewModel.chartViewModel
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] _ in
                self.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    @objc private func rangeChanged(_ sender: UISegmentedControl) {
        viewModel.range.type = DateRangeType.allCases[sender.selectedSegmentIndex]
    }
}

// MARK: UITableViewDataSource & UITableViewDelegate

extension AnalyticsDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int { 2 }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : viewModel.entries.value.count
    }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let chartViewModel = viewModel.chartViewModel.value
            switch chartViewModel.chartType {
            case .continous:
                let cell = tableView.dequeueReusableCell(ofType: AnalyticsLineChartCell.self, for: indexPath)
                cell.prevNextStackView.isHidden = false
                cell.chartView.highlightPerTapEnabled = true
                cell.chartView.highlightPerDragEnabled = true
                cell.delegate = self
                cell.configure(with: chartViewModel)
                return cell
            case .values:
                let cell = tableView.dequeueReusableCell(ofType: AnalyticsBarChartCell.self, for: indexPath)
                cell.prevNextStackView.isHidden = false
                cell.chartView.highlightPerTapEnabled = true
                cell.chartView.highlightPerDragEnabled = true
                cell.delegate = self
                cell.configure(with: chartViewModel)
                return cell
            }
        } else {
            switch viewModel.entries.value[indexPath.row] {
            case .activity(let activity):
                if activity.isTask ?? false {
                    let cell = tableView.dequeueReusableCell(ofType: TaskCell.self, for: indexPath)
                    if let listID = activity.listID, let list = networkController.activityService.listIDs[listID], let color = list.color {
                        cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                    } else if let list = networkController.activityService.lists[ListSourceOptions.plot.name]?.first(where: { $0.defaultList ?? false }), let color = list.color {
                        cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                    }
                    cell.configureCell(for: indexPath, task: activity)
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(ofType: EventCell.self, for: indexPath)
                    if let calendarID = activity.calendarID, let calendar = networkController.activityService.calendarIDs[calendarID], let color = calendar.color {
                        cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                    } else if let calendar = networkController.activityService.calendars[CalendarSourceOptions.plot.name]?.first(where: { $0.defaultCalendar ?? false }), let color = calendar.color {
                        cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                    }
                    cell.configureCell(for: indexPath, activity: activity, withInvitation: nil)
                    return cell
                }
            case .transaction(let transaction):
                let cell = tableView.dequeueReusableCell(ofType: FinanceTableViewCell.self, for: indexPath)
                cell.transaction = transaction
                return cell
            case .account(let account):
                let cell = tableView.dequeueReusableCell(ofType: FinanceTableViewCell.self, for: indexPath)
                cell.account = account
                return cell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section > 0 else { return }
        switch viewModel.entries.value[indexPath.row] {
        case .activity(let activity):
            if activity.isTask ?? false {
                showTaskDetailPresent(task: activity, updateDiscoverDelegate: nil, delegate: nil, event: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, list: nil, startDateTime: nil, endDateTime: nil)
            } else {
                showEventDetailPresent(event: activity, updateDiscoverDelegate: nil, delegate: nil, task: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, startDateTime: nil, endDateTime: nil)
            }
        case .transaction(let transaction):
            showTransactionDetailPresent(transaction: transaction, updateDiscoverDelegate: nil, delegate: nil, users: nil, container: nil, movingBackwards: nil)
        case .account(let account):
            showAccountDetailPresent(account: account, updateDiscoverDelegate: nil)
        }
    }
}

// MARK: - StackedBarChartCellDelegate

extension AnalyticsDetailViewController: StackedBarChartCellDelegate {
    func previousTouched(on cell: StackedBarChartCell) {
        viewModel.loadPreviousSegment()
    }
    
    func nextTouched(on cell: StackedBarChartCell) {
        viewModel.loadNextSegment()
    }
}

// MARK: - UpdateTransactionDelegate

extension AnalyticsDetailViewController: UpdateTransactionDelegate {
    func updateTransaction(transaction: Transaction) {
        guard let index = viewModel.entries.value.firstIndex(where: {
            if case .transaction(let trs) = $0 {
                return trs == transaction
            }
            return false
        }) else { return }
        viewModel.entries.value[index] = .transaction(transaction)
        tableView.reloadData()
    }
}

// MARK: - UpdateAccountDelegate

extension AnalyticsDetailViewController: UpdateAccountDelegate {
    func updateAccount(account: MXAccount) {
        guard let index = viewModel.entries.value.firstIndex(where: {
            if case .account(let acct) = $0 {
                return acct == account
            }
            return false
        }) else { return }
        viewModel.entries.value[index] = .account(account)
        tableView.reloadData()
    }
}
