//
//  ChooseEmailView.swift
//  Plot
//
//  Created by Cory McHattie on 2/20/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import UIKit

class ChooseEmailView: UIView {
        
    let title: UILabel = {
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.textAlignment = .center
        title.text = "Email"
        title.textColor = .label
        title.font = .preferredFont(forTextStyle: .title1)
        title.adjustsFontForContentSizeCategory = true
        return title
    }()
    
    let instructions: UILabel = {
        let instructions = UILabel()
        instructions.translatesAutoresizingMaskIntoConstraints = false
        instructions.textAlignment = .center
        instructions.numberOfLines = 2
        instructions.textColor = .label
        instructions.font = .preferredFont(forTextStyle: .body)
        instructions.adjustsFontForContentSizeCategory = true
        return instructions
    }()
    
    let googleView: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Google", for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        button.backgroundColor = .secondarySystemGroupedBackground
        button.layer.cornerRadius = 10
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10.0, bottom: 0.0, right: 10.0)
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        return button
    }()
    
    let emailView: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Email", for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        button.backgroundColor = .secondarySystemGroupedBackground
        button.layer.cornerRadius = 10
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10.0, bottom: 0.0, right: 10.0)
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        return button
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(title)
        addSubview(instructions)
        addSubview(googleView)
        addSubview(emailView)
                
        let leftConstant: CGFloat = 10
        let rightConstant: CGFloat = -10
        let heightConstant: CGFloat = 50
        let spacingConstant: CGFloat = 20
        
        NSLayoutConstraint.activate([
            
            title.topAnchor.constraint(equalTo: topAnchor, constant: spacingConstant),
            title.rightAnchor.constraint(equalTo: rightAnchor, constant: rightConstant),
            title.leftAnchor.constraint(equalTo: leftAnchor, constant: leftConstant),
            title.centerXAnchor.constraint(equalTo: emailView.centerXAnchor),
            
            instructions.topAnchor.constraint(equalTo: title.bottomAnchor, constant: spacingConstant),
            instructions.rightAnchor.constraint(equalTo: title.rightAnchor),
            instructions.leftAnchor.constraint(equalTo: title.leftAnchor),
            
            googleView.topAnchor.constraint(equalTo: instructions.bottomAnchor, constant: spacingConstant),
            googleView.rightAnchor.constraint(equalTo: title.rightAnchor),
            googleView.leftAnchor.constraint(equalTo: title.leftAnchor),
            googleView.heightAnchor.constraint(equalToConstant: heightConstant),
            
            emailView.topAnchor.constraint(equalTo: googleView.bottomAnchor, constant: spacingConstant),
            emailView.rightAnchor.constraint(equalTo: title.rightAnchor),
            emailView.leftAnchor.constraint(equalTo: title.leftAnchor),
            emailView.heightAnchor.constraint(equalToConstant: heightConstant),
        ])
    }
    
    //necessary to deserialize the UIView
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
}
