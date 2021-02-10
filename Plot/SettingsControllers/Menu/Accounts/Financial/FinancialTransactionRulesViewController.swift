//
//  FinancialTransactionRulesViewController.swift
//  Plot
//
//  Created by Cory McHattie on 11/11/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

class FinancialTransactionRulesViewController: UITableViewController {
    var networkController = NetworkController()
    
    let financialAccountCellID = "financialAccountCellID"
    
    var transactionRules: [TransactionRule] {
        networkController.financeService.transactionRules
    }
    
    let viewPlaceholder = ViewPlaceholder()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        
        title = "Transaction Rules"
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView = UITableView(frame: tableView.frame, style: .insetGrouped)
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = .none
        extendedLayoutIncludesOpaqueBars = true
        
        let barButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newTransactionRule))
        navigationItem.rightBarButtonItem = barButton
        
    }
    
    func checkIfThereAreAnyResults(isEmpty: Bool) {
        guard isEmpty else {
            viewPlaceholder.remove(from: tableView, priority: .medium)
            return
        }
        viewPlaceholder.add(for: tableView, title: .emptyTransactionRules, subtitle: .emptyTransactionRules, priority: .medium, position: .top)
    }
    
    @objc func newTransactionRule() {
        let destination = FinanceTransactionRuleViewController()
        let navigationViewController = UINavigationController(rootViewController: destination)
        self.present(navigationViewController, animated: true, completion: nil)

    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if transactionRules.count == 0 {
            checkIfThereAreAnyResults(isEmpty: true)
        } else {
            checkIfThereAreAnyResults(isEmpty: false)
        }
        return transactionRules.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        cell.selectionStyle = .none
        let rule = transactionRules[indexPath.item]
        cell.textLabel!.textColor = ThemeManager.currentTheme().generalTitleColor
        cell.textLabel!.font = UIFont.preferredFont(forTextStyle: .body)
        cell.textLabel!.text = rule.match_description
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let rule = transactionRules[indexPath.item]
        let destination = FinanceTransactionRuleViewController()
        destination.transactionRule = rule
        self.navigationController?.pushViewController(destination, animated: true)
    }
}
