//
//  FinanceDetailViewController.swift
//  Plot
//
//  Created by Cory McHattie on 9/16/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import Charts

fileprivate let chartViewHeight: CGFloat = 300
fileprivate let chartViewTopMargin: CGFloat = 10

class FinanceLineChartDetailViewController: UIViewController, ObjectDetailShowing {
        
    private let kFinanceTableViewCell = "FinanceTableViewCell"
    
    let isodateFormatter = ISO8601DateFormatter()
    let dateFormatterPrint = DateFormatter()
    
    var participants: [String: [User]] = [:]
        
    private var viewModel: FinanceDetailViewModelInterface
    var dayAxisValueFormatter: DayAxisValueFormatter?
    var backgroundChartViewHeightAnchor: NSLayoutConstraint?
    var backgroundChartViewTopAnchor: NSLayoutConstraint?
    
    lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
        
    lazy var backgroundChartView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
//        view.layer.cornerRadius = 10
//        view.layer.masksToBounds = true
        return view
    }()
    
    lazy var bufferView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var chartView: LineChartView = {
        let chartView = LineChartView()
        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.defaultChartStyle()
        chartView.highlightPerTapEnabled = true
        chartView.highlightPerDragEnabled = true
        return chartView
    }()
    
    lazy var segmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(items: ["D", "W", "M", "Y"])
        segmentedControl.addTarget(self, action: #selector(changeSegment(_:)), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        return segmentedControl
    }()
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return tableView
    }()
    
    lazy var barButton = UIBarButtonItem()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.sizeToFit()
        return activityIndicator
    }()
    
    lazy var units = "currency"
    
    var selectedIndex = 2
    
    var networkController: NetworkController
    
    init(viewModel: FinanceDetailViewModelInterface, networkController: NetworkController) {
        self.viewModel = viewModel
        self.networkController = networkController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("STORAGE DID DEINIT")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.isHidden = false
        navigationItem.largeTitleDisplayMode = .never
        
        
        
        extendedLayoutIncludesOpaqueBars = true
//        
//        barButton = UIBarButtonItem(title: "Hide Chart", style: .plain, target: self, action: #selector(hideUnhideTapped))
//        navigationItem.rightBarButtonItem = barButton
        
        if let accountDetails = viewModel.accountDetails {
            title = accountDetails.name
        } else if let transactionDetails = viewModel.transactionDetails {
            title = transactionDetails.name
        }

        addObservers()
        
        view.backgroundColor = .systemGroupedBackground
        containerView.backgroundColor = .systemBackground
        backgroundChartView.backgroundColor = .systemBackground
        chartView.backgroundColor = .systemBackground
        bufferView.backgroundColor = .systemGroupedBackground
        
        view.addSubview(activityIndicator)
        
        containerView.addSubview(segmentedControl)
        containerView.addSubview(backgroundChartView)
        containerView.addSubview(bufferView)
        backgroundChartView.addSubview(chartView)
        chartView.delegate = self
        
        segmentedControl.selectedSegmentIndex = selectedIndex
        
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        
        configureView()
        configureChart()
        
        fetchData(useAll: false)
                
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(financeUpdated), name: .financeUpdated, object: nil)
    }

    
    @objc fileprivate func financeUpdated() {
        DispatchQueue.main.async {
            self.fetchData(useAll: false)
        }
    }
    
    private func configureView() {
        
        activityIndicator.center = view.center
        activityIndicator.autoresizingMask = [.flexibleTopMargin,
                                              .flexibleBottomMargin,
                                              .flexibleLeftMargin,
                                              .flexibleRightMargin]
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])
        
        segmentedControl.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10).isActive = true
        segmentedControl.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 16).isActive = true
        segmentedControl.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: -16).isActive = true
        
        backgroundChartView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 10).isActive = true
        backgroundChartView.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 0).isActive = true
        backgroundChartView.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: 0).isActive = true
        backgroundChartView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10).isActive = true
        
        chartView.topAnchor.constraint(equalTo: backgroundChartView.topAnchor, constant: 10).isActive = true
        chartView.leftAnchor.constraint(equalTo: backgroundChartView.leftAnchor, constant: 10).isActive = true
        chartView.rightAnchor.constraint(equalTo: backgroundChartView.rightAnchor, constant: -5).isActive = true
        chartView.bottomAnchor.constraint(equalTo: backgroundChartView.bottomAnchor, constant: -10).isActive = true
        
        bufferView.topAnchor.constraint(equalTo: backgroundChartView.bottomAnchor, constant: 0).isActive = true
        bufferView.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 0).isActive = true
        bufferView.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: 0).isActive = true
        bufferView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0).isActive = true
        
        containerView.constrainHeight(340)
        tableView.tableHeaderView = containerView
        containerView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor).isActive = true
        containerView.widthAnchor.constraint(equalTo: tableView.widthAnchor).isActive = true
        containerView.topAnchor.constraint(equalTo: tableView.topAnchor).isActive = true
        tableView.tableHeaderView?.layoutIfNeeded()
        tableView.tableHeaderView = tableView.tableHeaderView
        
        tableView.separatorStyle = .none
        tableView.register(FinanceTableViewCell.self, forCellReuseIdentifier: kFinanceTableViewCell)
        tableView.allowsMultipleSelectionDuringEditing = false
        tableView.indicatorStyle = .default
        tableView.backgroundColor = view.backgroundColor
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 105
    }
    
    func configureChart() {
        chartView.maxVisibleCount = 60

        chartView.leftAxis.enabled = false
        
        dayAxisValueFormatter = DayAxisValueFormatter(chart: chartView)
        chartView.xAxis.valueFormatter = dayAxisValueFormatter
        chartView.xAxis.granularity = 1
        chartView.xAxis.labelCount = 5
        chartView.xAxis.labelFont = UIFont.caption1.with(weight: .regular)
        
        let rightAxisFormatter = NumberFormatter()
        rightAxisFormatter.numberStyle = .currency
        rightAxisFormatter.maximumFractionDigits = 0
        let rightAxis = chartView.rightAxis
        rightAxis.enabled = true
        rightAxis.labelFont = UIFont.caption1.with(weight: .regular)
        rightAxis.valueFormatter = DefaultAxisValueFormatter(formatter: rightAxisFormatter)

        let marker = XYMarkerView(color: .systemGroupedBackground,
                                  font: UIFont.body.with(weight: .regular),
                                  textColor: .label,
                                  insets: UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8),
                                  xAxisValueFormatter: dayAxisValueFormatter!, units: units)
        marker.chartView = chartView
        marker.minimumSize = CGSize(width: 80, height: 40)
        chartView.marker = marker
    }
    
    @objc func changeSegment(_ segmentedControl: UISegmentedControl) {
        fetchData(useAll: true)
    }
    
    @objc private func hideUnhideTapped() {
        if chartView.data != nil {
            updateChartViewAppearance(hidden: !chartView.isHidden)
        }
    }
    
    private func updateChartViewAppearance(hidden: Bool) {
        chartView.isHidden = hidden
        tableView.tableHeaderView = hidden ? nil : backgroundChartView
        backgroundChartViewHeightAnchor?.constant = hidden ? 0 : chartViewHeight
        backgroundChartViewTopAnchor?.constant = hidden ? 0 : chartViewTopMargin
        barButton.title = chartView.isHidden ? "Show Chart" : "Hide Chart"
    }
    
    // MARK: HealthKit Data
    func fetchData(useAll: Bool) {
        activityIndicator.startAnimating()
        
        backgroundChartView.isHidden = true
        tableView.isHidden = true
        
        guard let segmentType = TimeSegmentType(rawValue: segmentedControl.selectedSegmentIndex) else { return }
        
        viewModel.fetchLineChartData(segmentType: segmentType, useAll: useAll) { [weak self] (lineChartData, maxValue, minValue) in
            guard let weakSelf = self else { return }
            weakSelf.backgroundChartView.isHidden = false
            weakSelf.tableView.isHidden = false
            
            weakSelf.chartView.data = lineChartData
            if minValue > 0 {
                weakSelf.chartView.rightAxis.axisMinimum = 0
            }
//            weakSelf.chartView.rightAxis.axisMaximum = maxValue * 1.1
            weakSelf.dayAxisValueFormatter?.formatType = weakSelf.segmentedControl.selectedSegmentIndex
            weakSelf.chartView.resetZoom()
            weakSelf.chartView.notifyDataSetChanged()
            
            weakSelf.tableView.setContentOffset(weakSelf.tableView.contentOffset, animated: false)
            weakSelf.activityIndicator.stopAnimating()
            weakSelf.tableView.reloadData()
        }
    }
    
}

