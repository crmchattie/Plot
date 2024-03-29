//
//  ChangePhoneNumberController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/30/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class ChangePhoneNumberController: EnterPhoneNumberController {
    
    override func configurePhoneNumberContainerView() {
        super.configurePhoneNumberContainerView()
        
        let leftBarButton = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(leftBarButtonDidTap))
        navigationItem.leftBarButtonItem = leftBarButton
        phoneNumberContainerView.instructions.text = "Please confirm your country code\nand enter your NEW phone number."
        phoneNumberContainerView.phoneNumber.placeholder = "New Phone Number"
    }
    
    override func rightBarButtonDidTap() {
        super.rightBarButtonDidTap()
        
        let destination = ChangeNumberVerificationController(networkController: networkController)
        destination.enterVerificationContainerView.titleNumber.text = phoneNumberContainerView.countryCode.text! + phoneNumberContainerView.phoneNumber.text!
        navigationController?.pushViewController(destination, animated: true)
        
    }
    
}
