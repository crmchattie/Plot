//
//  FinancialAccountsViewController.swift
//  Plot
//
//  Created by Cory McHattie on 8/18/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class FinancialAccountsViewController: UITableViewController {
    var networkController = NetworkController()
            
    var members = [MXMember]()
    var memberAccountsDict: [MXMember: [MXAccount]] {
        return networkController.financeService.memberAccountsDict
    }
    
    let viewPlaceholder = ViewPlaceholder()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        
        title = "Accounts"
        tableView = UITableView(frame: view.frame, style: .insetGrouped)
        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorStyle = .none
        extendedLayoutIncludesOpaqueBars = true
        
        let barButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newAccount))
        navigationItem.rightBarButtonItem = barButton
        
        members = networkController.financeService.members.sorted(by: {$0.name < $1.name})
                
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(financeUpdated), name: .financeUpdated, object: nil)
    }
    
    @objc fileprivate func financeUpdated() {
        DispatchQueue.main.async {
            self.members = self.networkController.financeService.members.sorted(by: {$0.name < $1.name})
            self.tableView.reloadData()
        }
    }
    
    func checkIfThereAreAnyResults(isEmpty: Bool) {
        guard isEmpty else {
            viewPlaceholder.remove(from: tableView, priority: .medium)
            return
        }
        viewPlaceholder.add(for: tableView, title: .emptyAccounts, subtitle: .emptyAccounts, priority: .medium, position: .top)
    }
    
    @objc func newAccount() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Connect To Account", style: .default, handler: { (_) in
            self.openMXConnect(current_member_guid: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Manually Add Account", style: .default, handler: { (_) in
            let destination = FinanceAccountViewController(networkController: self.networkController)
            self.navigationController?.pushViewController(destination, animated: true)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
    
    func openMXConnect(current_member_guid: String?) {
        let destination = WebViewController()
        destination.current_member_guid = current_member_guid
        destination.controllerTitle = ""
        destination.delegate = self
        let navigationViewController = UINavigationController(rootViewController: destination)
        navigationViewController.modalPresentationStyle = .fullScreen
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if members.count == 0 {
            checkIfThereAreAnyResults(isEmpty: true)
        } else {
            checkIfThereAreAnyResults(isEmpty: false)
        }
        return members.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let member = members[section]
        if let accounts = memberAccountsDict[member] {
            return accounts.count + 1
        }
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        cell.backgroundColor = .secondarySystemGroupedBackground
        let member = members[indexPath.section]
        if indexPath.row == 0 {
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textLabel!.textColor = .label
            cell.textLabel!.font = UIFont.preferredFont(forTextStyle: .body)
            cell.textLabel!.text = members[indexPath.section].name
            cell.detailTextLabel!.textColor = .secondaryLabel
            cell.detailTextLabel!.font = UIFont.preferredFont(forTextStyle: .callout)
            let status = members[indexPath.section].connection_status
            if status == .connected {
                let imgView = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
                imgView.image = UIImage(named: "success")
                cell.accessoryView = imgView
                cell.detailTextLabel!.text = "Information is up-to-date"
            } else if status == .created || status == .updated || status == .delayed || status == .resumed || status == .pending {
                let imgView = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
                imgView.image = UIImage(named: "updating")
                cell.accessoryView = imgView
                cell.detailTextLabel!.text = "Information is updating"
            } else {
                let imgView = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
                imgView.image = UIImage(named: "failure")
                cell.accessoryView = imgView
                cell.detailTextLabel!.text = "Please click to fix connection"
            }
            let viewTap = TapGesture(target: self, action: #selector(self.viewTapped(_:)))
            viewTap.item = indexPath.section
            cell.addGestureRecognizer(viewTap)
        } else {
            if let accounts = memberAccountsDict[member] {
                cell.textLabel!.textColor = .label
                cell.textLabel!.font = UIFont.preferredFont(forTextStyle: .body)
                cell.textLabel!.text = accounts[indexPath.row - 1].name
                cell.detailTextLabel!.textColor = .secondaryLabel
                cell.detailTextLabel!.font = UIFont.preferredFont(forTextStyle: .callout)
                if accounts[indexPath.row - 1].should_link ?? true {
                    cell.detailTextLabel!.text = "Account Linked to Financial Profile"
                    cell.accessoryType = .checkmark
                } else {
                    cell.detailTextLabel!.text = "Account Not Linked to Financial Profile"
                    cell.accessoryType = .none
                }
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let member = members[indexPath.section]
        if let accounts = memberAccountsDict[member] {
            let account = accounts[indexPath.row - 1]
            let destination = FinanceAccountViewController(networkController: self.networkController)
            destination.account = account
            self.navigationController?.pushViewController(destination, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    @objc func viewTapped(_ sender: TapGesture) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { (_) in
            let member = self.members[sender.item]
            self.openMXConnect(current_member_guid: member.guid)
        }))
        
        alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { (_) in
            let member = self.members[sender.item]
            self.networkController.financeService.deleteMXMember(member: member)
            self.members.remove(at: sender.item)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }

        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
}

extension FinancialAccountsViewController: EndedWebViewDelegate {
    func updateMXMembers() {
        networkController.financeService.triggerUpdateMXUser {}
    }
}

//extension FinancialAccountsViewController: UpdateAccountDelegate {
//    func updateAccount(account: MXAccount) {
//        for (member, accounts) in memberAccountsDict {
//            for index in 0...accounts.count - 1 {
//                if accounts[index] == account {
//                    var accs = accounts
//                    accs[index] = account
//                    memberAccountsDict[member] = accs
//                    tableView.reloadData()
//                }
//            }
//        }
//    }
//}
