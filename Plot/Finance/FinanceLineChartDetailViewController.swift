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

fileprivate let chartViewHeight: CGFloat = 200
fileprivate let chartViewTopMargin: CGFloat = 10

protocol UpdateFinancialsDelegate: AnyObject {
    func updateTransactions(transactions: [Transaction])
    func updateAccounts(accounts: [MXAccount])
}

class FinanceLineChartDetailViewController: UIViewController {
    
    weak var delegate : UpdateFinancialsDelegate?
    
    private let kFinanceTableViewCell = "FinanceTableViewCell"
    
    let isodateFormatter = ISO8601DateFormatter()
    let dateFormatterPrint = DateFormatter()
    
    var participants: [String: [User]] = [:]
        
    private var viewModel: FinanceDetailViewModelInterface
    var dayAxisValueFormatter: DayAxisValueFormatter?
    var backgroundChartViewHeightAnchor: NSLayoutConstraint?
    var backgroundChartViewTopAnchor: NSLayoutConstraint?
    
    lazy var backgroundChartView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
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
        //self.viewModel.delegate = self
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
        
        barButton = UIBarButtonItem(title: "Hide Chart", style: .plain, target: self, action: #selector(hideUnhideTapped))
        navigationItem.rightBarButtonItem = barButton
        
        if let accountDetails = viewModel.accountDetails {
            title = accountDetails.name
        } else if let transactionDetails = viewModel.transactionDetails {
            title = transactionDetails.name
        }

        addObservers()
        changeTheme()
        
        view.addSubview(activityIndicator)
        
        view.addSubview(segmentedControl)
        segmentedControl.selectedSegmentIndex = selectedIndex

        backgroundChartView.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        view.addSubview(backgroundChartView)
        backgroundChartView.addSubview(chartView)
        chartView.delegate = self
        
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        
        configureView()
        
        fetchData(useAll: false)
                
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let transactions = viewModel.transactions, !transactions.isEmpty {
            self.delegate?.updateTransactions(transactions: transactions)
        } else if let accounts = viewModel.accounts, !accounts.isEmpty {
            self.delegate?.updateAccounts(accounts: accounts)
        }
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
    }
    
    @objc fileprivate func changeTheme() {
        let theme = ThemeManager.currentTheme()
        view.backgroundColor = theme.generalBackgroundColor
        backgroundChartView.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        chartView.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
    }
    
    private func configureView() {
        
        activityIndicator.center = view.center
        activityIndicator.autoresizingMask = [.flexibleTopMargin,
                                              .flexibleBottomMargin,
                                              .flexibleLeftMargin,
                                              .flexibleRightMargin]
        
        backgroundChartViewHeightAnchor = backgroundChartView.heightAnchor.constraint(equalToConstant: chartViewHeight)
        backgroundChartViewTopAnchor = backgroundChartView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: chartViewTopMargin)
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            segmentedControl.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            segmentedControl.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            
            backgroundChartViewTopAnchor!,
            backgroundChartView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            backgroundChartView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            backgroundChartViewHeightAnchor!,
            
            chartView.topAnchor.constraint(equalTo: backgroundChartView.topAnchor, constant: 16),
            chartView.leftAnchor.constraint(equalTo: backgroundChartView.leftAnchor, constant: 16),
            chartView.rightAnchor.constraint(equalTo: backgroundChartView.rightAnchor, constant: -16),
            chartView.bottomAnchor.constraint(equalTo: backgroundChartView.bottomAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: backgroundChartView.bottomAnchor, constant: 10),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])
        
        tableView.separatorStyle = .none
        tableView.register(FinanceTableViewCell.self, forCellReuseIdentifier: kFinanceTableViewCell)
        tableView.allowsMultipleSelectionDuringEditing = false
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.backgroundColor = view.backgroundColor
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 105
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
        
        viewModel.fetchLineChartData(segmentType: segmentType, useAll: useAll) { [weak self] (lineChartData, maxValue) in
            guard let weakSelf = self else { return }
            weakSelf.backgroundChartView.isHidden = false
            weakSelf.tableView.isHidden = false
            
            weakSelf.chartView.data = lineChartData
            weakSelf.chartView.rightAxis.axisMaximum = maxValue
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
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 0 }
    
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
        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
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
            let destination = FinanceTransactionViewController(networkController: networkController)
            destination.transaction = transaction
            destination.delegate = self
            ParticipantsFetcher.getParticipants(forTransaction: transaction) { (participants) in
                destination.selectedFalconUsers = participants
                self.navigationController?.pushViewController(destination, animated: true)
            }
        } else if let accounts = viewModel.accounts, !accounts.isEmpty {
            let account = accounts[indexPath.row]
            let destination = FinanceAccountViewController(networkController: networkController)
            destination.account = account
            destination.delegate = self
            ParticipantsFetcher.getParticipants(forAccount: account) { (participants) in
                destination.selectedFalconUsers = participants
                self.navigationController?.pushViewController(destination, animated: true)
            }
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

extension FinanceLineChartDetailViewController: UpdateAccountDelegate {
    func updateAccount(account: MXAccount) {
        if let index = viewModel.accounts!.firstIndex(of: account) {
            viewModel.accounts![index] = account
            fetchData(useAll: true)
        }
    }
}

extension FinanceLineChartDetailViewController: UpdateTransactionDelegate {
    func updateTransaction(transaction: Transaction) {
        if let index = viewModel.transactions!.firstIndex(of: transaction) {
            viewModel.transactions![index] = transaction
            fetchData(useAll: true)
        }
    }
}
