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
    
    let financialAccountCellID = "financialAccountCellID"
    
    var members: [MXMember] {
        return networkController.financeService.members
    }
    var institutionDict: [String: String] {
        return networkController.financeService.institutionDict
    }
    var memberAccountsDict: [MXMember: [MXAccount]] {
        return networkController.financeService.memberAccountsDict
    }
    
    let viewPlaceholder = ViewPlaceholder()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        
        title = "Accounts"
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView = UITableView(frame: view.frame, style: .insetGrouped)
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = .none
        extendedLayoutIncludesOpaqueBars = true
        
        let barButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newAccount))
        navigationItem.rightBarButtonItem = barButton
        
    }
    
    @objc fileprivate func newAccount() {
        if let mxUser = self.networkController.financeService.mxUser {
            self.openMXConnect(guid: mxUser.guid, current_member_guid: nil)
        } else {
            self.networkController.financeService.getMXUser { (mxUser) in
                if let mxUser = self.networkController.financeService.mxUser {
                    self.openMXConnect(guid: mxUser.guid, current_member_guid: nil)
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(financeUpdated), name: .financeUpdated, object: nil)
    }
    
    @objc fileprivate func financeUpdated() {
        DispatchQueue.main.async {
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
    
    func openMXConnect(guid: String, current_member_guid: String?) {
        Service.shared.getMXConnectURL(guid: guid, current_member_guid: current_member_guid ?? nil) { (search, err) in
            if let url = search?.user?.connect_widget_url {
                DispatchQueue.main.async {
                    let destination = WebViewController()
                    destination.urlString = url
                    destination.controllerTitle = ""
                    destination.delegate = self
                    let navigationViewController = UINavigationController(rootViewController: destination)
                    navigationViewController.modalPresentationStyle = .fullScreen
                    self.present(navigationViewController, animated: true, completion: nil)
                }
            }
        }
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
            return accounts.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = FinancialMemberView()
        headerView.nameLabel.text = members[section].name
        if let imageURL = institutionDict[members[section].institution_code] {
            headerView.companyImageView.sd_setImage(with: URL(string: imageURL))
        }
        let status = members[section].connection_status
        print("connection_status \(status)")
        if status == .connected {
            headerView.statusImageView.image =  UIImage(named: "success")
            headerView.infoLabel.text = "Information is up-to-date"
        } else if status == .created || status == .updated || status == .delayed || status == .resumed || status == .pending {
            headerView.statusImageView.image =  UIImage(named: "updating")
            headerView.infoLabel.text = "Information is updating"
        } else {
            headerView.statusImageView.image =  UIImage(named: "failure")
            headerView.infoLabel.text = "Please click to fix connection"
        }
        let viewTap = TapGesture(target: self, action: #selector(self.viewTapped(_:)))
        viewTap.item = section
        headerView.addGestureRecognizer(viewTap)
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 80
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        cell.selectionStyle = .none
        let member = members[indexPath.section]
        if let accounts = memberAccountsDict[member] {
            cell.textLabel!.textColor = ThemeManager.currentTheme().generalTitleColor
            cell.textLabel!.font = UIFont.preferredFont(forTextStyle: .body)
            cell.textLabel!.text = accounts[indexPath.row].name
            cell.detailTextLabel!.textColor = ThemeManager.currentTheme().generalSubtitleColor
            cell.detailTextLabel!.font = UIFont.preferredFont(forTextStyle: .callout)
            if accounts[indexPath.row].should_link ?? true {
                cell.detailTextLabel!.text = "Account Linked to Financial Profile"
                cell.accessoryType = .checkmark
            } else {
                cell.detailTextLabel!.text = "Account Not Linked to Financial Profile"
                cell.accessoryType = .none
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let member = members[indexPath.section]
        if let accounts = memberAccountsDict[member] {
            let account = accounts[indexPath.row]
            let destination = FinanceAccountViewController()
            destination.account = account
            self.navigationController?.pushViewController(destination, animated: true)
        }
        
    }
    
    @objc func viewTapped(_ sender: TapGesture) {
        let member = members[sender.item]
        if let mxUser = self.networkController.financeService.mxUser {
            self.openMXConnect(guid: mxUser.guid, current_member_guid: member.guid)
        } else {
            self.networkController.financeService.getMXUser { (mxUser) in
                if let mxUser = self.networkController.financeService.mxUser {
                    self.openMXConnect(guid: mxUser.guid, current_member_guid: member.guid)
                }
            }
        }
    }
}

extension FinancialAccountsViewController: EndedWebViewDelegate {
    func updateMXMembers() {
        networkController.financeService.grabFinances {}
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
