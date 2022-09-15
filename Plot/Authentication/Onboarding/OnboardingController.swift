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
        view.backgroundColor = .systemGroupedBackground
        view.addSubview(onboardingContainerView)
        onboardingContainerView.frame = view.bounds
        onboardingContainerView.startMessaging.addTarget(self, action: #selector(startMessagingDidTap), for: .touchUpInside)
        
    }
    
    fileprivate func setColorsAccordingToTheme() {
    }
    
    //move to next ViewController when user taps on startMessagingDidTap button
    @objc func startMessagingDidTap () {
        let destination = AuthPhoneNumberController()
        navigationController?.pushViewController(destination, animated: true)
    }
    
}
