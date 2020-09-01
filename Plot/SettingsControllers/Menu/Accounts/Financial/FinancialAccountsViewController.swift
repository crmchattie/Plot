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
    
    let financialMemberCellID = "financialMemberCellID"
    
    var mxMembers = [MXMember]()
    var mxUser: MXUser!
    var institutionDict = [String: String]()
    
    let viewPlaceholder = ViewPlaceholder()
    
    deinit {
        print("STORAGE DID DEINIT")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        grabMXUser()
        
        title = "Financial Accounts"
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = .none
        extendedLayoutIncludesOpaqueBars = true
        
        tableView.register(FinancialMemberCell.self, forCellReuseIdentifier: financialMemberCellID)
        
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
        Service.shared.getMXMembers(guid: guid, page: "1", records_per_page: "100") { (search, err) in
            if let members = search?.members {
                self.mxMembers = members
                for member in self.mxMembers {
                    self.grabInsitutionalDetails(institution_code: member.institution_code)
                }
                dispatchGroup.leave()
            } else if let member = search?.member {
                self.grabInsitutionalDetails(institution_code: member.institution_code)
                self.mxMembers = [member]
                dispatchGroup.leave()
            } else {
                dispatchGroup.leave()
            }
        }
    }
    
    func grabInsitutionalDetails(institution_code: String) {
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        Service.shared.getMXInstitution(institution_code: institution_code) { (search, err) in
            if let institution = search?.institution {
                self.institutionDict[institution_code] = institution.medium_logo_url
                dispatchGroup.leave()
            } else {
                print("error with search")
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
        let cell = tableView.dequeueReusableCell(withIdentifier: financialMemberCellID, for: indexPath) as? FinancialMemberCell ?? FinancialMemberCell()
        cell.nameLabel.text = mxMembers[indexPath.row].name
        if let imageURL = institutionDict[mxMembers[indexPath.row].institution_code] {
            cell.companyImageView.sd_setImage(with: URL(string: imageURL))
        }
        let status = mxMembers[indexPath.row].connection_status
        if status == "CONNECTED" {
            cell.statusImageView.image =  UIImage(named: "success")
        } else if status == "CREATED" || status == "UPDATED" || status == "DELAYED" || status == "RESUMED" {
            cell.statusImageView.image =  UIImage(named: "updating")
        } else {
            cell.statusImageView.image =  UIImage(named: "failure")
        }
        
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
