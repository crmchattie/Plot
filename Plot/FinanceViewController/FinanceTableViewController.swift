//
//  FinanceTableViewController.swift
//  Plot
//
//  Created by Cory McHattie on 9/16/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

protocol UpdateFinancialsDelegate: class {
    func updateTransactions(transactions: [Transaction])
    func updateAccounts(accounts: [MXAccount])
}

import UIKit
import Firebase

class FinanceTableViewController: UITableViewController {
    
    weak var delegate : UpdateFinancialsDelegate?
    
    private let kFinanceTableViewCell = "FinanceTableViewCell"
    
    var transactions: [Transaction]!
    var accounts: [MXAccount]!
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
        
    deinit {
        print("STORAGE DID DEINIT")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = .none
        extendedLayoutIncludesOpaqueBars = true
        tableView.register(FinanceTableViewCell.self, forCellReuseIdentifier: kFinanceTableViewCell)
        setupSearchController()
        handleReloadTable()
        
    }
    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        if let transactions = transactions {
//            self.delegate?.updateTransactions(transactions: transactions)
//        } else if let accounts = accounts {
//            self.delegate?.updateAccounts(accounts: accounts)
//        }
//    }
    
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
            transactions.sort { (transaction1, transaction2) -> Bool in
                if let date1 = isodateFormatter.date(from: transaction1.transacted_at), let date2 = isodateFormatter.date(from: transaction2.transacted_at) {
                    return date1 > date2
                }
                return transaction1.description < transaction2.description
            }
            filteredTransactions = transactions
        } else if accounts != nil {
            accounts.sort { (account1, account2) -> Bool in
                return account1.name < account2.name
            }
            filteredAccounts = accounts
        }
        tableView.reloadData()
        
    }
    
    
    func handleReloadTableAfterSearch() {
        if transactions != nil {
            filteredTransactions.sort { (transaction1, transaction2) -> Bool in
                return transaction1.description < transaction2.description
            }
        } else if accounts != nil {
            filteredAccounts.sort { (account1, account2) -> Bool in
                return account1.name < account2.name
            }
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let filteredTransactions = filteredTransactions {
            title = "Transactions"
            return filteredTransactions.count
        } else if let filteredAccounts = filteredAccounts {
            title = "Accounts"
            return filteredAccounts.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                        
        let cell = tableView.dequeueReusableCell(withIdentifier: kFinanceTableViewCell, for: indexPath) as? FinanceTableViewCell ?? FinanceTableViewCell()
        cell.selectionStyle = .none
        if let filteredTransactions = filteredTransactions {
            cell.transaction = filteredTransactions[indexPath.row]
        } else if let filteredAccounts = filteredAccounts {
            cell.account = filteredAccounts[indexPath.row]
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let filteredTransactions = filteredTransactions {
            let transaction = filteredTransactions[indexPath.row]
            let destination = FinanceTransactionViewController()
            destination.transaction = transaction
            destination.user = user
            destination.users = users
            destination.filteredUsers = filteredUsers
            destination.delegate = self
            self.getParticipants(transaction: transaction, account: nil) { (participants) in
                destination.selectedFalconUsers = participants
                let navigationViewController = UINavigationController(rootViewController: destination)
                self.present(navigationViewController, animated: true, completion: nil)
            }
        } else if let filteredAccounts = filteredAccounts {
            let account = filteredAccounts[indexPath.row]
            let destination = FinanceAccountViewController()
            destination.account = account
            destination.user = user
            destination.users = users
            destination.filteredUsers = filteredUsers
            destination.delegate = self
            self.getParticipants(transaction: nil, account: account) { (participants) in
                destination.selectedFalconUsers = participants
                let navigationViewController = UINavigationController(rootViewController: destination)
                self.present(navigationViewController, animated: true, completion: nil)
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
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

extension FinanceTableViewController: UpdateAccountDelegate {
    func updateAccount(account: MXAccount) {
        if let index = accounts.firstIndex(of: account) {
            accounts[index] = account
            handleReloadTable()
        }
    }
}

extension FinanceTableViewController: UpdateTransactionDelegate {
    func updateTransaction(transaction: Transaction) {
        if let index = transactions.firstIndex(of: transaction) {
            transactions[index] = transaction
            handleReloadTable()
        }
    }
}

extension FinanceTableViewController: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {}
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        filteredAccounts = accounts
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
        } else if filteredAccounts != nil {
            filteredAccounts = searchText.isEmpty ? accounts :
            accounts.filter({ (account) -> Bool in
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

extension FinanceTableViewController { /* hiding keyboard */
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
