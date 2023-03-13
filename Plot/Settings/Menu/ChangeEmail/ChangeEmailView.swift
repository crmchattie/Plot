//
//  ChangeEmailView.swift
//  Plot
//
//  Created by Cory McHattie on 2/20/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import UIKit

class ChangeEmailView: UIView {
        
    let title: UILabel = {
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.textAlignment = .center
        title.text = "Email Address"
        title.textColor = .label
        title.font = UIFont.title1.with(weight: .bold)
        title.adjustsFontForContentSizeCategory = true
        return title
    }()
    
    let instructions: UILabel = {
        let instructions = UILabel()
        instructions.translatesAutoresizingMaskIntoConstraints = false
        instructions.textAlignment = .center
        instructions.numberOfLines = 2
        instructions.textColor = .label
        instructions.font = UIFont.title3.with(weight: .medium)
        instructions.adjustsFontForContentSizeCategory = true
        return instructions
    }()
    
    let email: UITextField = {
        let email = UITextField()
        email.font = UIFont.title3.with(weight: .medium)
        email.adjustsFontForContentSizeCategory = true
        email.translatesAutoresizingMaskIntoConstraints = false
        email.textAlignment = .center
        email.keyboardType = .emailAddress
        email.autocapitalizationType = .none
        email.autocorrectionType = .no
        email.keyboardAppearance = .default
        email.textColor = .label
        return email
    }()
    
    var emailView: UIView = {
        var emailView = UIView()
        emailView.translatesAutoresizingMaskIntoConstraints = false
        emailView.layer.cornerRadius = 10
        emailView.backgroundColor = .secondarySystemGroupedBackground
        return emailView
    }()
    
    let nextView: UIButton = {
        let nextView = UIButton()
        nextView.translatesAutoresizingMaskIntoConstraints = false
        nextView.titleLabel?.backgroundColor = .clear
        nextView.titleLabel?.font = UIFont.title3.with(weight: .semibold)
        nextView.setTitle("Add", for: .normal)
        nextView.setTitleColor(.systemBlue, for: .normal)
        nextView.backgroundColor = .secondarySystemGroupedBackground
        nextView.layer.cornerRadius = 10
        return nextView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(title)
        addSubview(instructions)
        addSubview(emailView)
        emailView.addSubview(email)
        addSubview(nextView)
                
        let leftConstant: CGFloat = 15
        let rightConstant: CGFloat = -15
        let heightConstant: CGFloat = 50
        let spacingConstant: CGFloat = 20
        
        NSLayoutConstraint.activate([
            
            title.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: spacingConstant),
            title.rightAnchor.constraint(equalTo: rightAnchor, constant: rightConstant),
            title.leftAnchor.constraint(equalTo: leftAnchor, constant: leftConstant),
            title.centerXAnchor.constraint(equalTo: emailView.centerXAnchor),
            
            instructions.topAnchor.constraint(equalTo: title.bottomAnchor, constant: spacingConstant),
            instructions.rightAnchor.constraint(equalTo: title.rightAnchor),
            instructions.leftAnchor.constraint(equalTo: title.leftAnchor),
            
            emailView.topAnchor.constraint(equalTo: instructions.bottomAnchor, constant: spacingConstant),
            emailView.rightAnchor.constraint(equalTo: title.rightAnchor),
            emailView.leftAnchor.constraint(equalTo: title.leftAnchor),
            emailView.heightAnchor.constraint(equalToConstant: heightConstant),
            
            email.rightAnchor.constraint(equalTo: title.rightAnchor),
            email.leftAnchor.constraint(equalTo: title.leftAnchor),
            email.centerYAnchor.constraint(equalTo: emailView.centerYAnchor),
            email.heightAnchor.constraint(equalTo: emailView.heightAnchor),
            
            nextView.topAnchor.constraint(equalTo: emailView.bottomAnchor, constant: spacingConstant),
            nextView.rightAnchor.constraint(equalTo: title.rightAnchor),
            nextView.leftAnchor.constraint(equalTo: title.leftAnchor),
            nextView.heightAnchor.constraint(equalToConstant: heightConstant),
        ])
    }
    
    //necessary to deserialize the UIView
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
}
