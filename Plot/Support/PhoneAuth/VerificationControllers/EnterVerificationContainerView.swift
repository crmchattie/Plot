//
//  EnterVerificationContainerView.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/3/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import PhoneNumberKit

class EnterVerificationContainerView: UIView {
    
    let phoneNumberKit = PhoneNumberKit()
    
    let leftBarButton = UIBarButtonItem(title: "Resend", style: .done, target: EnterVerificationContainerView.self, action: nil)
    
    let titleNumber: UILabel = {
        let titleNumber = UILabel()
        titleNumber.translatesAutoresizingMaskIntoConstraints = false
        titleNumber.textAlignment = .center
        titleNumber.textColor = .label
        titleNumber.font = UIFont.title1.with(weight: .bold)
        return titleNumber
    }()
    
    let subtitleText: UILabel = {
        let subtitleText = UILabel()
        subtitleText.translatesAutoresizingMaskIntoConstraints = false
        subtitleText.font = UIFont.title3.with(weight: .medium)
        subtitleText.adjustsFontForContentSizeCategory = true
        subtitleText.textAlignment = .center
        subtitleText.textColor = .label
        subtitleText.text = "We have sent you an SMS with the code"
        
        return subtitleText
    }()
    
    let verificationCode: UITextField = {
        let verificationCode = UITextField()
        verificationCode.font = UIFont.title3.with(weight: .medium)
        verificationCode.adjustsFontForContentSizeCategory = true
        verificationCode.translatesAutoresizingMaskIntoConstraints = false
        verificationCode.textAlignment = .center
        verificationCode.keyboardType = .numberPad
        verificationCode.textColor = .label
        verificationCode.keyboardAppearance = .default
        verificationCode.backgroundColor = .secondarySystemGroupedBackground
        verificationCode.layer.cornerRadius = 10
        verificationCode.placeholder = "Code"
        return verificationCode
    }()
    
    let resend: UIButton = {
        let resend = UIButton()
        resend.translatesAutoresizingMaskIntoConstraints = false
        resend.setTitleColor(.white, for: .normal)
        resend.titleLabel?.backgroundColor = .clear
        resend.titleLabel?.font = UIFont.title3.with(weight: .semibold)
        resend.setTitle("Resend", for: .normal)
        resend.backgroundColor = .systemBlue
        resend.layer.cornerRadius = 10
        return resend
    }()
    
    let nextView: UIButton = {
        let nextView = UIButton()
        nextView.translatesAutoresizingMaskIntoConstraints = false
        nextView.setTitle("Next", for: .normal)
        nextView.titleLabel?.backgroundColor = .clear
        nextView.titleLabel?.font = UIFont.title3.with(weight: .semibold)
        nextView.setTitleColor(.systemBlue, for: .normal)
        nextView.backgroundColor = .secondarySystemGroupedBackground
        nextView.layer.cornerRadius = 10
        return nextView
    }()
    
    
    weak var enterVerificationCodeController: EnterVerificationCodeController?
    
    var seconds = 120
    
    var timer = Timer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(titleNumber)
        addSubview(subtitleText)
        addSubview(verificationCode)
        addSubview(nextView)
        addSubview(resend)
        
        let leftConstant: CGFloat = 15
        let rightConstant: CGFloat = -15
        let heightConstant: CGFloat = 50
        let spacingConstant: CGFloat = 20
        
        NSLayoutConstraint.activate([
            titleNumber.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            titleNumber.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleNumber.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleNumber.heightAnchor.constraint(equalToConstant: 70),
            
            subtitleText.topAnchor.constraint(equalTo: titleNumber.bottomAnchor),
            subtitleText.leadingAnchor.constraint(equalTo: leadingAnchor),
            subtitleText.trailingAnchor.constraint(equalTo: trailingAnchor),
            subtitleText.heightAnchor.constraint(equalToConstant: 30),
            
            verificationCode.topAnchor.constraint(equalTo: subtitleText.bottomAnchor, constant: spacingConstant),
            verificationCode.leadingAnchor.constraint(equalTo: leadingAnchor, constant: leftConstant),
            verificationCode.trailingAnchor.constraint(equalTo: trailingAnchor, constant: rightConstant),
            verificationCode.heightAnchor.constraint(equalToConstant: heightConstant),
            
            resend.topAnchor.constraint(equalTo: verificationCode.bottomAnchor, constant: spacingConstant),
            resend.leadingAnchor.constraint(equalTo: leadingAnchor, constant: leftConstant),
            resend.trailingAnchor.constraint(equalTo: trailingAnchor, constant: rightConstant),
            resend.heightAnchor.constraint(equalToConstant: 45),
            
            nextView.topAnchor.constraint(equalTo: resend.bottomAnchor, constant: spacingConstant),
            nextView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: leftConstant),
            nextView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: rightConstant),
            nextView.heightAnchor.constraint(equalToConstant: 45),
            
        ])
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
}
