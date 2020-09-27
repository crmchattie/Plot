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
    
    let financialAccountCellID = "financialAccountCellID"
    
    var members = [MXMember]()
    var memberAccountsDict = [MXMember: [MXAccount]]()
    var user: MXUser!
    var institutionDict = [String: String]()
    
    let viewPlaceholder = ViewPlaceholder()
    
    deinit {
        print("STORAGE DID DEINIT")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getMXUser()
        
        title = "Financial Accounts"
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = .none
        extendedLayoutIncludesOpaqueBars = true
        
        
        let newAccountBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newAccount))
        navigationItem.rightBarButtonItem = newAccountBarButton
        
    }
    
    func checkIfThereAreAnyResults(isEmpty: Bool) {
        guard isEmpty else {
            viewPlaceholder.remove(from: tableView, priority: .medium)
            return
        }
        viewPlaceholder.add(for: tableView, title: .emptyAccounts, subtitle: .emptyAccounts, priority: .medium, position: .top)
    }
    
    func getMXUser() {
        if let currentUser = Auth.auth().currentUser?.uid {
            let reference = Database.database().reference().child(userFinancialEntity).child(currentUser)
            reference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), let value = snapshot.value, let user = try? FirebaseDecoder().decode(MXUser.self, from: value) {
                    self.user = user
                    self.getMXMembers(guid: user.guid)
                } else if !snapshot.exists() {
                    let identifier = UUID().uuidString
                    Service.shared.createMXUser(id: identifier) { (search, err) in
                        if search?.user != nil {
                            var user = search?.user
                            user!.identifier = identifier
                            if let firebaseUser = try? FirebaseEncoder().encode(user) {
                                reference.setValue(firebaseUser)
                            }
                            self.user = user
                            self.getMXMembers(guid: user!.guid)
                        }
                    }
                }
            })
        }
    }
    
    func getMXMembers(guid: String) {
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        Service.shared.getMXMembers(guid: guid, page: "1", records_per_page: "100") { (search, err) in
            if let members = search?.members {
                self.members = members
                for member in members {
                    dispatchGroup.enter()
                    self.getInsitutionalDetails(institution_code: member.institution_code) {
                        dispatchGroup.leave()
                    }
                    dispatchGroup.enter()
                    self.getMXAccounts(guid: guid, member_guid: member.guid) { (accounts) in
                        self.memberAccountsDict[member] = accounts
                        dispatchGroup.leave()
                    }
                }
            } else if let member = search?.member {
                self.members = [member]
                dispatchGroup.enter()
                self.getInsitutionalDetails(institution_code: member.institution_code) {
                    dispatchGroup.leave()
                }
                dispatchGroup.enter()
                self.getMXAccounts(guid: guid, member_guid: member.guid) { (accounts) in
                    self.memberAccountsDict[member] = accounts
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            self.tableView.reloadData()
        }
    }
    
    func getMXAccounts(guid: String, member_guid: String, completion: @escaping ([MXAccount]) -> ()) {
        Service.shared.getMXMemberAccounts(guid: guid, member_guid: member_guid, page: "1", records_per_page: "100") { (search, err) in
            if search?.accounts != nil {
                var accounts = search?.accounts
                for index in 0...accounts!.count - 1 {
                    if let currentUser = Auth.auth().currentUser?.uid {
                        let reference = Database.database().reference().child(userFinancialAccountsEntity).child(currentUser).child(accounts![index].guid).child("should_link")
                        reference.observeSingleEvent(of: .value, with: { (snapshot) in
                            if snapshot.exists(), let value = snapshot.value, let should_link = value as? Bool {
                                accounts![index].should_link = should_link
                            } else if !snapshot.exists() {
                                reference.setValue(true)
                                accounts![index].should_link = true
                            }
                            
                            if index == accounts!.count - 1 {
                                completion(accounts!)
                            }
                        })
                    }
                }
            } else if search?.account != nil {
                var account = search?.account
                if let currentUser = Auth.auth().currentUser?.uid {
                    let reference = Database.database().reference().child(financialAccountsEntity).child(currentUser).child(account!.guid).child("should_link")
                    reference.observeSingleEvent(of: .value, with: { (snapshot) in
                        if snapshot.exists(), let value = snapshot.value, let should_link = value as? Bool {
                            account!.should_link = should_link
                        } else if !snapshot.exists() {
                            reference.setValue(true)
                            account!.should_link = true
                        }
                        completion([account!])
                    })
                }
            }
        }
    }
    
    func getInsitutionalDetails(institution_code: String, completion: @escaping () -> ()) {
        Service.shared.getMXInstitution(institution_code: institution_code) { (search, err) in
            if let institution = search?.institution {
                self.institutionDict[institution_code] = institution.medium_logo_url
                completion()
            }
        }
    }
    
    @objc func newAccount() {
        if let user = user {
            self.openMXConnect(guid: user.guid, current_member_guid: nil)
        }
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
        if status == "CONNECTED" {
            headerView.statusImageView.image =  UIImage(named: "success")
            headerView.infoLabel.text = "Information is up-to-date"
        } else if status == "CREATED" || status == "UPDATED" || status == "DELAYED" || status == "RESUMED" {
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
            destination.delegate = self
            destination.account = account
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }
        
    }
    
    @objc func viewTapped(_ sender: TapGesture) {
        if let user = user {
            let member = members[sender.item]
            self.openMXConnect(guid: user.guid, current_member_guid: member.guid)
        }
    }
}

extension FinancialAccountsViewController: EndedWebViewDelegate {
    func updateMXMembers() {
        if let user = user {
            getMXMembers(guid: user.guid)
        }
    }
}

extension FinancialAccountsViewController: UpdateAccountDelegate {
    func updateAccount(account: MXAccount) {
        print("updateAccount")
        for (member, accounts) in memberAccountsDict {
            for index in 0...accounts.count - 1 {
                if accounts[index] == account {
                    var accs = accounts
                    accs[index] = account
                    memberAccountsDict[member] = accs
                    tableView.reloadData()
                }
            }
        }
    }
}
