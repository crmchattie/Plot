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
        welcomeTitle.font = UIFont.preferredFont(forTextStyle: .title3)
        welcomeTitle.adjustsFontForContentSizeCategory = true
        welcomeTitle.textAlignment = .center
        welcomeTitle.textColor = .label
        return welcomeTitle
    }()
    
    //set-up startMessaging button
    let startMessaging: UIButton = {
        let startMessaging = UIButton()
        startMessaging.translatesAutoresizingMaskIntoConstraints = false
        startMessaging.setTitle("Start Plotting", for: .normal)
        startMessaging.setTitleColor(FalconPalette.defaultBlue, for: .normal)
        startMessaging.titleLabel?.backgroundColor = .clear
        startMessaging.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title3)
        startMessaging.titleLabel?.adjustsFontForContentSizeCategory = true
        return startMessaging
    }()
    
    //add View background color, Subviews and Constraints
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(logoImageView)
        addSubview(welcomeTitle)
        addSubview(startMessaging)
        
        NSLayoutConstraint.activate([
            logoImageView.topAnchor.constraint(equalTo: topAnchor, constant: 200),
            logoImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 50),
            logoImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -50),
            logoImageView.heightAnchor.constraint(equalTo: logoImageView.widthAnchor),
            
            welcomeTitle.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            welcomeTitle.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            welcomeTitle.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 50),
            welcomeTitle.heightAnchor.constraint(equalToConstant: 50),

            
            startMessaging.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            startMessaging.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            startMessaging.topAnchor.constraint(equalTo: welcomeTitle.bottomAnchor, constant: 10),
            startMessaging.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
}
