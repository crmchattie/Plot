//
//  PurchasesViewController.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 5/30/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import SplitRow
import Firebase

protocol UpdatePurchasesDelegate: class {
    func updatePurchases(purchase: Purchase)
}

class PurchasesViewController: FormViewController {
    
    weak var delegate : UpdatePurchasesDelegate?
    
    var purchase: Purchase!
    
    var users = [User]()
    var filteredUsers = [User]()
    var purchaserUsers = [User]()
    var purchaseeUsers = [User]()
    var userNames : [String] = []
    var userNamesString: String = ""
    
    fileprivate var movingBackwards: Bool = true
    
    fileprivate var active: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMainView()
        
        if purchase != nil {
            active = true
            self.navigationItem.rightBarButtonItem?.isEnabled = true
            if let participants = purchase!.participantsIDs {
                for ID in participants {
                    print("id \(ID)")
                    if let user = users.first(where: {$0.id == ID}) {
                        purchaseeUsers.append(user)
                    }
                }
                purchaseeUsers = purchaseeUsers.sorted { ($0.name! < $1.name!) }
            }
            if let participants = purchase!.purchaser {
                for ID in participants {
                    if let user = users.first(where: {$0.id == ID}) {
                        purchaserUsers.append(user)
                    }
                }
                purchaserUsers = purchaserUsers.sorted { ($0.name! < $1.name!) }
            }
        } else {
            purchase = Purchase(dictionary: ["name" : "Purchase Name" as AnyObject])
        }
        
