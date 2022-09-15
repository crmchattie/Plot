//
//  ContactsDetailController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/7/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import MessageUI
import PhoneNumberKit

class ContactsDetailController: UITableViewController {
    
    let phoneNumberKit = PhoneNumberKit()
    
    var contactName = String()
    
    var contactPhoneNumbers = [String]()
    
    var phoneNumbers = [PhoneNumber]()
    
    //  let invitationText = "Hey! Download Plot on the App Store."
    let invitationText = "Hey! Download Plot on the App Store. https://apps.apple.com/us/app/plot-scheduling-app/id1473764067?ls=1"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        phoneNumbers = phoneNumberKit.parse(contactPhoneNumbers)
        
        title = "Info"
        view.backgroundColor = .systemGroupedBackground
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        extendedLayoutIncludesOpaqueBars = true
        tableView.separatorStyle = .none
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return phoneNumbers.count
        } else {
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .default, reuseIdentifier: identifier)
        cell.backgroundColor =  .secondarySystemGroupedBackground
        cell.textLabel?.textColor = .label
        if indexPath.section == 0 {
            cell.imageView?.image = UIImage(named: "UserpicIcon")
            cell.textLabel?.text = contactName
            cell.textLabel?.font = UIFont.title3.with(weight: .bold)
        } else if indexPath.section == 1 {
            cell.imageView?.image = nil
            cell.textLabel?.text = phoneNumberKit.format(phoneNumbers[indexPath.row], toType: .national)
            cell.textLabel?.font = .preferredFont(forTextStyle: .body)
        } else {
            cell.textLabel?.textColor = FalconPalette.defaultBlue
            cell.textLabel?.text = "Invite to Plot"
            cell.textLabel?.font = .preferredFont(forTextStyle: .body)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 {
            if MFMessageComposeViewController.canSendText() {
                guard contactPhoneNumbers.indices.contains(0) else {
                    basicErrorAlertWith(title: "Error", message: "This user doesn't have any phone number provided.", controller: self)
                    return
                }
                let destination = MFMessageComposeViewController()
                destination.body = invitationText
                destination.recipients = [contactPhoneNumbers[0]]
                destination.messageComposeDelegate = self
                present(destination, animated: true, completion: nil)
            } else {
                basicErrorAlertWith(title: "Error", message: "You cannot send texts.", controller: self)
            }
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 100
        } else {
            return 50
        }
    }
}

extension ContactsDetailController: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        dismiss(animated: true, completion: nil)
    }
}
