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
import HealthKit
import Charts

class AnalyticsDetailViewController: UIViewController, ObjectDetailShowing {
    
    var networkController: NetworkController { viewModel.networkController }
    
    private let viewModel: AnalyticsDetailViewModel!
    private var cancellables = Set<AnyCancellable>()
    
    // activities
    var participants: [String : [User]] = [:]
    // transaction
    var users = [User]()
    var filteredUsers = [User]()
    var filterOff = true
    
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
        tableView.register(AnalyticsHorizontalBarChartCell.self)
        tableView.register(TaskCell.self)
        tableView.register(EventCell.self)
        tableView.register(FinanceTableViewCell.self)
        tableView.register(HealthDetailSampleCell.self)
        tableView.register(HealthMetricTableCell.self)
        return tableView
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.sizeToFit()
        return activityIndicator
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
        
        view.backgroundColor = .systemGroupedBackground
        
        view.addSubview(activityIndicator)
        activityIndicator.center = view.center
        activityIndicator.autoresizingMask = [.flexibleTopMargin,
                                              .flexibleBottomMargin,
                                              .flexibleLeftMargin,
                                              .flexibleRightMargin]
        
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
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            rangeContainer.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        
        initBindings()
        addObservers()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        rangeChanged(rangeControlView)
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
        activityIndicator.startAnimating()
        tableView.isHidden = true
        tableView.reloadData()
        filterOff = true
        viewModel.range.type = DateRangeType.allCases[sender.selectedSegmentIndex]
        viewModel.updateType {
            self.activityIndicator.stopAnimating()
            self.tableView.isHidden = false
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(goalsUpdated), name: .goalsUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tasksUpdated), name: .tasksUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(eventsUpdated), name: .calendarActivitiesUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(transactionsUpdated), name: .transactionsUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(accountsUpdated), name: .accountsUpdated, object: nil)
    }
    
    @objc fileprivate func goalsUpdated() {
        if navigationItem.title == "Goals" {
            rangeChanged(rangeControlView)
        }
    }
    
    @objc fileprivate func tasksUpdated() {
        if navigationItem.title == "Tasks" {
            rangeChanged(rangeControlView)
        }
    }
    
    @objc fileprivate func eventsUpdated() {
        if navigationItem.title == "Events" {
            rangeChanged(rangeControlView)
        }
    }
    
    @objc fileprivate func transactionsUpdated() {
        if navigationItem.title == "Spending" {
            rangeChanged(rangeControlView)
        }
    }
    
    @objc fileprivate func accountsUpdated() {
        if navigationItem.title == "Net Worth" {
            rangeChanged(rangeControlView)
        }
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
            case .line:
                let cell = tableView.dequeueReusableCell(ofType: AnalyticsLineChartCell.self, for: indexPath)
                cell.prevNextStackView.isHidden = false
                cell.chartView.highlightPerTapEnabled = true
                cell.chartView.highlightPerDragEnabled = true
                cell.delegate = self
                cell.chartView.delegate = self
                cell.configure(with: chartViewModel)
                if filterOff {
                    cell.chartView.highlightValue(nil)
                }
                return cell
            case .verticalBar:
                let cell = tableView.dequeueReusableCell(ofType: AnalyticsBarChartCell.self, for: indexPath)
                cell.prevNextStackView.isHidden = false
                cell.chartView.highlightPerTapEnabled = true
                cell.chartView.highlightPerDragEnabled = true
                cell.delegate = self
                cell.chartView.delegate = self
                cell.configure(with: chartViewModel)
                if filterOff {
                    cell.chartView.highlightValue(nil)
                }
                return cell
            case .horizontalBar:
                let cell = tableView.dequeueReusableCell(ofType: AnalyticsHorizontalBarChartCell.self, for: indexPath)
                cell.prevNextStackView.isHidden = false
                cell.chartView.highlightPerTapEnabled = true
                cell.chartView.highlightPerDragEnabled = true
                cell.delegate = self
                cell.chartView.delegate = self
                cell.configure(with: chartViewModel)
                if filterOff {
                    cell.chartView.highlightValue(nil)
                }
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
            case .sample(let sample):
                let cell = tableView.dequeueReusableCell(ofType: HealthDetailSampleCell.self, for: indexPath)
                if let healthMetric = viewModel.chartViewModel.value.healthMetric {
                    if case .workout = healthMetric.type {
                        cell.selectionStyle = .default
                    } else if case .mindfulness = healthMetric.type {
                        cell.selectionStyle = .default
                    } else if case .workoutMinutes = healthMetric.type {
                        cell.selectionStyle = .default
                    } else {
                        cell.selectionStyle = .none
                    }
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.healthMetric = healthMetric
                    let segmentType = TimeSegmentType(rawValue: rangeControlView.selectedSegmentIndex + 1)
                    cell.configure(sample, segmentType: segmentType ?? .week)
                }
                return cell
            case .mood(let mood):
                let cell = tableView.dequeueReusableCell(ofType: HealthMetricTableCell.self, for: indexPath)
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.configure(mood)
                return cell
            case .workout(let workout):
                let cell = tableView.dequeueReusableCell(ofType: HealthMetricTableCell.self, for: indexPath)
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.configure(workout)
                return cell
            case .mindfulness(let mindfulness):
                let cell = tableView.dequeueReusableCell(ofType: HealthMetricTableCell.self, for: indexPath)
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.configure(mindfulness)
                return cell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section > 0 else { return }
        switch viewModel.entries.value[indexPath.row] {
        case .activity(let activity):
            if activity.isGoal ?? false {
                showGoalDetailPresent(task: activity, updateDiscoverDelegate: nil, delegate: nil, event: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, list: nil, startDateTime: nil, endDateTime: nil)
            } else if !(activity.isGoal ?? false), activity.isTask ?? false {
                showTaskDetailPresent(task: activity, updateDiscoverDelegate: nil, delegate: nil, event: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, list: nil, startDateTime: nil, endDateTime: nil)
            } else {
                showEventDetailPresent(event: activity, updateDiscoverDelegate: nil, delegate: nil, task: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, startDateTime: nil, endDateTime: nil)
            }
        case .transaction(let transaction):
            showTransactionDetailPresent(transaction: transaction, updateDiscoverDelegate: nil, delegate: nil, users: nil, container: nil, movingBackwards: nil)
        case .account(let account):
            showAccountDetailPresent(account: account, updateDiscoverDelegate: nil)
        case .sample(let sample):
            if let hkWorkout = sample as? HKWorkout {
                let hkSampleID = hkWorkout.uuid.uuidString
                if let workout = self.networkController.healthService.workouts.first(where: {$0.hkSampleID == hkSampleID }) {
                    showWorkoutDetailPresent(workout: workout, updateDiscoverDelegate: nil, delegate: nil, template: nil, users: nil, container: nil, movingBackwards: nil)
                }
            }
            else if let hkMindfulness = sample as? HKCategorySample {
                let hkSampleID = hkMindfulness.uuid.uuidString
                if let mindfulness = self.networkController.healthService.mindfulnesses.first(where: {$0.hkSampleID == hkSampleID }) {
                    showMindfulnessDetailPresent(mindfulness: mindfulness, updateDiscoverDelegate: nil, delegate: nil, template: nil, users: nil, container: nil, movingBackwards: nil)
                }
            }
        case .mood(let mood):
            showMoodDetailPresent(mood: mood, updateDiscoverDelegate: nil, delegate: nil, template: nil, users: nil, container: nil, movingBackwards: nil)
        case .workout(let workout):
            showWorkoutDetailPresent(workout: workout, updateDiscoverDelegate: nil, delegate: nil, template: nil, users: nil, container: nil, movingBackwards: nil)
        case .mindfulness(let mindfulness):
            showMindfulnessDetailPresent(mindfulness: mindfulness, updateDiscoverDelegate: nil, delegate: nil, template: nil, users: nil, container: nil, movingBackwards: nil)
        }
    }
}

// MARK: - StackedBarChartCellDelegate

extension AnalyticsDetailViewController: StackedBarChartCellDelegate {
    func previousTouched(on cell: StackedBarChartCell) {
        activityIndicator.startAnimating()
        tableView.isHidden = true
        filterOff = true
        viewModel.loadPreviousSegment {
            self.activityIndicator.stopAnimating()
            self.tableView.isHidden = false
        }
    }
    
    func nextTouched(on cell: StackedBarChartCell) {
        filterOff = true
        activityIndicator.startAnimating()
        tableView.isHidden = true
        filterOff = true
        viewModel.loadNextSegment {
            self.activityIndicator.stopAnimating()
            self.tableView.isHidden = false
        }
    }
}

// MARK: - ChartViewDelegate
extension AnalyticsDetailViewController: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {        
        guard let date = entry.data as? Date else { return }
        filterOff = false
        viewModel.filter(date: date)
    }
    
    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        filterOff = true
        viewModel.filter(date: nil)
    }
    
    func chartScaled(_ chartView: ChartViewBase, scaleX: CGFloat, scaleY: CGFloat) {
        
    }
    
    func chartTranslated(_ chartView: ChartViewBase, dX: CGFloat, dY: CGFloat) {
        
    }
}
