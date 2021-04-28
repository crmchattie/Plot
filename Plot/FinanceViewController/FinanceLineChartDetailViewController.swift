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

protocol UpdateFinancialsDelegate: class {
    func updateTransactions(transactions: [Transaction])
    func updateAccounts(accounts: [MXAccount])
}

class FinanceLineChartDetailViewController: UIViewController {
    
    weak var delegate : UpdateFinancialsDelegate?
    
    private let kFinanceTableViewCell = "FinanceTableViewCell"
    
    let isodateFormatter = ISO8601DateFormatter()
    let dateFormatterPrint = DateFormatter()
    
    var users = [User]()
    var filteredUsers = [User]()
    
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
    
    lazy var units = "currency"
    
    var selectedIndex = 2
    
    init(viewModel: FinanceDetailViewModelInterface) {
        self.viewModel = viewModel
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
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for:.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layoutIfNeeded()
        
        barButton = UIBarButtonItem(title: "Hide Chart", style: .plain, target: self, action: #selector(hideUnhideTapped))
        navigationItem.rightBarButtonItem = barButton
        
        if let accountDetails = viewModel.accountDetails {
            title = accountDetails.name
        } else if let transactionDetails = viewModel.transactionDetails {
            title = transactionDetails.name
        }

        addObservers()
        changeTheme()
        
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
        
        fetchData()
                
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
        
        backgroundChartViewHeightAnchor = backgroundChartView.heightAnchor.constraint(equalToConstant: chartViewHeight)
        backgroundChartViewTopAnchor = backgroundChartView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: chartViewTopMargin)
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
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
    
//    func configureChart() {
//        chartView.defaultChartStyle()
//        chartView.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//        chartView.chartDescription?.enabled = false
//        chartView.dragEnabled = false
//        chartView.setScaleEnabled(false)
//        chartView.pinchZoomEnabled = false
//
//        let xAxis = chartView.xAxis
//        xAxis.labelPosition = .bottom
//        xAxis.labelFont = .systemFont(ofSize: 10)
//        xAxis.setLabelCount(6, force: true)
//        dayAxisValueFormatter = DayAxisValueFormatter(chart: chartView)
//        xAxis.valueFormatter = dayAxisValueFormatter
//        xAxis.drawGridLinesEnabled = false
//        xAxis.avoidFirstLastClippingEnabled = true
//
//        let rightAxisFormatter = NumberFormatter()
//        rightAxisFormatter.numberStyle = .currency
//        rightAxisFormatter.maximumFractionDigits = 0
//        let rightAxis = chartView.rightAxis
//        rightAxis.removeAllLimitLines()
//        rightAxis.drawLimitLinesBehindDataEnabled = true
//        rightAxis.drawGridLinesEnabled = false
//        rightAxis.valueFormatter = DefaultAxisValueFormatter(formatter: rightAxisFormatter)
//
//        chartView.leftAxis.enabled = false
//
//        let marker = XYMarkerView(color: ThemeManager.currentTheme().generalSubtitleColor,
//                                  font: .systemFont(ofSize: 12),
//                                  textColor: .white,
//                                  insets: UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8),
//                                  xAxisValueFormatter: dayAxisValueFormatter!, units: units)
//        marker.chartView = chartView
//        marker.minimumSize = CGSize(width: 80, height: 40)
//        chartView.marker = marker
//
//        chartView.legend.form = .line
//        chartView.legend.enabled = false
//    }
    
    @objc func changeSegment(_ segmentedControl: UISegmentedControl) {
        fetchData()
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
    func fetchData() {
        guard let segmentType = TimeSegmentType(rawValue: segmentedControl.selectedSegmentIndex) else { return }
        
        viewModel.fetchLineChartData(for: segmentType) { [weak self] (lineChartData, maxValue) in
            guard let weakSelf = self else { return }
            weakSelf.chartView.data = lineChartData
            weakSelf.chartView.rightAxis.axisMaximum = maxValue
            weakSelf.dayAxisValueFormatter?.formatType = weakSelf.segmentedControl.selectedSegmentIndex
            weakSelf.chartView.resetZoom()
            weakSelf.chartView.notifyDataSetChanged()
            
            weakSelf.tableView.setContentOffset(weakSelf.tableView.contentOffset, animated: false)
            weakSelf.tableView.reloadData()
        }
    }
    
    func getParticipants(transaction: Transaction?, account: MXAccount?, completion: @escaping ([User])->()) {
        if let transaction = transaction, let participantsIDs = transaction.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid {
            let group = DispatchGroup()
            let ID = transaction.guid
            let olderParticipants = self.participants[ID]
            var participants: [User] = []
            for id in participantsIDs {
                if transaction.admin == currentUserID && id == currentUserID {
                    continue
                }
                
                if let first = olderParticipants?.filter({$0.id == id}).first {
                    participants.append(first)
                    continue
                }
                
                group.enter()
                let participantReference = Database.database().reference().child("users").child(id)
                participantReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), var dictionary = snapshot.value as? [String: AnyObject] {
                        dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                        let user = User(dictionary: dictionary)
                        participants.append(user)
                    }
                    
                    group.leave()
                })
            }
            
            group.notify(queue: .main) {
                self.participants[ID] = participants
                completion(participants)
            }
        } else if let account = account, let participantsIDs = account.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid {
            let group = DispatchGroup()
            let ID = account.guid
            let olderParticipants = self.participants[ID]
            var participants: [User] = []
            for id in participantsIDs {
                if account.admin == currentUserID && id == currentUserID {
                    continue
                }
                
                if let first = olderParticipants?.filter({$0.id == id}).first {
                    participants.append(first)
                    continue
                }
                
                group.enter()
                let participantReference = Database.database().reference().child("users").child(id)
                participantReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), var dictionary = snapshot.value as? [String: AnyObject] {
                        dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                        let user = User(dictionary: dictionary)
                        participants.append(user)
                    }
                    
                    group.leave()
                })
            }
            
            group.notify(queue: .main) {
                self.participants[ID] = participants
                completion(participants)
            }
        } else {
            let participants: [User] = []
            completion(participants)
        }
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
            let destination = FinanceTransactionViewController()
            destination.transaction = transaction
            destination.users = users
            destination.filteredUsers = filteredUsers
            destination.delegate = self
            self.getParticipants(transaction: transaction, account: nil) { (participants) in
                destination.selectedFalconUsers = participants
                self.navigationController?.pushViewController(destination, animated: true)
            }
        } else if let accounts = viewModel.accounts, !accounts.isEmpty {
            let account = accounts[indexPath.row]
            let destination = FinanceAccountViewController()
            destination.account = account
            destination.users = users
            destination.filteredUsers = filteredUsers
            destination.delegate = self
            self.getParticipants(transaction: nil, account: account) { (participants) in
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
            fetchData()
        }
    }
}

extension FinanceLineChartDetailViewController: UpdateTransactionDelegate {
    func updateTransaction(transaction: Transaction) {
        if let index = viewModel.transactions!.firstIndex(of: transaction) {
            viewModel.transactions![index] = transaction
            fetchData()
        }
    }
}
