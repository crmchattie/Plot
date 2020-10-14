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
    var user: MXUser!
    
    var users = [User]()
    var filteredUsers = [User]()
    var selectedFalconUsers = [User]()
    
    var userNames : [String] = []
    var userNamesString: String = ""
    
    var active: Bool = false
    
    weak var delegate : UpdateAccountDelegate?
    
    let numberFormatter = NumberFormatter()
    
    // create dateFormatter with UTC time format
    let isodateFormatter = ISO8601DateFormatter()
    let dateFormatterPrint = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        numberFormatter.numberStyle = .currency
        dateFormatterPrint.dateFormat = "MMM dd, yyyy"
        
        if let _ = account {
            active = true
            numberFormatter.currencyCode = account.currency_code
            
            var participantCount = self.selectedFalconUsers.count
            // If user is creating this activity (admin)
            if account.admin == nil || account.admin == Auth.auth().currentUser?.uid {
                participantCount += 1
            }
            
            if participantCount > 1 {
                self.userNamesString = "\(participantCount) participants"
            } else {
                self.userNamesString = "1 participant"
            }
            
            if let inviteesRow: ButtonRow = self.form.rowBy(tag: "Participants") {
                inviteesRow.title = self.userNamesString
                inviteesRow.updateCell()
            }
            
        } else if let currentUser = Auth.auth().currentUser?.uid {
            let ID = Database.database().reference().child(userFinancialAccountsEntity).child(currentUser).childByAutoId().key ?? ""
            let date = isodateFormatter.string(from: Date())
            account = MXAccount(name: "", balance: 0.0, created_at: date, guid: ID, user_guid: user.guid, type: .any, subtype: .any, user_created: true, admin: currentUser)
            numberFormatter.currencyCode = "USD"
        }
        
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
        
        if active {
            let barButton = UIBarButtonItem(title: "Update", style: .plain, target: self, action: #selector(create))
            navigationItem.rightBarButtonItem = barButton
        } else {
            let barButton = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(create))
            navigationItem.rightBarButtonItem = barButton
        }
        
    }
    
    @IBAction func create(_ sender: AnyObject) {
        if account.user_created ?? false, let currentUser = Auth.auth().currentUser?.uid {
            let date = isodateFormatter.string(from: Date())
            let reference = Database.database().reference()
            reference.child(financialAccountsEntity).child(self.account.guid).child("updated_at").setValue(date)
            reference.child(userFinancialAccountsEntity).child(currentUser).child(account.guid).child("balances").child(date).setValue(account.balance)
        }
        
        updateTags()
        self.delegate?.updateAccount(account: account)
        self.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func initializeForm() {
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
                $0.cell.isUserInteractionEnabled = account.user_created ?? false
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
                    $0.cell.isUserInteractionEnabled = account.user_created ?? false
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
                $0.cell.isUserInteractionEnabled = account.user_created ?? false
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
                    $0.cell.isUserInteractionEnabled = account.user_created ?? false
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
                    $0.cell.isUserInteractionEnabled = account.user_created ?? false
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
                    $0.cell.isUserInteractionEnabled = account.user_created ?? false
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
        
        form +++
            Section()
            <<< ButtonRow("Participants") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                row.cell.textLabel?.textAlignment = .left
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.title = row.tag
                if active {
                    row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    row.title = self.userNamesString
                }
                }.onCellSelection({ _,_ in
                    self.openParticipantsInviter()
                }).cellUpdate { cell, row in
                    cell.accessoryType = .disclosureIndicator
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textLabel?.textAlignment = .left
                    if row.title == "Participants" {
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    } else {
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    }
                }
        
        form +++
            MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                               header: "Tags") {
                                $0.tag = "tagsfields"
                                $0.addButtonProvider = { section in
                                    return ButtonRow(){
                                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                        $0.title = "Add New Tag"
                                    }.cellUpdate { cell, row in
                                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                        cell.textLabel?.textAlignment = .left
                                        
                                    }
                                }
                                $0.multivaluedRowToInsertAt = { index in
                                    return TextRow() {
                                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                        $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                                        $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                                        $0.placeholder = "Tag"
                                    }.cellUpdate { cell, row in
                                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                        cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                                        row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                                    }
                                }
        }
        
        if let items = self.account.tags {
            for item in items {
                var mvs = (form.sectionBy(tag: "tagsfields") as! MultivaluedSection)
                mvs.insert(TextRow(){
                    $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                    $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                    $0.value = item
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                    row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                } , at: mvs.count - 1)
            }
        }
    }
    
    fileprivate func updateTags() {
        if let mvs = (form.values()["tagsfields"] as? [Any?])?.compactMap({ $0 as? String }) {
            if !mvs.isEmpty {
                print("mvs \(mvs)")
                var tagsArray = [String]()
                for value in mvs {
                    tagsArray.append(value)
                }
                self.account.tags = tagsArray
            } else {
                self.account.tags = nil
            }
            if let currentUser = Auth.auth().currentUser?.uid {
                let updatedTags = ["tags": self.account.tags as AnyObject]
                Database.database().reference().child(userFinancialAccountsEntity).child(currentUser).child(self.account.guid).updateChildValues(updatedTags)
            }
        }
    }
    
    @objc fileprivate func openParticipantsInviter() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        let destination = SelectActivityMembersViewController()
        var uniqueUsers = users
        for participant in selectedFalconUsers {
            if let userIndex = users.firstIndex(where: { (user) -> Bool in
                return user.id == participant.id }) {
                uniqueUsers[userIndex] = participant
            } else {
                uniqueUsers.append(participant)
            }
        }
        destination.users = uniqueUsers
        destination.filteredUsers = uniqueUsers
        if !selectedFalconUsers.isEmpty {
            destination.priorSelectedUsers = selectedFalconUsers
        }
        destination.delegate = self
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    func getSelectedFalconUsers(forAccount account: MXAccount, completion: @escaping ([User])->()) {
        guard let participantsIDs = account.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        var selectedFalconUsers = [User]()
        let group = DispatchGroup()
        for id in participantsIDs {
            // Only if the current user is created this activity
            if account.admin == currentUserID && id == currentUserID {
                continue
            }
            
            group.enter()
            let participantReference = Database.database().reference().child("users").child(id)
            participantReference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), var dictionary = snapshot.value as? [String: AnyObject] {
                    dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                    let user = User(dictionary: dictionary)
                    selectedFalconUsers.append(user)
                }
                group.leave()
            })
        }
        
        group.notify(queue: .main) {
            completion(selectedFalconUsers)
        }
    }
    
    func showActivityIndicator() {
        if let tabController = self.tabBarController {
            self.showSpinner(onView: tabController.view)
        }
        self.navigationController?.view.isUserInteractionEnabled = false
    }

    func hideActivityIndicator() {
        self.navigationController?.view.isUserInteractionEnabled = true
        self.removeSpinner()
    }
    
}

extension FinanceAccountViewController: UpdateInvitees {
    func updateInvitees(selectedFalconUsers: [User]) {
        if let inviteesRow: ButtonRow = form.rowBy(tag: "Participants") {
            if !selectedFalconUsers.isEmpty {
                self.selectedFalconUsers = selectedFalconUsers
                
                var participantCount = self.selectedFalconUsers.count
                // If user is creating this activity (admin)
                if account.admin == nil || account.admin == Auth.auth().currentUser?.uid {
                    participantCount += 1
                }
                
                if participantCount > 1 {
                    self.userNamesString = "\(participantCount) participants"
                } else {
                    self.userNamesString = "1 participant"
                }
                
                inviteesRow.title = self.userNamesString
                inviteesRow.updateCell()
                
            } else {
                self.selectedFalconUsers = selectedFalconUsers
                inviteesRow.title = "1 participant"
                inviteesRow.updateCell()
            }
            
            if active {
//                showActivityIndicator()
//                let createChecklist = ChecklistActions(checklist: checklist, active: active, selectedFalconUsers: selectedFalconUsers)
//                createChecklist.updateChecklistParticipants()
//                hideActivityIndicator()

            }
            
        }
    }
}
