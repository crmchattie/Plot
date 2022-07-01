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
        title.textColor = ThemeManager.currentTheme().generalTitleColor
        title.font = UIFont.systemFont(ofSize: 32)
        title.sizeToFit()
        
        return title
    }()
    
    let instructions: UILabel = {
        let instructions = UILabel()
        instructions.translatesAutoresizingMaskIntoConstraints = false
        instructions.textAlignment = .center
        instructions.numberOfLines = 2
        instructions.textColor = ThemeManager.currentTheme().generalTitleColor
        instructions.font = UIFont.systemFont(ofSize: 18)
        instructions.sizeToFit()
        
        return instructions
    }()
    
    let email: UITextField = {
        let email = UITextField()
        email.font = UIFont.preferredFont(forTextStyle: .body)
        email.adjustsFontForContentSizeCategory = true
        email.translatesAutoresizingMaskIntoConstraints = false
        email.textAlignment = .center
        email.keyboardType = .emailAddress
        email.autocapitalizationType = .none
        email.autocorrectionType = .no
        email.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
        email.textColor = ThemeManager.currentTheme().generalTitleColor
        email.addTarget(ChangeEmailView.self, action: #selector(EnterPhoneNumberController.textFieldDidChange(_:)), for: .editingChanged)
        return email
    }()
    
    var emailView: UIView = {
        var emailView = UIView()
        emailView.translatesAutoresizingMaskIntoConstraints = false
        emailView.layer.cornerRadius = 10
        emailView.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        return emailView
    }()
    
    let nextView: UIButton = {
        let next = UIButton()
        next.translatesAutoresizingMaskIntoConstraints = false
        next.setTitle("Add", for: .normal)
        next.contentVerticalAlignment = .center
        next.contentHorizontalAlignment = .center
        next.setTitleColor(FalconPalette.defaultBlue, for: .normal)
        next.setTitleColor(ThemeManager.currentTheme().generalSubtitleColor, for: .highlighted)
        next.setTitleColor(ThemeManager.currentTheme().generalSubtitleColor, for: .disabled)
        return next
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(title)
        addSubview(instructions)
        addSubview(emailView)
        emailView.addSubview(email)
        addSubview(nextView)
        
        email.delegate = self
        
        let leftConstant: CGFloat = 10
        let rightConstant: CGFloat = -10
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

extension ChangeEmailView: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.utf16.count + string.utf16.count - range.length
        return newLength <= 25
    }
    func textFieldDidChangeSelection(_ textField: UITextField) {
        guard let text = textField.text else { return }
        textField.text = text
    }
}
