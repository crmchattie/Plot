//
//  CreateContactTableViewController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 2/3/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import ContactsUI

private let createContactTableViewCellIdentifier = "CreateContactTableViewCellIdentifier"

class CreateContactTableViewController: UITableViewController {
    
    let store = CNContactStore()
    var contact : CNMutableContact? {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "New Contact"
        tableView.separatorStyle = .none
        view.backgroundColor = .systemGroupedBackground
        tableView.register(ContactDataTableViewCell.self, forCellReuseIdentifier: createContactTableViewCellIdentifier)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Create", style: .done, target: self, action: #selector(createContact))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(dismissController))
        navigationItem.largeTitleDisplayMode = .never
    }
    
    
    @objc func dismissController() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func createContact() {
        let request = CNSaveRequest()
        
        let nameCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ContactDataTableViewCell ?? ContactDataTableViewCell()
        let surnameCell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? ContactDataTableViewCell ?? ContactDataTableViewCell()
        let phoneCell = tableView.cellForRow(at: IndexPath(row: 2, section: 0)) as? ContactDataTableViewCell ?? ContactDataTableViewCell()
        contact?.givenName = nameCell.textField.text ?? ""
        contact?.familyName = surnameCell.textField.text ?? ""
        
        let phone = CNLabeledValue(label: CNLabelPhoneNumberiPhone, value: CNPhoneNumber(stringValue: phoneCell.textField.text ?? "" ))
        contact?.phoneNumbers = [phone]
        
        request.add(contact!, toContainerWithIdentifier: nil)
        do {
            try store.execute(request)
            //        ARSLineProgress.showSuccess()
            shouldReFetchFalconUsers = true
            localPhones.append(phoneCell.textField.text?.digits ?? "")
            
            dismiss(animated: true, completion: nil)
        } catch {
            basicErrorAlertWithClose(title: "Error", message: error.localizedDescription, controller: self)
        }
        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: createContactTableViewCellIdentifier,
                                                 for: indexPath) as? ContactDataTableViewCell ?? ContactDataTableViewCell()
        cell.backgroundColor = .secondarySystemGroupedBackground
        cell.textField.backgroundColor = .systemGroupedBackground
        cell.textField.textColor = .label
        
        if indexPath.row == 0 {
            cell.textField.keyboardType = .default
            cell.textField.attributedPlaceholder = NSAttributedString(string:"First name",
                                                                      attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
            cell.textField.text = contact?.givenName
            
        } else if indexPath.row == 1 {
            cell.textField.keyboardType = .default
            cell.textField.attributedPlaceholder = NSAttributedString(string: "Last name",
                                                                      attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
            
            cell.textField.text = contact?.familyName
            
        } else {
            cell.textField.keyboardType = .phonePad
            cell.textField.attributedPlaceholder = NSAttributedString(string:"Phone number",
                                                                      attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
            
            cell.textField.text = contact?.phoneNumbers[0].value.stringValue
        }
        return cell
    }
}
