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
    
    var mxMembers = [MXMember]()
    var mxUser: MXUser!
    
    let viewPlaceholder = ViewPlaceholder()
    
    deinit {
        print("STORAGE DID DEINIT")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Financial Accounts"
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = .none
        extendedLayoutIncludesOpaqueBars = true
        
        let newAccountBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newAccount))
        navigationItem.rightBarButtonItem = newAccountBarButton
        
        grabMXUser()
    }
    
    func checkIfThereAreAnyResults(isEmpty: Bool) {
        guard isEmpty else {
            viewPlaceholder.remove(from: tableView, priority: .medium)
            return
        }
        viewPlaceholder.add(for: tableView, title: .emptyAccounts, subtitle: .emptyAccounts, priority: .medium, position: .top)
    }
    
    func grabMXUser() {
        if let currentUser = Auth.auth().currentUser?.uid {
            let mxIDReference = Database.database().reference().child(usersFinancialEntity).child(currentUser)
            mxIDReference.observe(.value, with: { (snapshot) in
                if snapshot.exists(), let value = snapshot.value {
                    if let user = try? FirebaseDecoder().decode(MXUser.self, from: value) {
                        self.mxUser = user
                        self.grabMXMembers(guid: user.guid)
                    }
                } else if !snapshot.exists() {
                    let identifier = UUID().uuidString
                    Service.shared.createMXUser(id: identifier) { (search, err) in
                        if search?.user != nil {
                            var user = search?.user
                            user!.identifier = identifier
                            if let firebaseUser = try? FirebaseEncoder().encode(user) {
                                mxIDReference.setValue(firebaseUser)
                            }
                            self.mxUser = user
                            self.grabMXMembers(guid: user!.guid)
                        }
                    }
                }
            })
        }
    }
    
    func grabMXMembers(guid: String) {
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        Service.shared.getMXMembers(guid: guid) { (search, err) in
            if let members = search?.members {
                self.mxMembers = members
                dispatchGroup.leave()
            } else if let member = search?.member {
                self.mxMembers = [member]
                dispatchGroup.leave()
            } else {
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: .main) {
            self.tableView.reloadData()
        }
    }
    
    @objc func newAccount() {
        if let user = mxUser {
            self.openMXConnect(guid: user.guid)
        }
    }
    
    func openMXConnect(guid: String) {
        Service.shared.getMXConnectURL(guid: guid, current_member_guid: nil) { (search, err) in
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
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if mxMembers.count == 0 {
            checkIfThereAreAnyResults(isEmpty: true)
        } else {
            checkIfThereAreAnyResults(isEmpty: false)
        }
        return mxMembers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .default, reuseIdentifier: identifier)
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.backgroundColor = view.backgroundColor
        cell.textLabel?.text = mxMembers[indexPath.row].name
        cell.isUserInteractionEnabled = true
        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension FinancialAccountsViewController: EndedWebViewDelegate {
    func updateMXMembers() {
        if let user = mxUser {
            grabMXMembers(guid: user.guid)
        }
    }
}
