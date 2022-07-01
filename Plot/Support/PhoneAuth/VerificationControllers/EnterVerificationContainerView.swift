//
//  EnterVerificationContainerView.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/3/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class EnterVerificationContainerView: UIView {
    
    let leftBarButton = UIBarButtonItem(title: "Resend", style: .done, target: EnterVerificationContainerView.self, action: nil)

  let titleNumber: UILabel = {
    let titleNumber = UILabel()
    titleNumber.translatesAutoresizingMaskIntoConstraints = false
    titleNumber.textAlignment = .center
    titleNumber.textColor = ThemeManager.currentTheme().generalTitleColor
    titleNumber.font = UIFont.systemFont(ofSize: 32)
    return titleNumber
  }()
  
  let subtitleText: UILabel = {
    let subtitleText = UILabel()
    subtitleText.translatesAutoresizingMaskIntoConstraints = false
    subtitleText.font = UIFont.preferredFont(forTextStyle: .body)
    subtitleText.adjustsFontForContentSizeCategory = true
    subtitleText.textAlignment = .center
    subtitleText.textColor = ThemeManager.currentTheme().generalTitleColor
    subtitleText.text = "We have sent you an SMS with the code"
    
    return subtitleText
  }()
  
  let verificationCode: UITextField = {
    let verificationCode = UITextField()
    verificationCode.font = UIFont.preferredFont(forTextStyle: .title3)
    verificationCode.adjustsFontForContentSizeCategory = true
    verificationCode.translatesAutoresizingMaskIntoConstraints = false
    verificationCode.textAlignment = .center
    verificationCode.keyboardType = .numberPad
    verificationCode.textColor = ThemeManager.currentTheme().generalTitleColor
    verificationCode.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
    verificationCode.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
    verificationCode.layer.cornerRadius = 10
		verificationCode.attributedPlaceholder = NSAttributedString(string: "Code", attributes: [NSAttributedString.Key.foregroundColor:
      ThemeManager.currentTheme().generalSubtitleColor])    
    return verificationCode
  }()
  
  let resend: UIButton = {
    let resend = UIButton()
    resend.translatesAutoresizingMaskIntoConstraints = false
    resend.setTitle("Resend", for: .normal)
    resend.setTitle("Sent!", for: .disabled)
    resend.contentVerticalAlignment = .center
    resend.contentHorizontalAlignment = .center
    resend.setTitleColor(FalconPalette.defaultBlue, for: .normal)
    resend.setTitleColor(ThemeManager.currentTheme().generalSubtitleColor, for: .highlighted)
    resend.setTitleColor(ThemeManager.currentTheme().generalSubtitleColor, for: .disabled)
    
    return resend
  }()
    
    let nextView: UIButton = {
      let next = UIButton()
      next.translatesAutoresizingMaskIntoConstraints = false
      next.setTitle("Next", for: .normal)
      next.contentVerticalAlignment = .center
      next.contentHorizontalAlignment = .center
      next.setTitleColor(FalconPalette.defaultBlue, for: .normal)
      next.setTitleColor(ThemeManager.currentTheme().generalSubtitleColor, for: .highlighted)
      next.setTitleColor(ThemeManager.currentTheme().generalSubtitleColor, for: .disabled)
      
      return next
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
      
      verificationCode.topAnchor.constraint(equalTo: subtitleText.bottomAnchor, constant: 30),
      verificationCode.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
      verificationCode.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
      verificationCode.heightAnchor.constraint(equalToConstant: 50),
      
      resend.topAnchor.constraint(equalTo: verificationCode.bottomAnchor, constant: 5),
      resend.leadingAnchor.constraint(equalTo: leadingAnchor),
      resend.trailingAnchor.constraint(equalTo: trailingAnchor),
      resend.heightAnchor.constraint(equalToConstant: 45),
      
      nextView.topAnchor.constraint(equalTo: resend.bottomAnchor, constant: 5),
      nextView.leadingAnchor.constraint(equalTo: leadingAnchor),
      nextView.trailingAnchor.constraint(equalTo: trailingAnchor),
      nextView.heightAnchor.constraint(equalToConstant: 45),
      
    ])
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)!
  }
}
