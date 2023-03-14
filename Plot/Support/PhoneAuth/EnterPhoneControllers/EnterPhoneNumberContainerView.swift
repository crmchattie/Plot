//
//  EnterPhoneNumberContainerView.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import PhoneNumberKit

class EnterPhoneNumberContainerView: UIView {
    
    let phoneNumberKit = PhoneNumberKit()
    
    let title: UILabel = {
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.textAlignment = .center
        title.text = "Phone number"
        title.textColor = .label
        title.font = UIFont.title1.with(weight: .bold)
        return title
    }()
    
    let instructions: UILabel = {
        let instructions = UILabel()
        instructions.translatesAutoresizingMaskIntoConstraints = false
        instructions.textAlignment = .center
        instructions.numberOfLines = 2
        instructions.textColor = .label
        instructions.font = UIFont.title3.with(weight: .medium)
        return instructions
    }()
    
    let selectCountry: UIButton = {
        let selectCountry = UIButton()
        selectCountry.translatesAutoresizingMaskIntoConstraints = false
        selectCountry.setTitle("United States", for: .normal)
        selectCountry.setTitleColor(.white, for: .normal)
        selectCountry.contentHorizontalAlignment = .center
        selectCountry.contentVerticalAlignment = .center
        selectCountry.titleLabel?.sizeToFit()
        selectCountry.backgroundColor = .systemBlue
        selectCountry.layer.cornerRadius = 10
        selectCountry.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10.0, bottom: 0.0, right: 10.0)
        selectCountry.titleLabel?.font = UIFont.title3.with(weight: .medium)
        selectCountry.titleLabel?.adjustsFontForContentSizeCategory = true
        return selectCountry
    }()
    
    var countryCode: UILabel = {
        var countryCode = UILabel()
        countryCode.translatesAutoresizingMaskIntoConstraints = false
        countryCode.text = "+1"
        countryCode.textAlignment = .center
        countryCode.textColor = .label
        countryCode.font = UIFont.title3.with(weight: .medium)
        countryCode.adjustsFontForContentSizeCategory = true
        return countryCode
    }()
    
    let phoneNumber: UITextField = {
        let phoneNumber = UITextField()
        phoneNumber.font = UIFont.title3.with(weight: .medium)
        phoneNumber.adjustsFontForContentSizeCategory = true
        phoneNumber.translatesAutoresizingMaskIntoConstraints = false
        phoneNumber.textAlignment = .center
        phoneNumber.keyboardType = .numberPad
        phoneNumber.keyboardAppearance = .default
        phoneNumber.textColor = .label        
        return phoneNumber
    }()
    
    var phoneContainer: UIView = {
        var phoneContainer = UIView()
        phoneContainer.translatesAutoresizingMaskIntoConstraints = false
        phoneContainer.layer.cornerRadius = 10
        phoneContainer.backgroundColor = .secondarySystemGroupedBackground
        return phoneContainer
    }()
    
    let nextView: UIButton = {
        let nextView = UIButton()
        nextView.translatesAutoresizingMaskIntoConstraints = false
        nextView.titleLabel?.backgroundColor = .clear
        nextView.titleLabel?.font = UIFont.title3.with(weight: .semibold)
        nextView.setTitle("Continue", for: .normal)
        nextView.setTitleColor(.systemBlue, for: .normal)
        nextView.backgroundColor = .secondarySystemGroupedBackground
        nextView.layer.cornerRadius = 10
        return nextView
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        
        addSubview(title)
        addSubview(instructions)
        addSubview(phoneContainer)
        phoneContainer.addSubview(countryCode)
        phoneContainer.addSubview(phoneNumber)
        addSubview(selectCountry)
        addSubview(nextView)
                
        let leftConstant: CGFloat = 15
        let rightConstant: CGFloat = -15
        let heightConstant: CGFloat = 50
        let spacingConstant: CGFloat = 20
        
        NSLayoutConstraint.activate([
            
            title.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: spacingConstant),
            title.rightAnchor.constraint(equalTo: rightAnchor, constant: rightConstant),
            title.leftAnchor.constraint(equalTo: leftAnchor, constant: leftConstant),
            title.centerXAnchor.constraint(equalTo: phoneContainer.centerXAnchor),
            
            instructions.topAnchor.constraint(equalTo: title.bottomAnchor, constant: spacingConstant),
            instructions.rightAnchor.constraint(equalTo: title.rightAnchor),
            instructions.leftAnchor.constraint(equalTo: title.leftAnchor),
            
            phoneContainer.topAnchor.constraint(equalTo: instructions.bottomAnchor, constant: spacingConstant),
            phoneContainer.rightAnchor.constraint(equalTo: title.rightAnchor),
            phoneContainer.leftAnchor.constraint(equalTo: title.leftAnchor),
            phoneContainer.heightAnchor.constraint(equalToConstant: heightConstant),
            
            countryCode.leftAnchor.constraint(equalTo: phoneContainer.leftAnchor, constant: leftConstant),
            countryCode.centerYAnchor.constraint(equalTo: phoneContainer.centerYAnchor),
            countryCode.heightAnchor.constraint(equalTo: phoneContainer.heightAnchor),
            
            phoneNumber.rightAnchor.constraint(equalTo: title.rightAnchor),
            phoneNumber.leftAnchor.constraint(equalTo: title.leftAnchor),
            phoneNumber.centerYAnchor.constraint(equalTo: phoneContainer.centerYAnchor),
            phoneNumber.heightAnchor.constraint(equalTo: phoneContainer.heightAnchor),
            
            selectCountry.topAnchor.constraint(equalTo: phoneContainer.bottomAnchor, constant: spacingConstant),
            selectCountry.rightAnchor.constraint(equalTo: title.rightAnchor),
            selectCountry.leftAnchor.constraint(equalTo: title.leftAnchor),
            selectCountry.heightAnchor.constraint(equalToConstant: heightConstant),
            
            nextView.topAnchor.constraint(equalTo: selectCountry.bottomAnchor, constant: spacingConstant),
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
