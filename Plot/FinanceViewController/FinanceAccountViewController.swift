//
//  FinanceAccountViewController.swift
//  Plot
//
//  Created by Cory McHattie on 9/1/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import Firebase

protocol UpdateAccountDelegate: class {
    func updateAccount(account: MXAccount)
}

class FinanceAccountViewController: FormViewController {
    var account: MXAccount!
    
    weak var delegate : UpdateAccountDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        initializeForm()
    }
    
    fileprivate func configureTableView() {
        tableView.allowsMultipleSelectionDuringEditing = false
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.backgroundColor = view.backgroundColor
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        tableView.separatorStyle = .none
        definesPresentationContext = true
        navigationItem.title = "Account"
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        navigationItem.rightBarButtonItem = doneBarButton
        
    }
    
    @IBAction func done(_ sender: AnyObject) {
        self.delegate?.updateAccount(account: account)
        self.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func initializeForm() {
        let numberFormatter = NumberFormatter()
        numberFormatter.currencyCode = account.currency_code
        numberFormatter.numberStyle = .currency
        
        // create dateFormatter with UTC time format
        let isodateFormatter = ISO8601DateFormatter()
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "MMM dd, yyyy"

        
        form +++
            Section()
            
            <<< TextRow("Name") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.title = $0.tag
                $0.value = account.name.capitalized
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
            }.onChange { row in
                if let value = row.value {
                    self.account.name = value
                    if let currentUser = Auth.auth().currentUser?.uid {
                        let reference = Database.database().reference().child(userFinancialAccountsEntity).child(currentUser).child(self.account.guid).child("name")
                        reference.setValue(value)
                    }
                }
            }
            
            <<< TextRow("Type") {
                $0.cell.isUserInteractionEnabled = false
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.title = $0.tag
                $0.value = account.type.name
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
            }
        
            if account.subtype != .none {
                form.last!
                    <<< TextRow("Subtype") {
                        $0.cell.isUserInteractionEnabled = false
                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                        $0.title = $0.tag
                        $0.value = account.subtype.name
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                }
            }
        
        form.last!
            <<< TextRow("Last Updated On") {
                $0.cell.isUserInteractionEnabled = false
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.title = $0.tag
                if let date = isodateFormatter.date(from: account.updated_at) {
                    $0.value = dateFormatterPrint.string(from: date)
                }
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
            }
            
            <<< CheckRow() {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.tintColor = FalconPalette.defaultBlue
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.accessoryType = .checkmark
                if self.account.should_link ?? true {
                    $0.title = "Included in Financial Profile"
                    $0.value = true
                } else {
                    $0.title = "Not Included in Financial Profile"
                    $0.value = false
                }
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.tintColor = FalconPalette.defaultBlue
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                }.onChange { row in
                    row.title = row.value! ? "Included in Financial Profile" : "Not Included in Financial Profile"
                    row.updateCell()
                    self.account.should_link = row.value
                    if let currentUser = Auth.auth().currentUser?.uid {
                        let reference = Database.database().reference().child(userFinancialAccountsEntity).child(currentUser).child(self.account.guid).child("should_link")
                        reference.setValue(row.value!)
                    }
                }
            
            <<< TextRow("Balance") {
                $0.cell.isUserInteractionEnabled = false
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.title = $0.tag
                if let balance = numberFormatter.string(from: account.balance as NSNumber) {
                    $0.value = "\(balance)"
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
            }
            
            if let availableBalance = account.available_balance {
                form.last!
                    <<< TextRow("Available Balance") {
                        $0.cell.isUserInteractionEnabled = false
                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                        $0.title = $0.tag
                        if let balance = numberFormatter.string(from: availableBalance as NSNumber) {
                            $0.value = "\(balance)"
                        }
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                }
            }
            
            if let paymentDueDate = account.payment_due_at {
                form.last!
                    <<< TextRow("Payment Due Date") {
                        $0.cell.isUserInteractionEnabled = false
                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                        $0.title = $0.tag
                        if let date = isodateFormatter.date(from: paymentDueDate) {
                            $0.value = dateFormatterPrint.string(from: date)
                        }
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                }
            }
        
            if let minimum = account.minimum_payment {
                form.last!
                    <<< TextRow("Minimum Payment Due") {
                        $0.cell.isUserInteractionEnabled = false
                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                        $0.title = $0.tag
                        if let minimum = numberFormatter.string(from: minimum as NSNumber) {
                            $0.value = "\(minimum)"
                        }
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                }
            }
    }
    
}
