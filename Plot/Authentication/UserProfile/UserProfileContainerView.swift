//
//  UserProfileContainerView.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/4/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit


class BioTextView: UITextView {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(UIResponderStandardEditActions.paste(_:)) {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }
}

class PasteRestrictedTextField: UITextField {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(UIResponderStandardEditActions.paste(_:)) {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }
}

class UserProfileContainerView: UIView {
    
    lazy var profileImageView: UIImageView = {
        let profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.masksToBounds = true
        profileImageView.layer.cornerRadius = 48
        profileImageView.isUserInteractionEnabled = true
        profileImageView.backgroundColor = .secondarySystemGroupedBackground
        return profileImageView
    }()
    
    let addPhotoLabel: UILabel = {
        let addPhotoLabel = UILabel()
        addPhotoLabel.translatesAutoresizingMaskIntoConstraints = false
        addPhotoLabel.text = "Add\nphoto"
        addPhotoLabel.font = UIFont.preferredFont(forTextStyle: .body)
        addPhotoLabel.adjustsFontForContentSizeCategory = true
        addPhotoLabel.numberOfLines = 2
        addPhotoLabel.textColor = FalconPalette.defaultBlue
        addPhotoLabel.textAlignment = .center
        return addPhotoLabel
    }()
    
    var name: PasteRestrictedTextField = {
        let name = PasteRestrictedTextField()
        name.font = UIFont.preferredFont(forTextStyle: .body)
        name.adjustsFontForContentSizeCategory = true
        name.enablesReturnKeyAutomatically = true
        name.translatesAutoresizingMaskIntoConstraints = false
        name.textAlignment = .center
        name.placeholder = "Enter name"
        name.borderStyle = .none
        name.autocorrectionType = .no
        name.returnKeyType = .done
        name.keyboardAppearance = .default
        name.textColor = .label
        
        return name
    }()
    
    let phone: PasteRestrictedTextField = {
        let phone = PasteRestrictedTextField()
        phone.font = UIFont.preferredFont(forTextStyle: .body)
        phone.adjustsFontForContentSizeCategory = true
        phone.translatesAutoresizingMaskIntoConstraints = false
        phone.textAlignment = .center
        phone.keyboardType = .numberPad
        phone.placeholder = "Phone number"
        phone.borderStyle = .none
//        phone.isEnabled = false
        phone.textColor = .label
        phone.keyboardAppearance = .default
        return phone
    }()
    
