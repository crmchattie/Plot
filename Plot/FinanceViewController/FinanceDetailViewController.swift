//
//  FinanceDetailViewController.swift
//  Plot
//
//  Created by Cory McHattie on 9/16/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

fileprivate let chartViewHeight: CGFloat = 260
fileprivate let chartViewTopMargin: CGFloat = 10

protocol UpdateFinancialsDelegate: class {
    func updateTransactions(transactions: [Transaction])
    func updateAccounts(accounts: [MXAccount])
}

import UIKit
import Firebase
import Charts

class FinanceDetailViewController: UIViewController {
    
    weak var delegate : UpdateFinancialsDelegate?
    
    private let kFinanceTableViewCell = "FinanceTableViewCell"
    
    var user: MXUser!
    
    var filteredTransactions: [Transaction]!
    var filteredAccounts: [MXAccount]!
    
    var searchBar: UISearchBar?
    var searchController: UISearchController?
    
    let isodateFormatter = ISO8601DateFormatter()
    let dateFormatterPrint = DateFormatter()
    
    var users = [User]()
    var filteredUsers = [User]()
    
    var participants: [String: [User]] = [:]
    
    private var viewModel: FinanceDetailViewModelInterface
    var dayAxisValueFormatter: DayAxisValueFormatter?
    var chartViewHeightAnchor: NSLayoutConstraint?
    var chartViewTopAnchor: NSLayoutConstraint?
    
    lazy var chartView: LineChartView = {
        let chartView = LineChartView()
        chartView.translatesAutoresizingMaskIntoConstraints = false
        return chartView
    }()
    
    lazy var segmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(items: ["D", "W", "M", "Y"])
        segmentedControl.addTarget(self, action: #selector(changeSegment(_:)), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        return segmentedControl
    }()
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return tableView
    }()
    
    let barButton = UIBarButtonItem(title: "Hide Chart", style: .plain, target: self, action: #selector(hideUnhideTapped))
    
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
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        navigationItem.rightBarButtonItem = barButton
        
        if let accountDetails = viewModel.accountDetails {
            title = accountDetails.name
        } else if let transactionDetails = viewModel.transactionDetails {
            title = transactionDetails.name
        }

        addObservers()
        changeTheme()
        
        view.addSubview(chartView)
        chartView.delegate = self
        
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        
        view.addSubview(segmentedControl)
        segmentedControl.selectedSegmentIndex = 0
        
        configureView()
        configureChart()
        
        fetchData()
        
//        setupSearchController()
//        handleReloadTable()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let transactions = viewModel.transactions {
            self.delegate?.updateTransactions(transactions: transactions)
        } else if let accounts = viewModel.accounts {
            self.delegate?.updateAccounts(accounts: accounts)
        }
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
    }
    
    @objc fileprivate func changeTheme() {
        let theme = ThemeManager.currentTheme()
        view.backgroundColor = theme.generalBackgroundColor
    }
    
    private func configureView() {
        
        chartViewHeightAnchor = chartView.heightAnchor.constraint(equalToConstant: chartViewHeight)
        chartViewTopAnchor = chartView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: chartViewTopMargin)
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            segmentedControl.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            segmentedControl.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            
            chartViewTopAnchor!,
            chartView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            chartView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            chartViewHeightAnchor!,
            
            tableView.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 10),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])
        
        tableView.separatorStyle = .none
        tableView.backgroundColor = view.backgroundColor
        extendedLayoutIncludesOpaqueBars = true
        tableView.register(FinanceTableViewCell.self, forCellReuseIdentifier: kFinanceTableViewCell)
        tableView.allowsMultipleSelectionDuringEditing = false
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.backgroundColor = view.backgroundColor
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 105
    }
    
    func configureChart() {
        
        chartView.chartDescription?.enabled = false
        chartView.dragEnabled = true
        chartView.setScaleEnabled(true)
        chartView.pinchZoomEnabled = true
        
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = .systemFont(ofSize: 10)
        xAxis.setLabelCount(6, force: true)
        dayAxisValueFormatter = DayAxisValueFormatter(chart: chartView)
        dayAxisValueFormatter?.formatType = segmentedControl.selectedSegmentIndex
        xAxis.valueFormatter = dayAxisValueFormatter
        xAxis.drawGridLinesEnabled = false
        xAxis.avoidFirstLastClippingEnabled = true

        let rightAxis = chartView.rightAxis
        rightAxis.removeAllLimitLines()
        rightAxis.axisMinimum = 0
        rightAxis.drawLimitLinesBehindDataEnabled = true
        rightAxis.drawGridLinesEnabled = false
        
        chartView.leftAxis.enabled = false

        let marker = BalloonMarker(color: UIColor(white: 180/255, alpha: 1),
                                   font: .systemFont(ofSize: 12),
                                   textColor: .white,
                                   insets: UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8))
        marker.chartView = chartView
        marker.minimumSize = CGSize(width: 80, height: 40)
        chartView.marker = marker
        
        chartView.legend.form = .line
    }
    
    fileprivate func setupSearchController() {
        
        if #available(iOS 11.0, *) {
            searchController = UISearchController(searchResultsController: nil)
            searchController?.searchResultsUpdater = self
            searchController?.obscuresBackgroundDuringPresentation = false
            searchController?.searchBar.delegate = self
            searchController?.definesPresentationContext = true
            navigationItem.searchController = searchController
        } else {
            searchBar = UISearchBar()
            searchBar?.delegate = self
            searchBar?.placeholder = "Search"
            searchBar?.searchBarStyle = .minimal
            searchBar?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
            tableView.tableHeaderView = searchBar
        }
    }
    
    func handleReloadTable() {
        if viewModel.transactions != nil {
            viewModel.transactions!.sort { (transaction1, transaction2) -> Bool in
                if let date1 = isodateFormatter.date(from: transaction1.transacted_at), let date2 = isodateFormatter.date(from: transaction2.transacted_at) {
                    return date1 > date2
                }
                return transaction1.description < transaction2.description
            }
            filteredTransactions = viewModel.transactions
        } else if viewModel.accounts != nil {
            viewModel.accounts!.sort { (account1, account2) -> Bool in
                return account1.name < account2.name
            }
            filteredAccounts = viewModel.accounts
        }
        tableView.reloadData()
        
    }
    
    @objc func changeSegment(_ segmentedControl: UISegmentedControl) {
        fetchData()
    }
    
    @objc private func hideUnhideTapped() {
        barButton.title = chartView.isHidden ? "Show Chart" : "Hide Chart"
        updateChartViewAppearance(hidden: !chartView.isHidden)
    }
    
    private func updateChartViewAppearance(hidden: Bool) {
        chartView.isHidden = hidden
        chartViewHeightAnchor?.constant = hidden ? 0 : chartViewHeight
        chartViewTopAnchor?.constant = hidden ? 0 : chartViewTopMargin
    }
    
    // MARK: HealthKit Data
    func fetchData() {
        guard let segmentType = TimeSegmentType(rawValue: segmentedControl.selectedSegmentIndex) else { return }
        
        viewModel.fetchChartData(for: segmentType) { [weak self] (data, maxValue) in
            guard let weakSelf = self else { return }
            
            weakSelf.chartView.data = data
            weakSelf.chartView.rightAxis.axisMaximum = maxValue
            weakSelf.dayAxisValueFormatter?.formatType = weakSelf.segmentedControl.selectedSegmentIndex
            weakSelf.chartView.resetZoom()
            weakSelf.chartView.animate(xAxisDuration: 1)
            weakSelf.updateChartViewAppearance(hidden: data == nil)
            
            weakSelf.tableView.setContentOffset(weakSelf.tableView.contentOffset, animated: false)
            weakSelf.tableView.reloadData()
        }
    }
    
    
    func handleReloadTableAfterSearch() {
        if viewModel.transactions != nil {
            filteredTransactions.sort { (transaction1, transaction2) -> Bool in
                return transaction1.description < transaction2.description
            }
        } else if viewModel.accounts != nil {
            filteredAccounts.sort { (account1, account2) -> Bool in
                return account1.name < account2.name
            }
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
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
}

extension FinanceDetailViewController: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        
    }
    
    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        
    }
    
    func chartScaled(_ chartView: ChartViewBase, scaleX: CGFloat, scaleY: CGFloat) {
        
    }
    
    func chartTranslated(_ chartView: ChartViewBase, dX: CGFloat, dY: CGFloat) {
        
    }
}

