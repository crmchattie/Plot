//
//  OnboardingController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class OnboardingController: UIViewController {

  let onboardingContainerView = OnboardingContainerView()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    //set-up interface with the help of OnboardingContainerView file
    extendedLayoutIncludesOpaqueBars = true
    view.addSubview(onboardingContainerView)
    onboardingContainerView.frame = view.bounds
    setColorsAccordingToTheme()
    onboardingContainerView.startMessaging.addTarget(self, action: #selector(startMessagingDidTap), for: .touchUpInside)

  }
  
  fileprivate func setColorsAccordingToTheme() {
    let theme = ThemeManager.currentTheme()
    ThemeManager.applyTheme(theme: theme)
    //redundant and why do we pass the generalBackgroundColor back and forth between views
    view.backgroundColor = ThemeManager.currentTheme().launchBackgroundColor
    onboardingContainerView.backgroundColor = view.backgroundColor
  }
    
  //move to next ViewController when user taps on startMessagingDidTap button
  @objc func startMessagingDidTap () {
    let destination = AuthPhoneNumberController()
    navigationController?.pushViewController(destination, animated: true)
  }

}
