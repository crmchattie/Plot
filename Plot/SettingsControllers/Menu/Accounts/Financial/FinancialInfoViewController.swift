//
//  FinancialInfoTableViewController.swift
//  Plot
//
//  Created by Cory McHattie on 11/11/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class FinancialInfoViewController: UITableViewController {
    
    var user: MXUser!
    
    deinit {
        print("STORAGE DID DEINIT")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getMXUser()
        
        title = "Financial Information"
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = .none
        extendedLayoutIncludesOpaqueBars = true
    }
    
    func getMXUser() {
        if let currentUser = Auth.auth().currentUser?.uid {
            let reference = Database.database().reference().child(userFinancialEntity).child(currentUser)
            reference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), let value = snapshot.value, let user = try? FirebaseDecoder().decode(MXUser.self, from: value) {
                    self.user = user
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
                        }
                    }
                }
            })
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let identifier = "cell"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .default, reuseIdentifier: identifier)
        
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.backgroundColor = view.backgroundColor
        
        if indexPath.row == 0 {
            cell.textLabel?.text = "Accounts"
            cell.isUserInteractionEnabled = true
            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
        }
        if indexPath.row == 1 {
            cell.textLabel?.text = "Transaction Rules"
            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0, let user = user {
            let destination = FinancialAccountsViewController()
            destination.user = user
            navigationController?.pushViewController(destination, animated: true)
        }
        if indexPath.row == 1, let user = user {
            let destination = FinancialTransactionRulesViewController()
            destination.user = user
            navigationController?.pushViewController(destination, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