        initializeForm()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.movingBackwards {
            delegate?.updatePurchases(purchase: purchase)
        }
    }
    
    fileprivate func setupMainView() {
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        navigationItem.title = "New Purchase"
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.sectionIndexBackgroundColor = view.backgroundColor
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        navigationItem.rightBarButtonItem =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(rightBarButtonTapped))
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        
    }
    
    fileprivate func initializeForm() {
        
        form +++
            Section()
            
            <<< TextRow("Purchase Name") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.placeholder = $0.tag
                if self.active {
                    $0.value = self.purchase.name
                    self.navigationItem.title = $0.value
                } else {
                    $0.cell.textField.becomeFirstResponder()
                }
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                    row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                }
                .onChange() { [unowned self] row in
                    if row.value == nil {
                        self.navigationItem.title = "New Purchase"
                        self.navigationItem.rightBarButtonItem?.isEnabled = false
                    } else {
                        self.navigationItem.title = row.value
                        self.rightBarButton()
                    }
            }
            
            <<< TextRow("Type of Purchase") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.placeholder = $0.tag
                if self.active && self.purchase.purchaseType != nil {
                    $0.value = self.purchase.purchaseType
                }
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                    row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
            }
            
            <<< TextAreaRow("Description") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textView?.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textView?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.placeholderLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.placeholder = $0.tag
                if self.active && self.purchase.purchaseDescription != nil {
                    $0.value = self.purchase.purchaseDescription
                }
                }.cellUpdate({ (cell, row) in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textView?.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textView?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.placeholderLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                })
            
            <<< DecimalRow("Cost"){
                $0.useFormatterDuringInput = true
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.title = $0.tag
                $0.value = 0.00
                if self.active {
                    $0.value = self.purchase.cost
                }
                let formatter = CurrencyFormatter()
                formatter.locale = .current
                formatter.numberStyle = .currency
                $0.formatter = formatter
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                }.onChange() { [unowned self] row in
                    if row.value == 0.00 {
                        row.value = nil
                    }
                    self.rightBarButton()
        }
        
        form +++
        Section("Who made the purchase?")
        
        for user in users {
            if let userName = user.name {
                form.last!
                <<< CheckRow("purchaser\(userName)") {
                    $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    $0.cell.tintColor = FalconPalette.defaultBlue
                    $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    $0.title = userName
                    if purchaserUsers.contains(user) {
                        $0.value = true
                    } else {
                        $0.value = false
                    }
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        cell.tintColor = FalconPalette.defaultBlue
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    }.onChange { row in
                        if row.value == true {
                            self.purchaserUsers.append(user)
                        } else {
                            if let index = self.purchaserUsers.firstIndex(of: user) {
                                self.purchaserUsers.remove(at: index)
                            }
                        }
                }
            }
        }
        
        form +++
            Section("Split up the purchase")
        
        if users.count > 1 {
            form.last!
            <<< CheckRow("Everyone") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.tintColor = FalconPalette.defaultBlue
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.title = $0.tag
                if purchaseeUsers == users {
                    $0.value = true
                } else {
                    $0.value = false
                }
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.tintColor = FalconPalette.defaultBlue
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                }.onChange { row in
                    if row.value == true {
                        self.purchaseeUsers = self.users
                        for user in self.purchaseeUsers {
                            if let userName = user.name {
                                let checkRow: CheckRow! = self.form.rowBy(tag: "purchasee\(userName)")
                                checkRow.value = false
                                checkRow.updateCell()
                            }
                        }
                        if let intRow: IntRow = self.form.rowBy(tag: "purchaseRowCount") {
                            intRow.value = nil
                            intRow.updateCell()
                        }
                    }
                }
        }

        for user in users {
            if let userName = user.name {
                form.last!
                <<< CheckRow("purchasee\(userName)") {
                    $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    $0.cell.tintColor = FalconPalette.defaultBlue
                    $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    $0.title = userName
                    if users.count == 1 {
                        if !purchaseeUsers.contains(user) || purchaseeUsers.isEmpty {
                            $0.value = false
                        } else {
                            $0.value = true
                        }
                    } else {
                        if purchaseeUsers == users || !purchaseeUsers.contains(user) || purchaseeUsers.isEmpty {
                            $0.value = false
                        } else {
                            $0.value = true
                        }
                    }
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        cell.tintColor = FalconPalette.defaultBlue
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    }.onChange { row in
                        if row.value == true {
                            if self.purchaseeUsers == self.users {
                                self.purchaseeUsers.removeAll()
                            }
                            self.purchaseeUsers.append(user)
                            if let checkRow: CheckRow = self.form.rowBy(tag: "Everyone") {
                                checkRow.value = false
                                checkRow.updateCell()
                            }
                            if let intRow: IntRow = self.form.rowBy(tag: "purchaseRowCount") {
                                intRow.value = nil
                                intRow.updateCell()
                            }
                        } else {
                            if let checkRow: CheckRow = self.form.rowBy(tag: "Everyone") {
                                if checkRow.value == true {
                                    return
                                }
                            }
                            if let index = self.purchaseeUsers.firstIndex(of: user) {
                                self.purchaseeUsers.remove(at: index)
                            }
                        }
                }
            }
        }
        
        form.last!
        <<< IntRow("purchaseRowCount") {
            $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
            $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
            $0.title = "Split purchase by custom number"
            if let rowValue = purchase.purchaseRowCount {
                $0.value = rowValue
            }
            }.onChange() { [unowned self] row in
                    if row.value != nil {
                        self.purchaseeUsers = []
                        if let checkRow: CheckRow = self.form.rowBy(tag: "Everyone") {
                            checkRow.value = false
                            checkRow.updateCell()
                        }
                        for user in self.purchaseeUsers {
                            if let userName = user.name {
                                let checkRow: CheckRow! = self.form.rowBy(tag: "purchasee\(userName)")
                                checkRow.value = false
                                checkRow.updateCell()
                            }
                        }
                    }
                    self.rightBarButton()
        }
        
        
        
    }
    
    fileprivate func rightBarButton() {
        let nameRow: TextRow! = self.form.rowBy(tag: "Purchase Name")
        let decimalRow: DecimalRow! = self.form.rowBy(tag: "Cost")
        
        if nameRow.value != nil && decimalRow.value != nil {
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        } else {
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
    
    @objc fileprivate func rightBarButtonTapped() {
        movingBackwards = false
        let valuesDictionary = form.values()
        
        purchase.name = valuesDictionary["Purchase Name"] as? String
        
        if let value = valuesDictionary["Type of Purchase"] as? String {
            purchase.purchaseType = value
        }
        
        if let value = valuesDictionary["Description"] as? String {
            purchase.purchaseDescription = value
        }
        
        purchase.cost = valuesDictionary["Cost"] as? Double
        
        if let value = valuesDictionary["purchaseRowCount"] as? Int {
            purchase.purchaseRowCount = value
        } else {
            purchase.purchaseRowCount = nil
        }
        
        if !purchaserUsers.isEmpty {
            purchase.purchaser = fetchMembersIDs(users: purchaserUsers)
        } else {
            purchase.purchaser = nil
        }
    
        if !purchaseeUsers.isEmpty {
            purchase.participantsIDs = fetchMembersIDs(users: purchaseeUsers)
        } else {
            purchase.participantsIDs = nil
        }
        
                        
        delegate?.updatePurchases(purchase: purchase)
        
        self.navigationController?.popViewController(animated: true)
    }
    
    
    func fetchMembersIDs(users: [User]) -> ([String]) {
        var membersIDs = [String]()
                
        for selectedUser in users {
            guard let id = selectedUser.id else { continue }
            membersIDs.append(id)
        }
        
        return (membersIDs)
    }
    
    
}
