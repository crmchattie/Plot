//
//  UserInfoPhoneNumberTableViewCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 2/2/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import ContactsUI

extension UIViewController: CNContactViewControllerDelegate {
    fileprivate func checkContactsAuthorizationStatus() -> Bool {
        let contactsAuthorityCheck = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        
        switch contactsAuthorityCheck {
            
        case .denied, .notDetermined, .restricted:
            basicErrorAlertWithClose(title: "No access", message: contactsAccessDeniedMessage, controller: self)
            return false
            
        case .authorized:
            return true
        @unknown default:
            fatalError()
        }
    }
    
    func addPhoneNumber(phone : String , name: String, surname: String) {
        
        let contactsAccessStatus = checkContactsAuthorizationStatus()
        guard contactsAccessStatus == true else { return }
        
        let phone = CNLabeledValue(label: CNLabelPhoneNumberiPhone, value: CNPhoneNumber(stringValue :phone ))
        let contact = CNMutableContact()
        
        contact.givenName = name
        contact.familyName = surname
        contact.phoneNumbers = [phone]
        let destination = CreateContactTableViewController(style: .grouped)
        let newNavigationController = UINavigationController(rootViewController: destination)
        
        destination.contact = contact
        present(newNavigationController, animated: true, completion: nil)
    }
}

class UserInfoPhoneNumberTableViewCell: UITableViewCell {
    
    weak var userInfoTableViewController: UserInfoTableViewController?
    
    let copyNumberImage = UIImage(named: "copyNumber")?.withRenderingMode(.alwaysTemplate)
    
    let copy: UIButton = {
        let copy = UIButton(type: .system)
        copy.translatesAutoresizingMaskIntoConstraints = false
        copy.imageView?.contentMode = .scaleAspectFit
        
        return copy
    }()
    
    let add: UIButton = {
        let add = UIButton(type: .system )
        add.translatesAutoresizingMaskIntoConstraints = false
        add.imageView?.contentMode = .scaleAspectFit
        add.setTitle("Add to contacts", for: .normal)
        
        return add
    }()
    
    let phoneLabel: UILabel = {
        let phoneLabel = UILabel()
        phoneLabel.textColor = .label
        phoneLabel.translatesAutoresizingMaskIntoConstraints = false
        phoneLabel.adjustsFontForContentSizeCategory = true
        return phoneLabel
    }()
    
    let contactStatus: UILabel = {
        let contactStatus = UILabel()
        contactStatus.font = UIFont.preferredFont(forTextStyle: .subheadline)
        contactStatus.adjustsFontForContentSizeCategory = true
        contactStatus.text = "This user not in your contacts"
        contactStatus.textColor = .secondaryLabel
        contactStatus.translatesAutoresizingMaskIntoConstraints = false
        return contactStatus
    }()
    
    let bio: UILabel = {
        let bio = UILabel()
        bio.numberOfLines = 0
        bio.textColor = .label
        bio.translatesAutoresizingMaskIntoConstraints = false
        bio.font = UIFont.preferredFont(forTextStyle: .body)
        bio.adjustsFontForContentSizeCategory = true
        return bio
    }()
    
    var bioTopAnchor: NSLayoutConstraint!
    
    var addHeightConstraint:NSLayoutConstraint!
    var phoneTopConstraint:NSLayoutConstraint!
    var contactStatusHeightConstraint: NSLayoutConstraint!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        addSubview(copy)
        addSubview(add)
        addSubview(contactStatus)
        addSubview(phoneLabel)
        addSubview(bio)
        
        contactStatus.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
        if #available(iOS 11.0, *) {
            contactStatus.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 15).isActive = true
        } else {
            contactStatus.leftAnchor.constraint(equalTo: leftAnchor, constant: 15).isActive = true
        }
        contactStatus.widthAnchor.constraint(equalToConstant: 180).isActive = true
        contactStatusHeightConstraint = contactStatus.heightAnchor.constraint(equalToConstant: 40)
        contactStatusHeightConstraint.isActive = true
        
        phoneTopConstraint = phoneLabel.topAnchor.constraint(equalTo: contactStatus.bottomAnchor, constant: 0)
        phoneTopConstraint.isActive = true
        
        if #available(iOS 11.0, *) {
            phoneLabel.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 15).isActive = true
        } else {
            phoneLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 15).isActive = true
        }
        phoneLabel.widthAnchor.constraint(equalToConstant: 200).isActive = true
        phoneLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        
        
        if #available(iOS 11.0, *) {
            copy.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -15).isActive = true
            add.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -15).isActive = true
        } else {
            copy.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
            add.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
        }
        
        add.widthAnchor.constraint(equalToConstant: 110).isActive = true
        addHeightConstraint = add.heightAnchor.constraint(equalToConstant: 20)
        addHeightConstraint.isActive = true
        add.centerYAnchor.constraint(equalTo: contactStatus.centerYAnchor, constant: 0).isActive = true
        
        copy.widthAnchor.constraint(equalToConstant: 20).isActive = true
        copy.heightAnchor.constraint(equalToConstant: 20).isActive = true
        copy.centerYAnchor.constraint(equalTo: phoneLabel.centerYAnchor, constant: 0).isActive = true
        
        add.addTarget(self, action: #selector(handleAddNewContact), for: .touchUpInside)
        copy.addTarget(self, action: #selector(handleCopy), for: .touchUpInside)
        copy.setImage(copyNumberImage, for: .normal)
        
        bioTopAnchor = bio.topAnchor.constraint(equalTo: phoneLabel.bottomAnchor, constant: 20)
        bioTopAnchor.isActive = true
        if #available(iOS 11.0, *) {
            bio.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 15).isActive = true
            bio.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -15).isActive = true
        } else {
            bio.leftAnchor.constraint(equalTo: leftAnchor, constant: 15).isActive = true
            bio.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        copy.imageView?.image = nil
    }
    
    @objc func handleAddNewContact() {
        let name = userInfoTableViewController?.user?.name?.components(separatedBy: " ").first ?? ""
        var surname = userInfoTableViewController?.user?.name?.components(separatedBy: " ").last ?? ""
        if name == surname {
            surname = ""
        }
        userInfoTableViewController?.addPhoneNumber(phone: self.phoneLabel.text ?? "", name: name, surname: surname)
    }
    
    @objc func handleCopy() {
        UIPasteboard.general.string = self.phoneLabel.text
        //     ARSLineProgress.showSuccess()
    }
}

