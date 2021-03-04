//
//  OnboardingContainerView.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class OnboardingContainerView: UIView {
    
    //set-up logo image
    let logoImageView: UIImageView = {
        let logoImageView = UIImageView()
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.image = UIImage(named: "plotLogo")
        logoImageView.contentMode = .scaleAspectFit
        return logoImageView
    }()
    
    //set-up welcome label
    let welcomeTitle: UILabel = {
        let welcomeTitle = UILabel()
        welcomeTitle.translatesAutoresizingMaskIntoConstraints = false
        welcomeTitle.text = "Welcome to Plot"
        //    welcomeTitle.font = UIFont.systemFont(ofSize: 20)
        welcomeTitle.font = UIFont.preferredFont(forTextStyle: .title3)
        welcomeTitle.adjustsFontForContentSizeCategory = true
        welcomeTitle.minimumScaleFactor = 0.1
        welcomeTitle.adjustsFontSizeToFitWidth = true
        welcomeTitle.textAlignment = .center
        welcomeTitle.textColor = ThemeManager.currentTheme().generalTitleColor
        return welcomeTitle
    }()
    
    //set-up startMessaging button
    let startMessaging: UIButton = {
        let startMessaging = UIButton()
        startMessaging.translatesAutoresizingMaskIntoConstraints = false
        startMessaging.setTitle("Start Plotting", for: .normal)
        startMessaging.setTitleColor(FalconPalette.defaultBlue, for: .normal)
        startMessaging.titleLabel?.backgroundColor = .clear
        //    startMessaging.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        startMessaging.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title3)
        startMessaging.titleLabel?.adjustsFontForContentSizeCategory = true
        startMessaging.titleLabel?.minimumScaleFactor = 0.1
        startMessaging.titleLabel?.adjustsFontSizeToFitWidth = true
        startMessaging.addTarget(self, action: #selector(OnboardingController.startMessagingDidTap), for: .touchUpInside)
        
        return startMessaging
    }()
    
    //add View background color, Subviews and Constraints
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        addSubview(logoImageView)
        addSubview(welcomeTitle)
        addSubview(startMessaging)
        
        NSLayoutConstraint.activate([
            logoImageView.topAnchor.constraint(equalTo: topAnchor, constant: 100),
            logoImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 50),
            logoImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -50),
            logoImageView.heightAnchor.constraint(equalTo: logoImageView.widthAnchor),
            
            startMessaging.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            startMessaging.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            startMessaging.heightAnchor.constraint(equalToConstant: 50),
            
            welcomeTitle.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            welcomeTitle.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            welcomeTitle.heightAnchor.constraint(equalToConstant: 50),
            welcomeTitle.bottomAnchor.constraint(equalTo: startMessaging.topAnchor, constant: -10)
        ])
        
        if #available(iOS 11.0, *) {
            startMessaging.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -100).isActive = true
        } else {
            startMessaging.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -100).isActive = true
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
}