    let email: PasteRestrictedTextField = {
        let textField = PasteRestrictedTextField()
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.textAlignment = .center
        textField.keyboardType = .emailAddress
        textField.attributedPlaceholder = NSAttributedString(string: "Email",
                                     attributes: [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
        textField.borderStyle = .none
        textField.layer.cornerRadius = 10
        textField.autocorrectionType = .no
        textField.backgroundColor = .secondarySystemGroupedBackground
        textField.textColor = .label
        textField.keyboardAppearance = .default
        return textField
    }()
    
    let userData: UIView = {
        let userData = UIView()
        userData.translatesAutoresizingMaskIntoConstraints = false
        userData.layer.cornerRadius = 10
        userData.backgroundColor = .secondarySystemGroupedBackground
        return userData
    }()
    
    let bio: BioTextView = {
        let bio = BioTextView()
        bio.translatesAutoresizingMaskIntoConstraints = false
        bio.layer.cornerRadius = 10
        bio.textAlignment = .center
        bio.font = UIFont.preferredFont(forTextStyle: .body)
        bio.adjustsFontForContentSizeCategory = true
        bio.isScrollEnabled = false
        bio.textContainerInset = UIEdgeInsets(top: 15, left: 35, bottom: 15, right: 35)
        bio.backgroundColor = .secondarySystemGroupedBackground
        bio.textColor = .label
        bio.indicatorStyle = .default
        bio.keyboardAppearance = .default
        bio.textContainer.lineBreakMode = .byTruncatingTail
        bio.returnKeyType = .done
        return bio
    }()
    
    let bioPlaceholderLabel: UILabel = {
        let bioPlaceholderLabel = UILabel()
        bioPlaceholderLabel.text = "Bio"
        bioPlaceholderLabel.font = UIFont.preferredFont(forTextStyle: .body)
        bioPlaceholderLabel.adjustsFontForContentSizeCategory = true
        bioPlaceholderLabel.sizeToFit()
        bioPlaceholderLabel.textAlignment = .center
        bioPlaceholderLabel.backgroundColor = .clear
        bioPlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        bioPlaceholderLabel.textColor = .secondaryLabel
        return bioPlaceholderLabel
    }()
    
    let countLabel: UILabel = {
        let countLabel = UILabel()
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.sizeToFit()
        countLabel.textColor = .secondaryLabel
        countLabel.font = UIFont.preferredFont(forTextStyle: .body)
        countLabel.adjustsFontForContentSizeCategory = true
        countLabel.isHidden = true
        
        return countLabel
    }()
    
    let bioMaxCharactersCount = 70
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .systemGroupedBackground
        
        addSubview(profileImageView)
        addSubview(addPhotoLabel)
        addSubview(userData)
        addSubview(bio)
        addSubview(email)
        addSubview(countLabel)
        userData.addSubview(name)
        userData.addSubview(phone)
        bio.addSubview(bioPlaceholderLabel)
        
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 30),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),
            
            addPhotoLabel.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor),
            addPhotoLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            addPhotoLabel.widthAnchor.constraint(equalToConstant: 100),
            addPhotoLabel.heightAnchor.constraint(equalToConstant: 100),
            
            userData.topAnchor.constraint(equalTo: profileImageView.topAnchor, constant: 0),
            userData.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 10),
            userData.bottomAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 0),
            
            name.topAnchor.constraint(equalTo: userData.topAnchor, constant: 0),
            name.leftAnchor.constraint(equalTo: userData.leftAnchor, constant: 0),
            name.rightAnchor.constraint(equalTo: userData.rightAnchor, constant: 0),
            name.heightAnchor.constraint(equalToConstant: 50),
            
            phone.topAnchor.constraint(equalTo: name.bottomAnchor, constant: 0),
            phone.leftAnchor.constraint(equalTo: userData.leftAnchor, constant: 0),
            phone.rightAnchor.constraint(equalTo: userData.rightAnchor, constant: 0),
            phone.heightAnchor.constraint(equalToConstant: 50),
            
            email.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 10),
            email.heightAnchor.constraint(equalToConstant: 50),
            
            bio.topAnchor.constraint(equalTo: email.bottomAnchor, constant: 10),
                        
            countLabel.widthAnchor.constraint(equalToConstant: 30),
            countLabel.heightAnchor.constraint(equalToConstant: 30),
            countLabel.rightAnchor.constraint(equalTo: bio.rightAnchor, constant: -5),
            countLabel.bottomAnchor.constraint(equalTo: bio.bottomAnchor, constant: -5),
            
            bioPlaceholderLabel.centerXAnchor.constraint(equalTo: bio.centerXAnchor, constant: 0),
            bioPlaceholderLabel.centerYAnchor.constraint(equalTo: bio.centerYAnchor, constant: 0),
        ])
        
        bioPlaceholderLabel.isHidden = !bio.text.isEmpty
        
        if profileImageView.image != nil {
            addPhotoLabel.isHidden = true
        } else {
            addPhotoLabel.isHidden = false
        }
        
        
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                profileImageView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 15),
                bio.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 15),
                bio.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -15),
                email.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 15),
                email.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -15),
                userData.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -15),
            ])
        } else {
            NSLayoutConstraint.activate([
                profileImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
                bio.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
                bio.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
                email.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
                email.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
                userData.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
            ])
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }    
}
