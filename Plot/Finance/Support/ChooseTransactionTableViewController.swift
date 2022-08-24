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
        
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Choose Transaction"
        
        self.transactions = self.transactions.filter{ !self.existingTransactions.contains($0) && $0.status != .pending && $0.containerID == nil }
        filteredTransactions = transactions
        
        configureView()
        setupSearchController()
                
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if movingBackwards {
            let transaction = Transaction(description: "Name", amount: 0.0, created_at: "", guid: "", user_guid: "", type: nil, status: .posted, category: "Uncategorized", top_level_category: "Uncategorized", user_created: true, admin: "")
            self.delegate?.chosenTransaction(transaction: transaction)
        }
    }
    
    fileprivate func configureView() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = .none
        extendedLayoutIncludesOpaqueBars = true
        tableView.register(FinanceTableViewCell.self, forCellReuseIdentifier: kFinanceTableViewCell)
        
        if navigationItem.leftBarButtonItem != nil {
            navigationItem.leftBarButtonItem?.action = #selector(cancel)
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
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            searchBar = UISearchBar()
            searchBar?.delegate = self
            searchBar?.placeholder = "Search"
            searchBar?.searchBarStyle = .minimal
            searchBar?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
            tableView.tableHeaderView = searchBar
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.tintColor = ThemeManager.currentTheme().generalBackgroundColor
        return view
        
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
        searchBar.resignFirstResponder()
        filteredTransactions = transactions
        tableView.reloadData()

    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if transactions != nil {
            filteredTransactions = searchText.isEmpty ? transactions :
            transactions.filter({ (transaction) -> Bool in
                return transaction.description.lowercased().contains(searchText.lowercased())
            })
        }
        tableView.reloadData()
    }

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
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
