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
    var networkController = NetworkController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        
        title = "Financial Information"
        tableView = UITableView(frame: tableView.frame, style: .insetGrouped)
        tableView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.separatorStyle = .none
        extendedLayoutIncludesOpaqueBars = true
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .default, reuseIdentifier: identifier)
        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        cell.textLabel?.adjustsFontForContentSizeCategory = true        
        if indexPath.row == 0 {
            cell.textLabel?.text = "Accounts"
            cell.isUserInteractionEnabled = true
            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
        }
        else if indexPath.row == 1 {
            cell.textLabel?.text = "Transaction Rules"
            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            let destination = FinancialAccountsViewController()
            destination.networkController = self.networkController
            self.navigationController?.pushViewController(destination, animated: true)
        }
        if indexPath.row == 1 {
            let destination = FinancialTransactionRulesViewController()
            destination.networkController = networkController
            navigationController?.pushViewController(destination, animated: true)
        }
    }
}
