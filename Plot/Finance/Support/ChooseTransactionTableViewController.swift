//
//  ChooseTransactionViewController.swift
//  Plot
//
//  Created by Cory McHattie on 10/24/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

protocol ChooseTransactionDelegate: AnyObject {
    func chosenTransaction(transaction: Transaction)
}


class ChooseTransactionTableViewController: UITableViewController {
    
    private let kFinanceTableViewCell = "FinanceTableViewCell"
      
    var existingTransactions = [Transaction]()
    var transactions: [Transaction]!
    var filteredTransactions: [Transaction]!
    
    let transactionFetcher = FinancialTransactionFetcher()
    
    var searchBar: UISearchBar?
    var searchController: UISearchController?
    
    let isodateFormatter = ISO8601DateFormatter()
    let dateFormatterPrint = DateFormatter()
    
    weak var delegate : ChooseTransactionDelegate?
    
    var movingBackwards = false
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.sizeToFit()
        return activityIndicator
    }()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Choose Transaction"
        
        view.addSubview(activityIndicator)
        
        activityIndicator.center = view.center
        activityIndicator.autoresizingMask = [.flexibleTopMargin,
                                              .flexibleBottomMargin,
                                              .flexibleLeftMargin,
                                              .flexibleRightMargin]
        
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = .none
        extendedLayoutIncludesOpaqueBars = true
        tableView.register(FinanceTableViewCell.self, forCellReuseIdentifier: kFinanceTableViewCell)
        
        self.transactions = self.transactions.filter{ !self.existingTransactions.contains($0) && $0.status != .pending && $0.containerID == nil }
        
        
        handleReloadTable()
        setupSearchController()
        
        if navigationItem.leftBarButtonItem != nil {
            navigationItem.leftBarButtonItem?.action = #selector(cancel)
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if movingBackwards {
            let transaction = Transaction(description: "Name", amount: 0.0, created_at: "", guid: "", user_guid: "", type: nil, status: .posted, category: "Uncategorized", top_level_category: "Uncategorized", user_created: true, admin: "")
            self.delegate?.chosenTransaction(transaction: transaction)
        }
    }
    
    @objc fileprivate func cancel() {
        let transaction = Transaction(description: "Name", amount: 0.0, created_at: "", guid: "", user_guid: "", type: nil, status: .posted, category: "Uncategorized", top_level_category: "Uncategorized", user_created: true, admin: "")
        self.delegate?.chosenTransaction(transaction: transaction)
        movingBackwards = false
        dismiss(animated: true, completion: nil)
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
        if transactions != nil {
            activityIndicator.startAnimating()
            DispatchQueue.global(qos: .userInteractive).async {
                self.filteredTransactions = self.transactions
                self.filteredTransactions.sort { (transaction1, transaction2) -> Bool in
                    if transaction1.should_link ?? true == transaction2.should_link ?? true {
                        if let date1 = self.isodateFormatter.date(from: transaction1.transacted_at), let date2 = self.isodateFormatter.date(from: transaction2.transacted_at) {
                            return date1 > date2
                        }
                        return transaction1.description < transaction2.description
                    }
                    return transaction1.should_link ?? true && !(transaction2.should_link ?? true)
                }
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    
    func handleReloadTableAfterSearch() {
        self.activityIndicator.startAnimating()
        if transactions != nil {
            filteredTransactions.sort { (transaction1, transaction2) -> Bool in
                if transaction1.should_link ?? true == transaction2.should_link ?? true {
                    if let date1 = isodateFormatter.date(from: transaction1.transacted_at), let date2 = isodateFormatter.date(from: transaction2.transacted_at) {
                        return date1 > date2
                    }
                    return transaction1.description < transaction2.description
                }
                return transaction1.should_link ?? true && !(transaction2.should_link ?? true)
            }
        }
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.tableView.reloadData()
        }
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let filteredTransactions = filteredTransactions {
            return filteredTransactions.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kFinanceTableViewCell, for: indexPath) as? FinanceTableViewCell ?? FinanceTableViewCell()
        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        if let filteredTransactions = filteredTransactions {
            cell.transaction = filteredTransactions[indexPath.row]
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let transaction = filteredTransactions[indexPath.row]
        delegate?.chosenTransaction(transaction: transaction)
        movingBackwards = false
        if navigationItem.leftBarButtonItem != nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
}

extension ChooseTransactionTableViewController: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {}
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        filteredTransactions = transactions
        handleReloadTable()
        guard #available(iOS 11.0, *) else {
            searchBar.setShowsCancelButton(false, animated: true)
            searchBar.resignFirstResponder()
            return
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if transactions != nil {
            filteredTransactions = searchText.isEmpty ? transactions :
            transactions.filter({ (transaction) -> Bool in
                return transaction.description.lowercased().contains(searchText.lowercased())
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

extension ChooseTransactionTableViewController { /* hiding keyboard */
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
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