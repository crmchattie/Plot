//
//  AccountsTableViewController.swift
//  Plot
//
//  Created by Cory McHattie on 8/17/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

//
//  StorageTableViewController.swift
//  Avalon-Print
//
//  Created by Roman Mizin on 7/4/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class AccountsTableViewController: UITableViewController {
    
    deinit {
        print("STORAGE DID DEINIT")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Accounts"
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = .none
        extendedLayoutIncludesOpaqueBars = true
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let identifier = "cell"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .default, reuseIdentifier: identifier)
        
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.backgroundColor = view.backgroundColor
        
        if indexPath.row == 0 {
            cell.textLabel?.text = "Calendar Accounts"
            cell.isUserInteractionEnabled = true
            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
        }
        if indexPath.row == 1 {
            cell.textLabel?.text = "Financial Accounts"
            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
        }
        if indexPath.row == 2 {
            cell.textLabel?.text = "Health Accounts"
            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            
        }
        if indexPath.row == 1 {
            let destination = FinancialAccountsViewController()
            navigationController?.pushViewController(destination, animated: true)
        }
        if indexPath.row == 2 {
            
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

