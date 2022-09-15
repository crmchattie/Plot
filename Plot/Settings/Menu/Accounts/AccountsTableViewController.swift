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
    var networkController = NetworkController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        title = "Information"
        view.backgroundColor = .systemGroupedBackground

        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = .none
        extendedLayoutIncludesOpaqueBars = true
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
            cell.textLabel?.text = "Time Information"
            cell.isUserInteractionEnabled = true
            cell.textLabel?.textColor = .label
        }
        else if indexPath.row == 1 {
            cell.textLabel?.text = "Financial Information"
            cell.textLabel?.textColor = .label
        }
//        else if indexPath.row == 2 {
//            cell.textLabel?.text = "Health Information"
//            cell.textLabel?.textColor = .label
//        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            let destination = TimeInfoViewController()
            destination.networkController = networkController
            navigationController?.pushViewController(destination, animated: true)
        }
        else if indexPath.row == 1 {
            let destination = FinancialInfoViewController()
            destination.networkController = networkController
            navigationController?.pushViewController(destination, animated: true)
        }
        
    }
}

