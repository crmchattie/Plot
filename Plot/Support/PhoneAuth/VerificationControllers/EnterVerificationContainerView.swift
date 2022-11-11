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
        verificationCode.attributedPlaceholder = NSAttributedString(string: "Code", attributes: [NSAttributedString.Key.foregroundColor:
                                                                                                    UIColor.secondaryLabel])
        return verificationCode
    }()
    
    let resend: UIButton = {
        let resend = UIButton()
        resend.translatesAutoresizingMaskIntoConstraints = false
        resend.setTitle("Resend", for: .normal)
        resend.setTitle("Sent!", for: .disabled)
        resend.setTitleColor(.white, for: .normal)
        resend.setTitleColor(.white, for: .disabled)
        resend.titleLabel?.backgroundColor = .clear
        resend.titleLabel?.font = UIFont.title3.with(weight: .semibold)
        resend.backgroundColor = .systemBlue
        resend.layer.cornerRadius = 10
        return resend
    }()
    
    let nextView: UIButton = {
        let nextView = UIButton()
        nextView.translatesAutoresizingMaskIntoConstraints = false
        nextView.setTitle("Next", for: .normal)
        nextView.setTitleColor(.white, for: .normal)
        nextView.titleLabel?.backgroundColor = .clear
        nextView.titleLabel?.font = UIFont.title3.with(weight: .semibold)
        nextView.backgroundColor = .systemBlue
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
        
        NSLayoutConstraint.activate([
            titleNumber.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            titleNumber.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleNumber.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleNumber.heightAnchor.constraint(equalToConstant: 70),
            
            subtitleText.topAnchor.constraint(equalTo: titleNumber.bottomAnchor),
            subtitleText.leadingAnchor.constraint(equalTo: leadingAnchor),
            subtitleText.trailingAnchor.constraint(equalTo: trailingAnchor),
            subtitleText.heightAnchor.constraint(equalToConstant: 30),
            
            verificationCode.topAnchor.constraint(equalTo: subtitleText.bottomAnchor, constant: 20),
            verificationCode.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            verificationCode.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            verificationCode.heightAnchor.constraint(equalToConstant: 50),
            
            resend.topAnchor.constraint(equalTo: verificationCode.bottomAnchor, constant: 20),
            resend.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            resend.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            resend.heightAnchor.constraint(equalToConstant: 45),
            
            nextView.topAnchor.constraint(equalTo: resend.bottomAnchor, constant: 20),
            nextView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            nextView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            nextView.heightAnchor.constraint(equalToConstant: 45),
            
        ])
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
}