extension FinanceLineChartDetailViewController: ChartViewDelegate {
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        
    }
    
    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        
    }
    
    func chartScaled(_ chartView: ChartViewBase, scaleX: CGFloat, scaleY: CGFloat) {
        
    }
    
    func chartTranslated(_ chartView: ChartViewBase, dX: CGFloat, dY: CGFloat) {
        
    }
}

extension FinanceLineChartDetailViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let transactions = viewModel.transactions, !transactions.isEmpty {
            return transactions.count
        } else if let accounts = viewModel.accounts, !accounts.isEmpty {
            return accounts.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kFinanceTableViewCell, for: indexPath) as? FinanceTableViewCell ?? FinanceTableViewCell()
        cell.backgroundColor = .secondarySystemGroupedBackground
        if let transactions = viewModel.transactions, !transactions.isEmpty {
            cell.transaction = transactions[indexPath.row]
        } else if let accounts = viewModel.accounts, !accounts.isEmpty {
            cell.account = accounts[indexPath.row]
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let transactions = viewModel.transactions, !transactions.isEmpty {
            let transaction = transactions[indexPath.row]
            showTransactionDetailPresent(transaction: transaction, updateDiscoverDelegate: nil, delegate: nil, users: nil, container: nil, movingBackwards: nil)
        } else if let accounts = viewModel.accounts, !accounts.isEmpty {
            let account = accounts[indexPath.row]
            showAccountDetailPresent(account: account, updateDiscoverDelegate: nil)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

enum TimeSegmentType: Int {
    case day = 0
    case week
    case month
    case year
}