extension FinanceDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let transactions = viewModel.transactions {
            return transactions.count
        } else if let accounts = viewModel.accounts {
            return accounts.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                        
        let cell = tableView.dequeueReusableCell(withIdentifier: kFinanceTableViewCell, for: indexPath) as? FinanceTableViewCell ?? FinanceTableViewCell()
        cell.selectionStyle = .none
        if let transactions = viewModel.transactions {
            cell.transaction = transactions[indexPath.row]
        } else if let accounts = viewModel.accounts {
            cell.account = accounts[indexPath.row]
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let transactions = viewModel.transactions {
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
        } else if let accounts = viewModel.accounts {
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

extension FinanceDetailViewController: UpdateAccountDelegate {
    func updateAccount(account: MXAccount) {
        if let index = viewModel.accounts!.firstIndex(of: account) {
            viewModel.accounts![index] = account
            handleReloadTable()
        }
    }
}

extension FinanceDetailViewController: UpdateTransactionDelegate {
    func updateTransaction(transaction: Transaction) {
        if let index = viewModel.transactions!.firstIndex(of: transaction) {
            viewModel.transactions![index] = transaction
            handleReloadTable()
        }
    }
}

extension FinanceDetailViewController: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {}
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        filteredAccounts = viewModel.accounts
        filteredTransactions = viewModel.transactions
        handleReloadTable()
        guard #available(iOS 11.0, *) else {
            searchBar.setShowsCancelButton(false, animated: true)
            searchBar.resignFirstResponder()
            return
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if viewModel.transactions != nil {
            filteredTransactions = searchText.isEmpty ? viewModel.transactions :
                viewModel.transactions!.filter({ (transaction) -> Bool in
                return transaction.description.lowercased().contains(searchText.lowercased())
            })
        } else if filteredAccounts != nil {
            filteredAccounts = searchText.isEmpty ? viewModel.accounts :
                viewModel.accounts!.filter({ (account) -> Bool in
                return account.name.lowercased().contains(searchText.lowercased())
            })
        }
        handleReloadTableAfterSearch()
    }

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
        guard #available(iOS 11.0, *) else {
            searchBar.setShowsCancelButton(true, animated: true)
            return true
        }
        return true
    }
}

extension FinanceDetailViewController { /* hiding keyboard */
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        if #available(iOS 11.0, *) {
            searchController?.searchBar.endEditing(true)
        } else {
            self.searchBar?.endEditing(true)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        setNeedsStatusBarAppearanceUpdate()
        if #available(iOS 11.0, *) {
            searchController?.searchBar.endEditing(true)
        } else {
            self.searchBar?.endEditing(true)
        }
    }
}
